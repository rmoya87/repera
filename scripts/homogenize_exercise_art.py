#!/usr/bin/env python3
"""DEPRECATED para regenerar arte.

El arte ExerciseArt se genera de cero (GenerateImage) con estilo anatómico
gris + lime sobre charcoal. Este script solo re-exporta thumbs desde los full
ya existentes (resize limpio, sin flood-fill ni crush).

Uso:
  .venv-art/bin/python scripts/homogenize_exercise_art.py
  .venv-art/bin/python scripts/export_generated_art.py <src> <stem>
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Apps/Repera/Resources/ExerciseArt"
THUMBS = ART / "thumbs"
THUMB = 192


def make_thumb(src: Path) -> None:
    im = Image.open(src).convert("RGB")
    thumb = im.resize((THUMB, THUMB), Image.Resampling.LANCZOS)
    thumb = ImageEnhance.Contrast(thumb).enhance(1.12)
    thumb = thumb.filter(ImageFilter.UnsharpMask(radius=1.2, percent=120, threshold=2))
    THUMBS.mkdir(exist_ok=True)
    thumb.save(THUMBS / src.name, format="JPEG", quality=88, optimize=True)


def main() -> None:
    files = sorted(ART.glob("art_*.jpg"))
    print(f"Rebuild thumbs for {len(files)} full images…", flush=True)
    for i, f in enumerate(files, 1):
        make_thumb(f)
        if i % 50 == 0 or i == len(files):
            print(f"  {i}/{len(files)}", flush=True)
    print(f"thumbs={len(list(THUMBS.glob('art_*.jpg')))} size={THUMB}px", flush=True)


if __name__ == "__main__":
    main()
