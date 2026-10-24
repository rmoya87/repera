#!/usr/bin/env python3
"""Build the two Repera launch figures from the ACTUAL Repera MascotHero.

Hero: preserve the original figure, make enclosed details completely opaque,
      and keep only its exterior silhouette transparent.
Running: start from an existing running pose, then replace its head with the
         actual cleaned Repera head (not an invented face).
Never flatten the transparent asset onto the green backdrop.
"""
from pathlib import Path
import argparse
import cv2
import numpy as np
from PIL import Image

ASSETS = Path("Apps/Repera/Resources/Assets.xcassets")
HERO_PATH = ASSETS / "MascotHero.imageset/mascot-hero.png"
RUN_PATH = ASSETS / "MascotRunning.imageset/mascot-running.png"


def largest_silhouette(alpha):
    visible = (alpha > 15).astype(np.uint8)
    count, comps, sizes, centers = cv2.connectedComponentsWithStats(visible, 8)
    if count < 2:
        raise ValueError("Expected visible mascot artwork")
    largest = 1 + int(np.argmax(sizes[1:, cv2.CC_STAT_AREA]))
    return np.uint8(comps == largest) * 255


def make_solid_inside(alpha, rgb):
    """Repair tiny enclosed or nearly enclosed holes without filling open gaps."""
    outer = largest_silhouette(alpha)
    closed = cv2.morphologyEx(outer, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (19, 19)))
    inv = 255 - closed
    count, comps, sizes, centers = cv2.connectedComponentsWithStats(inv, 8)
    # Outside = any transparent component touching an image edge.
    exterior = set()
    h, w = alpha.shape
    for label in np.unique(np.concatenate([comps[0], comps[-1], comps[:, 0], comps[:, -1]])):
        exterior.add(int(label))
    fill = np.zeros((h, w), np.uint8)
    for i in range(1, count):
        if i not in exterior and sizes[i, cv2.CC_STAT_AREA] < h * w * 0.018:
            fill[comps == i] = 255
    need = ((fill > 0) | ((closed > 0) & (alpha < 170))) & (alpha < 240)
    if np.any(need):
        repaired = cv2.inpaint(rgb, need.astype(np.uint8) * 255, 5, cv2.INPAINT_TELEA)
        rgb[need] = repaired[need]
        alpha[need] = 255
    return rgb, alpha


def repair_barbell_image(image):
    data = np.array(image.convert("RGBA"), copy=True)
    h, w = data.shape[:2]
    assert w >= 900 and h >= 900, "Unexpected original art size"
    rgb = data[:, :, :3].copy()
    alpha = data[:, :, 3].copy()
    rgb, alpha = make_solid_inside(alpha, rgb)

    # Source image is 1024x1024. Explicit *internal* face matte corrects
    # open alpha leaks in both pupils and mouth that flood-fill cannot reach.
    # Never modify pixels outside the face (including holes between limbs).
    sx, sy = w / 1024.0, h / 1024.0
    face = np.zeros((h, w), np.uint8)
    face_points = np.array([
        [286, 345], [315, 306], [400, 295], [501, 305],
        [632, 320], [719, 341], [765, 384], [746, 461],
        [699, 507], [620, 545], [516, 550], [414, 547],
        [350, 516], [299, 465], [282, 396]
    ], dtype=np.float32)
    cv2.fillPoly(face, [np.rint(face_points * [sx, sy]).astype(np.int32)], 255)

    # Use neighboring *opaque* skin pixels to recover lost RGB values.
    gaps = ((face > 0) & (alpha < 250)).astype(np.uint8) * 255
    if np.any(gaps):
        fixed = cv2.inpaint(rgb, gaps, 8, cv2.INPAINT_TELEA)
        rgb[gaps > 0] = fixed[gaps > 0]
        alpha[gaps > 0] = 255

    # Restore plain skin in *only* the three original feature areas before
    # painting each feature ONCE. This also removes broken alpha artifacts in
    # the original pixels, and prevents duplicate outlines in later rebuilds.
    clean = np.zeros((h, w), np.uint8)
    for center, axes in (
        ((444, 381), (36, 55)),
        ((607, 412), (38, 55)),
        ((515, 434), (57, 39)),
    ):
        xy = (round(center[0] * sx), round(center[1] * sy))
        ab = (round(axes[0] * sx), round(axes[1] * sy))
        cv2.ellipse(clean, xy, ab, 0, 0, 360, 255, -1)
    rgb = cv2.inpaint(rgb, clean, 15, cv2.INPAINT_TELEA)
    alpha[clean > 0] = 255

    # Draw Repera's compact black eyes and ONE U-shaped smile, opaque by design.
    dark = (49, 42, 38)
    detail = np.zeros((h, w), np.uint8)
    for center, axes, angle in (
        ((444, 381), (26, 43), 6),
        ((606, 412), (26, 42), 4),
    ):
        xy = (round(center[0] * sx), round(center[1] * sy))
        ab = (round(axes[0] * sx), round(axes[1] * sy))
        cv2.ellipse(rgb, xy, ab, angle, 0, 360, dark, -1, cv2.LINE_AA)
        cv2.ellipse(detail, xy, ab, angle, 0, 360, 255, -1)
    mouth_xy = (round(517 * sx), round(416 * sy))
    mouth_ab = (round(35 * sx), round(29 * sy))
    cv2.ellipse(rgb, mouth_xy, mouth_ab, 0, 0, 180, dark,
                round(10 * sx), cv2.LINE_AA)
    cv2.ellipse(detail, mouth_xy, mouth_ab, 0, 0, 180, 255,
                round(12 * sx), cv2.LINE_AA)
    for px, py, radius in ((452, 350, 7), (615, 382, 6)):
        xy = (round(px * sx), round(py * sy))
        cv2.circle(rgb, xy, round(radius * sx), (247, 239, 236), -1, cv2.LINE_AA)
        cv2.circle(detail, xy, round(radius * sx), 255, -1)
    alpha[detail > 0] = 255

    repaired = np.dstack([rgb, alpha])
    return Image.fromarray(repaired, "RGBA")


def running_with_original_head(running, original):
    """Run using EXACT Repera original eyes, smile and blush, never duplicate faces.

    Keep the existing runner's motion and outer head shape. Replace its facial
    expression by feathering an opaque patch of the corrected, original Repera
    face over it, after erasing the previous running character's facial marks.
    """
    run = np.array(running.convert("RGBA"), copy=True)
    old = np.array(original.convert("RGBA"), copy=True)
    rh, rw = run.shape[:2]
    oh, ow = old.shape[:2]
    assert abs(rw / rh - 1) < .15
    relative = rw / 1254.0
    old_scale = ow / 1024.0

    # Remove stray artifacts around the generated silhouette.
    body = largest_silhouette(run[:, :, 3])
    enlarged = cv2.dilate(body, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7,7)))
    run[:, :, 3] = np.where(enlarged > 0, run[:, :, 3], 0)

    # Clear only the running source's eyebrows (not present on Repera).
    erase = np.zeros((rh, rw), np.uint8)
    for cx, cy, rx, ry in ((772, 398, 57, 28), (966, 428, 55, 30)):
        cv2.ellipse(erase,
            (round(cx * relative), round(cy * relative)),
            (round(rx * relative), round(ry * relative)), 0, 0, 360, 255, -1)
    # Inpaint only dark brown eyebrow ink, not green textile or beige skin.
    dark_brow = np.max(run[:,:,:3], axis=2) < 115
    brow_bad = ((erase > 0) & dark_brow).astype(np.uint8) * 255
    if np.any(brow_bad):
        run[:,:,:3] = cv2.inpaint(run[:,:,:3], brow_bad, 12, cv2.INPAINT_TELEA)

    # A face-only mask (strictly below the headband): no ears, dumbbells or
    # duplicate head contours are transferred from the original image.
    mask = np.zeros((oh, ow), np.uint8)
    cv2.ellipse(mask, (round(516 * old_scale), round(423 * old_scale)),
                (round(211 * old_scale), round(112 * old_scale)), 0,
                0, 360, 255, -1)
    mask = cv2.GaussianBlur(mask, (0,0), 22 * old_scale)
    mask = (mask.astype(np.float32) * old[:,:,3].astype(np.float32) / 255).astype(np.uint8)

    # Place original eyes precisely over running character's eyes.
    # Original (444,381) -> (760,517), (606,412) -> (948,553).
    scale = 1.16 * (rw / 1254.0) * (1024.0 / ow)
    transformation = np.float32([
        [scale, 0, 245 * relative],
        [0, scale, 75 * relative],
    ])
    face = cv2.warpAffine(old, transformation, (rw, rh),
                          flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_CONSTANT,
                          borderValue=(0,0,0,0))
    matte = cv2.warpAffine(mask, transformation, (rw, rh),
                           flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT,
                           borderValue=0)
    overlay = face.copy()
    overlay[:,:,3] = matte
    return Image.alpha_composite(Image.fromarray(run, "RGBA"),
                                 Image.fromarray(overlay, "RGBA"))


def assert_launch_art(image, label):
    alpha = np.asarray(image.convert("RGBA"))[:, :, 3]
    h, w = alpha.shape
    assert alpha[0, 0] == 0 and alpha[-1, -1] == 0, label + ": exterior not transparent"
    assert np.count_nonzero(alpha > 245) > h * w * .14, label + ": mascot missing"
    print(label, image.size, "opaque", int(np.count_nonzero(alpha >= 245)), "transparent", int(np.count_nonzero(alpha < 10)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--running-source", type=Path, required=True)\n    parser.add_argument("--hero-source", type=Path, default=HERO_PATH)
    args = parser.parse_args()
    hero = repair_barbell_image(Image.open(args.hero_source))
    runner = running_with_original_head(Image.open(args.running_source), hero)
    assert_launch_art(hero, "barbell")
    assert_launch_art(runner, "running")
    hero.save(HERO_PATH, optimize=True)
    RUN_PATH.parent.mkdir(exist_ok=True)
    runner.save(RUN_PATH, optimize=True)
    import json
    (RUN_PATH.parent / "Contents.json").write_text(
        json.dumps({"images": [{"filename": RUN_PATH.name, "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
        encoding="utf-8"
    )


if __name__ == "__main__":
    main()
