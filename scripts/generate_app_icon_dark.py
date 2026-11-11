#!/usr/bin/env python3
"""Install Repera App Icons from designer masters into iOS / Watch / Android.

Sources (outside the asset catalog):
  Apps/Repera/Resources/AppIconSource/AppIcon-Master.png       (light, green BG)
  Apps/Repera/Resources/AppIconSource/AppIcon-Dark-Master.png  (dark, black BG)

Writes:
  - iPhone AppIcon.png + AppIcon-Dark.png
  - Watch AppIcon.png (single; no dark slot)
  - Android/Wear adaptive foreground (transparent BG, 432²)
  - Android/Wear legacy mipmap ic_launcher(+_round) densities

Run without flags to regenerate; use --check in CI.
"""
from __future__ import annotations

import argparse
import math
import struct
import sys
import zlib
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASTER_LIGHT = ROOT / "Apps/Repera/Resources/AppIconSource/AppIcon-Master.png"
MASTER_DARK = ROOT / "Apps/Repera/Resources/AppIconSource/AppIcon-Dark-Master.png"
PHONE_LIGHT = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
PHONE_DARK = (
    ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png"
)
WATCH_SET = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset"
WATCH_ICON = WATCH_SET / "AppIcon.png"
ANDROID_FG = (
    ROOT / "android/mobile/src/main/res/drawable/ic_launcher_foreground.png",
    ROOT / "android/wear/src/main/res/drawable/ic_launcher_foreground.png",
)
ANDROID_MIPMAP_ROOTS = (
    ROOT / "android/mobile/src/main/res",
    ROOT / "android/wear/src/main/res",
)
MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
SIGNATURE = b"\x89PNG\r\n\x1a\n"
BRAND_GREEN = (0x30, 0xD1, 0x58)
BG_THRESHOLD = 55.0
ANDROID_FG_SIZE = 432


def decode_png(path: Path) -> tuple[int, int, bytes]:
    png = path.read_bytes()
    if not png.startswith(SIGNATURE):
        raise ValueError(f"Not a PNG: {path}")
    at, compressed = 8, []
    width = height = depth = mode = interlace = -1
    while at < len(png):
        size = struct.unpack_from(">I", png, at)[0]
        kind, data = png[at + 4 : at + 8], png[at + 8 : at + 8 + size]
        at += size + 12
        if kind == b"IHDR":
            width, height, depth, mode, _, _, interlace = struct.unpack(">IIBBBBB", data)
        elif kind == b"IDAT":
            compressed.append(data)
        elif kind == b"IEND":
            break
    if (depth, mode, interlace) != (8, 6, 0):
        raise ValueError("Expected noninterlaced RGBA PNG with 8-bit channels")
    raw = zlib.decompress(b"".join(compressed))
    stride = width * 4
    if len(raw) != (stride + 1) * height:
        raise ValueError("Invalid scanline length")
    pixels, offset = bytearray(height * stride), 0
    for y in range(height):
        filter_type = raw[offset]
        offset += 1
        for x in range(stride):
            value = raw[offset]
            offset += 1
            i = y * stride + x
            left = pixels[i - 4] if x >= 4 else 0
            above = pixels[i - stride] if y else 0
            upperleft = pixels[i - stride - 4] if y and x >= 4 else 0
            if filter_type == 1:
                value += left
            elif filter_type == 2:
                value += above
            elif filter_type == 3:
                value += (left + above) // 2
            elif filter_type == 4:
                predicted = left + above - upperleft
                dleft, dabove, dupperleft = (
                    abs(predicted - v) for v in (left, above, upperleft)
                )
                value += (
                    left
                    if dleft <= dabove and dleft <= dupperleft
                    else above
                    if dabove <= dupperleft
                    else upperleft
                )
            elif filter_type != 0:
                raise ValueError(f"Unsupported PNG filter: {filter_type}")
            pixels[i] = value & 255
    return width, height, bytes(pixels)


def encode_png(width: int, height: int, data: bytes) -> bytes:
    row = width * 4
    raw = b"".join(b"\0" + data[y * row : (y + 1) * row] for y in range(height))

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return SIGNATURE + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(
        b"IEND", b""
    )


def _brand_dist(r: int, g: int, b: int) -> float:
    return math.sqrt(
        (r - BRAND_GREEN[0]) ** 2
        + (g - BRAND_GREEN[1]) ** 2
        + (b - BRAND_GREEN[2]) ** 2
    )


def _scale_nearest(data: bytes, src_w: int, src_h: int, dst: int) -> bytes:
    out = bytearray(dst * dst * 4)
    for y in range(dst):
        sy = min(src_h - 1, (y * src_h) // dst)
        for x in range(dst):
            sx = min(src_w - 1, (x * src_w) // dst)
            i = (sy * src_w + sx) * 4
            j = (y * dst + x) * 4
            out[j : j + 4] = data[i : i + 4]
    return bytes(out)


def _corner_green(pixels: bytes, width: int, height: int) -> tuple[int, int, int]:
    samples = (
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1),
        (8, 8),
        (width // 2, 8),
    )
    rs = gs = bs = 0
    for x, y in samples:
        i = (y * width + x) * 4
        rs += pixels[i]
        gs += pixels[i + 1]
        bs += pixels[i + 2]
    n = len(samples)
    return rs // n, gs // n, bs // n


def _is_bg_green(
    r: int, g: int, b: int, plate: tuple[int, int, int], threshold: float = BG_THRESHOLD
) -> bool:
    plate_dist = math.sqrt(
        (r - plate[0]) ** 2 + (g - plate[1]) ** 2 + (b - plate[2]) ** 2
    )
    return plate_dist <= threshold or _brand_dist(r, g, b) <= threshold


def _flood_green_mask(
    pixels: bytes, width: int, height: int, plate: tuple[int, int, int]
) -> bytearray:
    bg = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque(
        ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1))
    )
    while queue:
        x, y = queue.popleft()
        idx = y * width + x
        if bg[idx]:
            continue
        i = idx * 4
        if not _is_bg_green(pixels[i], pixels[i + 1], pixels[i + 2], plate):
            continue
        bg[idx] = 1
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and not bg[ny * width + nx]:
                queue.append((nx, ny))
    if not any(bg):
        raise ValueError("No green background found to key")
    # Absorb near-plate fringe.
    for _ in range(4):
        add: list[int] = []
        for y in range(height):
            for x in range(width):
                idx = y * width + x
                if bg[idx]:
                    continue
                near = any(
                    0 <= nx < width and 0 <= ny < height and bg[ny * width + nx]
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                )
                if not near:
                    continue
                i = idx * 4
                r, g, b = pixels[i], pixels[i + 1], pixels[i + 2]
                if g > r + 10 and g > b + 10 and _is_bg_green(r, g, b, plate, 75):
                    add.append(idx)
        if not add:
            break
        for idx in add:
            bg[idx] = 1
    return bg


def normalize_light_background(light: bytes, width: int, height: int) -> bytes:
    """Snap JPEG-shifted green plate to exact brand `#30D158` for iOS/mipmaps."""
    plate = _corner_green(light, width, height)
    bg = _flood_green_mask(light, width, height, plate)
    out = bytearray(light)
    fill = bytes((BRAND_GREEN[0], BRAND_GREEN[1], BRAND_GREEN[2], 255))
    for idx in range(width * height):
        if bg[idx]:
            i = idx * 4
            out[i : i + 4] = fill
    return bytes(out)


def make_android_foreground(light: bytes, width: int, height: int) -> bytes:
    """Chroma-key green plate → transparent for adaptive icon FG."""
    plate = _corner_green(light, width, height)
    bg = _flood_green_mask(light, width, height, plate)
    out = bytearray(light)
    for idx in range(width * height):
        if bg[idx]:
            i = idx * 4
            out[i : i + 4] = b"\x00\x00\x00\x00"
    return _scale_nearest(bytes(out), width, height, ANDROID_FG_SIZE)


def generate_all() -> tuple[bytes, bytes, bytes, dict[int, bytes]]:
    lw, lh, light_raw = decode_png(MASTER_LIGHT)
    dw, dh, dark = decode_png(MASTER_DARK)
    if (lw, lh) != (1024, 1024) or (dw, dh) != (1024, 1024):
        raise ValueError("Masters must be 1024x1024 RGBA PNGs")
    if light_raw == dark:
        raise ValueError("Light and dark masters must differ")
    light = normalize_light_background(light_raw, lw, lh)
    fg = make_android_foreground(light_raw, lw, lh)
    mipmaps = {size: _scale_nearest(light, lw, lh, size) for size in set(MIPMAP_SIZES.values())}
    return light, dark, fg, mipmaps


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path in (MASTER_LIGHT, MASTER_DARK):
        if not path.is_file():
            print(f"FAIL: missing master {path}", file=sys.stderr)
            return 1
    light, dark, fg, mipmaps = generate_all()
    light_png = encode_png(1024, 1024, light)
    dark_png = encode_png(1024, 1024, dark)
    fg_png = encode_png(ANDROID_FG_SIZE, ANDROID_FG_SIZE, fg)
    watch_dark = WATCH_SET / "AppIcon-Dark.png"

    if args.check:
        checks = (
            (PHONE_LIGHT, light),
            (PHONE_DARK, dark),
            (WATCH_ICON, light),
        )
        for path, expected in checks:
            aw, ah, actual = decode_png(path)
            if (aw, ah) != (1024, 1024) or actual != expected:
                print(f"FAIL: {path.relative_to(ROOT)} does not match master", file=sys.stderr)
                return 1
        if watch_dark.exists():
            print(
                f"FAIL: {watch_dark.relative_to(ROOT)} must not exist "
                "(watchOS AppIcon has no dark appearance slot)",
                file=sys.stderr,
            )
            return 1
        for path in ANDROID_FG:
            aw, ah, actual = decode_png(path)
            if (aw, ah) != (ANDROID_FG_SIZE, ANDROID_FG_SIZE) or actual != fg:
                print(
                    f"FAIL: {path.relative_to(ROOT)} does not match generated foreground",
                    file=sys.stderr,
                )
                return 1
        for root in ANDROID_MIPMAP_ROOTS:
            for folder, size in MIPMAP_SIZES.items():
                for name in ("ic_launcher.png", "ic_launcher_round.png"):
                    path = root / folder / name
                    aw, ah, actual = decode_png(path)
                    if (aw, ah) != (size, size) or actual != mipmaps[size]:
                        print(
                            f"FAIL: {path.relative_to(ROOT)} does not match generated mipmap",
                            file=sys.stderr,
                        )
                        return 1
        print(
            "PASS: AppIcon masters installed "
            "(iPhone light+dark; Watch single; Android/Wear FG+mipmaps)"
        )
        return 0

    PHONE_LIGHT.write_bytes(light_png)
    PHONE_DARK.write_bytes(dark_png)
    WATCH_ICON.write_bytes(light_png)
    for path in ANDROID_FG:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(fg_png)
    for root in ANDROID_MIPMAP_ROOTS:
        for folder, size in MIPMAP_SIZES.items():
            directory = root / folder
            directory.mkdir(parents=True, exist_ok=True)
            encoded = encode_png(size, size, mipmaps[size])
            (directory / "ic_launcher.png").write_bytes(encoded)
            (directory / "ic_launcher_round.png").write_bytes(encoded)
    if watch_dark.exists():
        watch_dark.unlink()
        print(f"Removed unsupported {watch_dark.relative_to(ROOT)}")
    print(f"Installed {PHONE_LIGHT.relative_to(ROOT)}")
    print(f"Installed {PHONE_DARK.relative_to(ROOT)}")
    print(f"Installed {WATCH_ICON.relative_to(ROOT)}")
    for path in ANDROID_FG:
        print(f"Installed {path.relative_to(ROOT)}")
    print("Installed Android/Wear mipmap ic_launcher(+_round)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
