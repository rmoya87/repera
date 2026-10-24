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

    # Preserve all previously opaque pixels. For missing dark pupil or smile
    # samples, paint the missing pixels dark instead of the green background.
    details = np.zeros((h, w), np.uint8)
    cv2.ellipse(details, (round(444*sx), round(379*sy)), (round(27*sx), round(47*sy)), 6, 0, 360, 255, -1)
    cv2.ellipse(details, (round(606*sx), round(412*sy)), (round(29*sx), round(46*sy)), 5, 0, 360, 255, -1)
    cv2.ellipse(details, (round(516*sx), round(447*sy)), (round(44*sx), round(23*sy)), 0, 0, 180, 255, -1)
    # Only paint holes reported by the original alpha; do not change opaque details.
    original_a = np.asarray(image.convert("RGBA"))[:, :, 3]
    missing_details = (details > 0) & (original_a < 210)
    rgb[missing_details] = (50, 43, 39)
    alpha[missing_details] = 255

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

    head_poly = np.array([
        [477, 93], [505, 103], [547, 137], [567, 80], [596, 77],
        [643, 133], [671, 171], [728, 207], [769, 272],
        [788, 351], [772, 424], [735, 481], [691, 518],
        [624, 549], [541, 564], [456, 555], [379, 536],
        [313, 493], [277, 439], [264, 374], [272, 304],
        [311, 236], [371, 178], [419, 150]
    ], np.float32) * old_scale
    mask = np.zeros((oh, ow), np.uint8)
    cv2.fillPoly(mask, [head_poly.astype(np.int32)], 255)
    mask = cv2.GaussianBlur(mask, (9, 9), 2.2)
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
