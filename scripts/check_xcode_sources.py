#!/usr/bin/env python3
"""Check that the generated Xcode project compiles Auth and AI feature stores.

XcodeGen project files are local/generated and can be older than checked-out Swift.
Never delete them or change app data: regenerate with `xcodegen generate`.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = (
    "AppleAuthStore.swift",
    "BusinessAuthStore.swift",
    "BusinessDataStore.swift",
    "BusinessWorkoutSyncStore.swift",
    "AITrainingInboxStore.swift",
    "AIAccessView.swift",
    "AITrainingContextStore.swift",
    "AITrainingProfileView.swift",
    "AITrainingProgramsView.swift",
)


def validate(root: Path) -> None:
    app = root / "Apps" / "Repera" / "Sources"
    missing = [name for name in REQUIRED if not list(app.rglob(name))]
    if missing:
        raise ValueError(
            "Faltan fuentes Swift del target Repera: " + ", ".join(missing)
            + ". Ejecuta git pull origin main; no basta con regenerar Xcode."
        )

    spec = (root / "project.yml").read_text(encoding="utf-8")
    if "- path: Apps/Repera/Sources" not in spec:
        raise ValueError("project.yml ya no incluye el directorio del target Repera.")
    if "product: Supabase" not in spec:
        raise ValueError("El target Repera carece de la dependencia de Supabase.")

    project = root / "Repera.xcodeproj" / "project.pbxproj"
    if not project.is_file():
        raise ValueError("No existe Repera.xcodeproj. Regenera con xcodegen generate --spec project.yml.")

    pbx = project.read_text(encoding="utf-8")
    for name in REQUIRED:
        # A file reference alone is not enough: the Swift source must belong to
        # the app's Compile Sources phase, or references to its types will fail.
        if f"{name} in Sources" not in pbx:
            raise ValueError(
                f"Xcode utiliza un proyecto antiguo sin {name}. "
                "Cierra Xcode y ejecuta xcodegen generate --spec project.yml."
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        validate(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print("OK: fuentes de autenticación, sincronización y funciones IA en Compile Sources del target Repera.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
