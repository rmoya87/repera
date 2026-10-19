#!/usr/bin/env python3
"""Convierte PNG/JPG generados → full 1024 JPG + thumbs 192. Sin homogenize destructivo."""
from __future__ import annotations
import sys
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Apps/Repera/Resources/ExerciseArt"
THUMBS = ART / "thumbs"
FULL = 1024
THUMB = 192

def export_one(src: Path, stem: str) -> None:
    im = Image.open(src).convert("RGB")
    # square center-crop
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    im = im.crop((left, top, left + side, top + side))
    full = im.resize((FULL, FULL), Image.Resampling.LANCZOS)
    full = full.filter(ImageFilter.UnsharpMask(radius=0.7, percent=70, threshold=3))
    out = ART / f"{stem}.jpg"
    full.save(out, format="JPEG", quality=93, optimize=True, progressive=True)
    thumb = im.resize((THUMB, THUMB), Image.Resampling.LANCZOS)
    thumb = ImageEnhance.Contrast(thumb).enhance(1.15)
    thumb = thumb.filter(ImageFilter.UnsharpMask(radius=1.2, percent=130, threshold=2))
    THUMBS.mkdir(exist_ok=True)
    thumb.save(THUMBS / f"{stem}.jpg", format="JPEG", quality=88, optimize=True)
    print(f"OK {stem} full={out.stat().st_size}B thumb={(THUMBS/f'{stem}.jpg').stat().st_size}B")

def main() -> None:
    if len(sys.argv) < 2:
        print("usage: export_generated_art.py <src.png|jpg> [stem]")
        sys.exit(1)
    src = Path(sys.argv[1])
    stem = sys.argv[2] if len(sys.argv) > 2 else src.stem
    export_one(src, stem)

if __name__ == "__main__":
    main()
