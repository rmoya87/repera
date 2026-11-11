#!/usr/bin/env python3
"""Contract: App Icon masters → iOS dark/light, Watch single, Android/Wear launchers."""
from __future__ import annotations

import json
import math
import struct
import subprocess
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHONE_SET = ROOT / "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset"
WATCH_SET = ROOT / "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset"
MASTER_DIR = ROOT / "Apps/Repera/Resources/AppIconSource"
GEN = ROOT / "scripts/generate_app_icon_dark.py"
MOBILE_NIGHT = ROOT / "android/mobile/src/main/res/values-night/colors.xml"
WEAR_NIGHT = ROOT / "android/wear/src/main/res/values-night/colors.xml"
MOBILE_DAY = ROOT / "android/mobile/src/main/res/values/colors.xml"
WEAR_DAY = ROOT / "android/wear/src/main/res/values/colors.xml"
BRAND = (0x30, 0xD1, 0x58)


def _dark_entry(contents: dict) -> dict | None:
    for image in contents.get("images", []):
        for appearance in image.get("appearances", []) or []:
            if (
                appearance.get("appearance") == "luminosity"
                and appearance.get("value") == "dark"
            ):
                return image
    return None


def _decode_png(path: Path) -> tuple[int, int, bytes]:
    png = path.read_bytes()
    at, compressed = 8, []
    width = height = -1
    while at < len(png):
        size = struct.unpack_from(">I", png, at)[0]
        kind, data = png[at + 4 : at + 8], png[at + 8 : at + 8 + size]
        at += size + 12
        if kind == b"IHDR":
            width, height, *_ = struct.unpack(">IIBBBBB", data)
        elif kind == b"IDAT":
            compressed.append(data)
        elif kind == b"IEND":
            break
    raw = zlib.decompress(b"".join(compressed))
    stride = width * 4
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
            pixels[i] = value & 255
    return width, height, bytes(pixels)


class AppIconDarkModeContract(unittest.TestCase):
    def test_iphone_declares_dark_appearance(self) -> None:
        contents = json.loads((PHONE_SET / "Contents.json").read_text(encoding="utf-8"))
        dark = _dark_entry(contents)
        self.assertIsNotNone(dark, "iPhone AppIcon missing luminosity=dark entry")
        assert dark is not None
        self.assertEqual(dark.get("filename"), "AppIcon-Dark.png")
        self.assertTrue((PHONE_SET / "AppIcon-Dark.png").is_file())
        self.assertTrue((PHONE_SET / "AppIcon.png").is_file())

    def test_watch_has_single_icon_without_dark_slot(self) -> None:
        """watchOS AppIcon has no dark/tinted wells; dark PNG → actool unassigned child."""
        contents = json.loads((WATCH_SET / "Contents.json").read_text(encoding="utf-8"))
        self.assertIsNone(
            _dark_entry(contents),
            "Watch AppIcon must not declare luminosity=dark",
        )
        self.assertFalse(
            (WATCH_SET / "AppIcon-Dark.png").exists(),
            "Watch AppIcon-Dark.png must not exist in the appiconset",
        )
        self.assertTrue((WATCH_SET / "AppIcon.png").is_file())
        images = contents.get("images", [])
        self.assertEqual(len(images), 1)
        self.assertEqual(images[0].get("filename"), "AppIcon.png")
        self.assertEqual(images[0].get("platform"), "watchos")

    def test_masters_exist_and_generator_matches_outputs(self) -> None:
        self.assertTrue((MASTER_DIR / "AppIcon-Master.png").is_file())
        self.assertTrue((MASTER_DIR / "AppIcon-Dark-Master.png").is_file())
        gen_src = GEN.read_text(encoding="utf-8")
        self.assertIn("AppIcon-Master.png", gen_src)
        self.assertIn("AppIcon-Dark-Master.png", gen_src)
        self.assertIn("make_android_foreground", gen_src)
        result = subprocess.run(
            ["python3", str(GEN), "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(
            result.returncode,
            0,
            msg=result.stdout + result.stderr,
        )

    def test_light_and_dark_backgrounds_differ(self) -> None:
        _, _, light = _decode_png(PHONE_SET / "AppIcon.png")
        _, _, dark = _decode_png(PHONE_SET / "AppIcon-Dark.png")
        self.assertNotEqual(light, dark)
        # Corner pixels: light ≈ brand green, dark ≈ black.
        lr, lg, lb = light[0], light[1], light[2]
        dr, dg, db = dark[0], dark[1], dark[2]
        light_dist = math.sqrt(
            (lr - BRAND[0]) ** 2 + (lg - BRAND[1]) ** 2 + (lb - BRAND[2]) ** 2
        )
        self.assertLessEqual(light_dist, 40, "light icon corner should be brand green")
        self.assertLessEqual(dr + dg + db, 30, "dark icon corner should be near black")

    def test_android_wear_night_launcher_background_is_black(self) -> None:
        for label, night, day in (
            ("mobile", MOBILE_NIGHT, MOBILE_DAY),
            ("wear", WEAR_NIGHT, WEAR_DAY),
        ):
            self.assertTrue(night.is_file(), f"{label} values-night/colors.xml missing")
            night_text = night.read_text(encoding="utf-8")
            day_text = day.read_text(encoding="utf-8")
            self.assertIn(
                'name="ic_launcher_background">#FF000000</color>',
                night_text.replace(" ", ""),
                f"{label} night ic_launcher_background must be #FF000000",
            )
            self.assertIn(
                'name="ic_launcher_background">#FF30D158</color>',
                day_text.replace(" ", ""),
                f"{label} day ic_launcher_background must stay #FF30D158",
            )

    def test_android_fg_has_no_solid_brand_plate(self) -> None:
        for label, path in (
            ("mobile", ROOT / "android/mobile/src/main/res/drawable/ic_launcher_foreground.png"),
            ("wear", ROOT / "android/wear/src/main/res/drawable/ic_launcher_foreground.png"),
        ):
            width, height, pixels = _decode_png(path)
            self.assertEqual((width, height), (432, 432))
            brandish = transparent = 0
            for i in range(0, len(pixels), 4):
                if pixels[i + 3] < 8:
                    transparent += 1
                    continue
                r, g, b = pixels[i], pixels[i + 1], pixels[i + 2]
                dist = math.sqrt(
                    (r - BRAND[0]) ** 2 + (g - BRAND[1]) ** 2 + (b - BRAND[2]) ** 2
                )
                if dist <= 28:
                    brandish += 1
            self.assertGreater(transparent, 50_000, f"{label} FG should be mostly transparent")
            self.assertEqual(
                brandish,
                0,
                f"{label} ic_launcher_foreground still has brand-green plate ({brandish})",
            )


if __name__ == "__main__":
    unittest.main()
