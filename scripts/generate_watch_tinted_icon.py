#!/usr/bin/env python3
"""Derive a stable watchOS tinted complication image from the real Repera AppIcon.

Uses only Python's standard library. The official AppIcon is never modified;
the transparent grayscale asset retains the original eyes, smile and headband.
Run --check in CI or run without flags to regenerate after an AppIcon change.
"""
from __future__ import annotations

import argparse
import math
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
TARGET = ROOT / "Apps/ReperaWatchWidget/Assets.xcassets/ReperaWatchTintedIcon.imageset/icon.png"
SIGNATURE = b"\x89PNG\r\n\x1a\n"


def decode_png(path: Path) -> tuple[int, int, bytes]:
    png = path.read_bytes()
    if not png.startswith(SIGNATURE):
        raise ValueError(f"Not a PNG: {path}")
    at, compressed = 8, []
    width = height = depth = mode = interlace = -1
    while at < len(png):
        size = struct.unpack_from(">I", png, at)[0]
        kind, data = png[at+4:at+8], png[at+8:at+8+size]
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
            left = pixels[i-4] if x >= 4 else 0
            above = pixels[i-stride] if y else 0
            upperleft = pixels[i-stride-4] if y and x >= 4 else 0
            if filter_type == 1:
                value += left
            elif filter_type == 2:
                value += above
            elif filter_type == 3:
                value += (left + above) // 2
            elif filter_type == 4:
                predicted = left + above - upperleft
                dleft, dabove, dupperleft = (abs(predicted-v) for v in (left, above, upperleft))
                value += left if dleft <= dabove and dleft <= dupperleft else above if dabove <= dupperleft else upperleft
            elif filter_type != 0:
                raise ValueError(f"Unsupported PNG filter: {filter_type}")
            pixels[i] = value & 255
    return width, height, bytes(pixels)


def generate_rgba(source: bytes, width: int, height: int) -> bytes:
    if width != height or width % 4:
        raise ValueError("AppIcon must be square and divisible by four")
    bg = source[:3]
    side = width // 4
    result = bytearray(side * side * 4)
    for y in range(side):
        for x in range(side):
            weight = luminance = 0.0
            for dy in range(4):
                for dx in range(4):
                    i = 4 * (((y*4+dy)*width) + x*4+dx)
                    r, g, b, alpha = source[i:i+4]
                    distance = math.sqrt((r-bg[0])**2 + (g-bg[1])**2 + (b-bg[2])**2)
                    mask = max(0.0, min(1.0, (distance-19.0)/36.0)) * (alpha/255.0)
                    weight += mask
                    luminance += mask * (.2126*r + .7152*g + .0722*b)
            opacity = weight/16
            shade = int(math.floor(luminance/weight + .5)) if weight else 0
            i = (y*side+x)*4
            result[i:i+4] = bytes((shade, shade, shade, int(math.floor(opacity*255+.5))))
    return bytes(result)


def encode_png(width: int, height: int, data: bytes) -> bytes:
    row = width*4
    raw = b"".join(b"\0"+data[y*row:(y+1)*row] for y in range(height))
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return struct.pack(">I",len(payload))+kind+payload+struct.pack(">I",zlib.crc32(kind+payload))
    header = struct.pack(">IIBBBBB",width,height,8,6,0,0,0)
    return SIGNATURE+chunk(b"IHDR",header)+chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b"")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=TARGET)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    width, height, pixels = decode_png(args.source)
    expected = generate_rgba(pixels,width,height)
    side = width//4
    if args.check:
        actual_w,actual_h,actual = decode_png(args.output)
        if (actual_w,actual_h)!=(side,side) or len(actual)!=len(expected):
            print("FAIL: tinted asset size differs from official AppIcon conversion",file=sys.stderr)
            return 1
        # The reference PNG is generated by an independent pixel converter.
        # Allow one 8-bit unit for floating-point rounding differences.
        maximum = max(abs(a-b) for a,b in zip(actual,expected))
        if maximum > 1:
            print(f"FAIL: tinted pixels differ from official icon (max delta {maximum})",file=sys.stderr)
            return 1
        print(f"PASS: tinted icon {side}x{side} matches official AppIcon (delta {maximum})")
        return 0
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_bytes(encode_png(side,side,expected))
    print(f"Generated {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
