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

    # Definitively paint the two pupils and smile as FULLY opaque, not merely
    # fill alpha. The source PNG has partly erased RGB at those locations.
    # Keep the same facial geometry and highlights of Repera's original face.
    dark = (48, 41, 38)  # RGB warm dark, not a transparent pixel
    details = np.zeros((h, w), np.uint8)
    for center, axes, rotation in (
        ((444, 379), (27, 45), 6),
        ((606, 411), (28, 43), 5),
    ):
        xy = (round(center[0] * sx), round(center[1] * sy))
        ab = (round(axes[0] * sx), round(axes[1] * sy))
        cv2.ellipse(rgb, xy, ab, rotation, 0, 360, dark, -1, cv2.LINE_AA)
        cv2.ellipse(details, xy, ab, rotation, 0, 360, 255, -1)
    mouth_center = (round(515 * sx), round(432 * sy))
    mouth_axes = (round(38 * sx), round(30 * sy))
    cv2.ellipse(rgb, mouth_center, mouth_axes, 0, 0, 180,
                dark, round(11 * sx), cv2.LINE_AA)
    cv2.ellipse(details, mouth_center, mouth_axes, 0, 0, 180,
                255, round(14 * sx), cv2.LINE_AA)
    for px, py, radius in ((453, 346, 7), (618, 380, 7)):
        xy = (round(px * sx), round(py * sy))
        cv2.circle(rgb, xy, round(radius * sx), (241, 235, 233), -1, cv2.LINE_AA)
        cv2.circle(details, xy, round(radius * sx), 255, -1)
    alpha[details > 0] = 255

    repaired = np.dstack([rgb, alpha])
    return Image.fromarray(repaired, "RGBA")


def running_with_original_head(running, original):
    """Use the original head, face and green headband with a running body."""
    run = np.array(running.convert("RGBA"), copy=True)
    old = np.array(original.convert("RGBA"), copy=True)
    rh, rw = run.shape[:2]
    oh, ow = old.shape[:2]
    assert abs(rw / rh - 1) < 0.15, "Running asset must be square"
    old_scale = ow / 1024.0

    # Clean speckles in the generated runner's exterior alpha: keep only the
    # main connected silhouette while leaving original antialiasing.
    body = largest_silhouette(run[:, :, 3])
    expanded = cv2.dilate(body, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
    run[:, :, 3] = np.where(expanded > 0, run[:, :, 3], 0)

    # Transfer ONLY the genuine facial/headband texture. Earlier we
    # accidentally transferred weights and extra ear silhouettes too; those
    # must stay out. The existing runner provides the outer head contour,
    # ears and the running body. Feather the face/headband patch naturally.
    head_poly = np.array([
        [374, 218], [432, 190], [518, 179], [625, 179],
        [690, 202], [728, 238], [735, 275], [722, 316],
        [721, 380], [699, 450], [649, 510], [575, 541],
        [466, 539], [396, 516], [343, 477], [322, 420],
        [329, 350], [324, 305], [338, 255]
    ], np.float32) * old_scale
    mask = np.zeros((oh, ow), np.uint8)
    cv2.fillPoly(mask, [np.rint(head_poly).astype(np.int32)], 255)
    mask = cv2.GaussianBlur(mask, (0, 0), 16)
    mask = (mask.astype(np.float32) * old[:, :, 3].astype(np.float32) / 255).astype(np.uint8)

    # Align authentic head and headband with the new running torso.
    # Coordinates are proportional, not device-specific: assets can be
    # displayed with aspect-fit on every iPhone / iPad orientation.
    factor = (rw / 1254.0) * (1024.0 / ow) * 1.38
    transform = np.float32([[factor, 0, -(rw / 1254.0) * 33],
                            [0, factor, -(rh / 1254.0) * 40]])
    head = cv2.warpAffine(old, transform, (rw, rh), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_CONSTANT, borderValue=(0,0,0,0))
    matte = cv2.warpAffine(mask, transform, (rw, rh), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)

    # Straight-alpha overlay using Pillow avoids dark fringes.
    overlay = head.copy()
    overlay[:, :, 3] = matte
    result = Image.alpha_composite(Image.fromarray(run, "RGBA"), Image.fromarray(overlay, "RGBA"))
    return result


def assert_launch_art(image, label):
    alpha = np.asarray(image.convert("RGBA"))[:, :, 3]
    h, w = alpha.shape
    assert alpha[0, 0] == 0 and alpha[-1, -1] == 0, label + ": exterior not transparent"
    assert np.count_nonzero(alpha > 245) > h * w * .14, label + ": mascot missing"
    print(label, image.size, "opaque", int(np.count_nonzero(alpha >= 245)), "transparent", int(np.count_nonzero(alpha < 10)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--running-source", type=Path, required=True)
    args = parser.parse_args()
    hero = repair_barbell_image(Image.open(HERO_PATH))
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
