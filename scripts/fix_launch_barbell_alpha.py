#!/usr/bin/env python3
"""Create a launch-only PNG with an opaque Repera mascot and a transparent exterior.

The source artwork contains alpha holes INSIDE its eyes, mouth and equipment.
Black-on-black previews conceal those defects; preview the result on #30D158.
The mask must never flatten the whole canvas into green.
"""
from pathlib import Path
import json

import cv2
import numpy as np
from PIL import Image

ROOT = Path("Apps/Repera/Resources/Assets.xcassets")
SOURCE = ROOT / "MascotHero.imageset/mascot-hero.png"
OUT = ROOT / "MascotLaunchBarbell.imageset/mascot-launch-barbell.png"
PREVIEW = Path("docs/assets/repera-launch-alpha-preview.png")
GREEN = (48, 209, 88)
INK = (47, 42, 39)


def ellipse_mask(shape, xy, axes, angle=0):
    mask = np.zeros(shape, dtype=np.uint8)
    cv2.ellipse(mask, xy, axes, angle, 0, 360, 255, -1, cv2.LINE_AA)
    return mask > 0


def fill_face(rgb, alpha):
    h, w = alpha.shape
    sx, sy = w / 1024, h / 1024
    # Inside the *cheek skin*, away from the outline / headband. Repair even
    # completely transparent pixels, because old transparency must not win.
    safe_face = np.zeros((h, w), dtype=np.uint8)
    polygon = np.array([
        [364, 333], [396, 318], [481, 312], [567, 321],
        [632, 348], [685, 381], [695, 436], [652, 484],
        [580, 501], [476, 501], [407, 483], [366, 446],
    ], dtype=np.float32)
    cv2.fillPoly(safe_face, [np.rint(polygon * [sx, sy]).astype(np.int32)], 255)
    holes = (safe_face > 0) & (alpha < 252)
    if holes.any():
        # RGB of a fully transparent pixel isn't meaningful. Inpaint it from
        # surrounding cream skin before making it opaque.
        rgb[:] = cv2.inpaint(rgb, holes.astype(np.uint8) * 255, 6, cv2.INPAINT_TELEA)
        alpha[holes] = 255
    return sx, sy


def restore_face_features(rgb, alpha, sx, sy):
    h, w = alpha.shape
    # Wipe the old feature region to avoid duplicated mouths / green eye holes.
    wipe = np.zeros((h, w), dtype=np.uint8)
    for xy, axes, angle in [
        ((445, 381), (37, 55), 6),
        ((606, 413), (38, 56), 5),
        ((516, 429), (53, 33), 0),
    ]:
        cv2.ellipse(wipe,
                    (round(xy[0] * sx), round(xy[1] * sy)),
                    (round(axes[0] * sx), round(axes[1] * sy)),
                    angle, 0, 360, 255, -1)
    rgb[:] = cv2.inpaint(rgb, wipe, 15, cv2.INPAINT_TELEA)
    alpha[wipe > 0] = 255

    # One matched Repera expression. Alpha is forcibly 255 throughout the
    # full pupils and smile rather than only in the centers.
    feature = np.zeros((h, w), dtype=np.uint8)
    for xy, axes, angle in [
        ((445, 379), (27, 44), 6),
        ((607, 411), (27, 43), 5),
    ]:
        center = (round(xy[0] * sx), round(xy[1] * sy))
        extents = (round(axes[0] * sx), round(axes[1] * sy))
        cv2.ellipse(rgb, center, extents, angle, 0, 360, INK, -1, cv2.LINE_AA)
        cv2.ellipse(feature, center, extents, angle, 0, 360, 255, -1, cv2.LINE_AA)
    # Original Repera U-shape (one smile, no inner green areas).
    center = (round(518 * sx), round(416 * sy))
    axes = (round(35 * sx), round(29 * sy))
    width = max(2, round(10 * sx))
    cv2.ellipse(rgb, center, axes, 0, 0, 180, INK, width, cv2.LINE_AA)
    cv2.ellipse(feature, center, axes, 0, 0, 180, 255, width + 2, cv2.LINE_AA)
    alpha[feature > 0] = 255

    # Small reflected highlights are themselves opaque white, never holes.
    for xy, radius in [((453, 351), 7), ((617, 380), 6)]:
        pos = (round(xy[0] * sx), round(xy[1] * sy))
        r = round(radius * sx)
        cv2.circle(rgb, pos, r, (249, 244, 242), -1, cv2.LINE_AA)
        cv2.circle(alpha, pos, r, 255, -1, cv2.LINE_AA)


def restore_weights(rgb, alpha, sx, sy):
    h, w = alpha.shape
    # Only equipment contours. Hands and skin (already solid) are NEVER
    # repainted. Restrict restoration to actual dark equipment structure.
    regions = [
        [(30, 278), (112, 272), (163, 315), (179, 399), (123, 465), (45, 429)],
        [(175, 224), (235, 211), (302, 255), (313, 332), (278, 388), (207, 364)],
        [(743, 314), (800, 286), (871, 309), (884, 379), (819, 422), (754, 395)],
        [(861, 347), (935, 357), (998, 396), (998, 494), (951, 545), (877, 504)],
    ]
    dark_visible = ((alpha > 180) &
                    (rgb.max(axis=2) < 135) &
                    (rgb.min(axis=2) < 115)).astype(np.uint8)
    close = cv2.morphologyEx(dark_visible,
                            cv2.MORPH_CLOSE,
                            cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (31, 31)))
    nearby_dark = cv2.dilate(close,
                             cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21)))
    for polygon in regions:
        local = np.zeros((h, w), dtype=np.uint8)
        poly = np.rint(np.asarray(polygon) * [sx, sy]).astype(np.int32)
        cv2.fillPoly(local, [poly], 255)
        # Fill opaque dark elements and the small pierced holes around them.
        affected = (local > 0) & (nearby_dark > 0) & (alpha < 250)
        # Ink belongs only to previously transparent/partly-transparent pixels.
        rgb[affected] = (58, 56, 55)
        alpha[affected] = 255


def main():
    im = Image.open(SOURCE).convert("RGBA")
    pix = np.array(im, copy=True)
    rgb = pix[:, :, :3].copy()
    alpha = pix[:, :, 3].copy()
    sx, sy = fill_face(rgb, alpha)
    restore_face_features(rgb, alpha, sx, sy)
    restore_weights(rgb, alpha, sx, sy)

    finished = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")
    assert finished.getpixel((0, 0))[3] == 0
    assert finished.getpixel((im.width-1, im.height-1))[3] == 0
    for point in [(445,379),(607,411),(518,438),(453,351),(617,380)]:
        x,y = round(point[0]*sx),round(point[1]*sy)
        assert finished.getpixel((x,y))[3] == 255, (point, "internal transparency")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    finished.save(OUT, optimize=True)
    (OUT.parent / "Contents.json").write_text(
        json.dumps({"images":[{"filename":OUT.name,"idiom":"universal"}],
                    "info":{"author":"xcode","version":1}},indent=2)+"\n",
        encoding="utf-8"
    )
    # Diagnostic compositing is NOT used as the app asset. Its sole purpose
    # is to catch exactly the green leaks visible in the user's screenshot.
    backdrop = Image.new("RGBA", finished.size, GREEN + (255,))
    backdrop.alpha_composite(finished)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    backdrop.convert("RGB").save(PREVIEW, optimize=True)
    print("Created", OUT, "and brand-green preview", PREVIEW)
    print("All named face feature centers opaque; exterior alpha preserved.")


if __name__ == "__main__":
    main()
