#!/usr/bin/env python3
"""Inspect native packaging without changing third-party binaries or build outputs."""
from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

KNOWN = (
    "libandroidx.graphics.path.so",
    "libdatastore_shared_counter.so",
    "libicing.so",
    "libmaplibre.so",
    "libmlkit_google_ocr_pipeline.so",
)


def report(module: Path, variant: str) -> str:
    root = module / "build" / "intermediates"
    sources = sorted(root.glob(f"merged_native_libs/{variant}/**/*.so"))
    if not sources:
        sources = sorted(root.glob(f"stripped_native_libs/{variant}/**/*.so"))
    lines = ["### Bibliotecas nativas: diagnóstico de empaquetado",
             f"- Variante: {variant}. Solo lectura: no se modifican archivos .so.",
             f"- Bibliotecas halladas en intermediarios de Gradle: {len(sources)}"]
    tool = shutil.which("readelf")
    for filename in KNOWN:
        match = [path for path in sources if path.name == filename]
        if not match:
            lines.append(f"- {filename}: no localizado en los intermediarios.")
            continue
        path = match[0]
        size = path.stat().st_size
        flags = []
        if tool:
            result = subprocess.run([tool, "-S", str(path)], capture_output=True,
                                    text=True, check=False)
            if result.returncode == 0:
                flags = [flag for flag in (".symtab", ".debug_info", ".gnu_debuglink")
                         if flag in result.stdout]
        lines.append(f"- {filename}: {size} bytes; secciones: {', '.join(flags) or 'ninguna identificada'}")
    lines.append("- El aviso de strip no implica que falten bibliotecas ni altera la validación.")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--module", type=Path, required=True)
    parser.add_argument("--variant", default="release")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(report(args.module, args.variant), encoding="utf-8")


if __name__ == "__main__":
    main()
