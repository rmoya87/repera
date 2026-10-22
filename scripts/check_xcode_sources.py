#!/usr/bin/env python3
"""Check that the generated Xcode project compiles Auth and AI feature stores.

XcodeGen project files are local/generated and can be older than checked-out Swift.
Never delete them or change app data: regenerate with `xcodegen generate`.
"""
from __future__ import annotations

import argparse
import re
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
    "AITrainingProgramsView.swift",
    "AIChangeRequestStore.swift",
)
WATCH_REQUIRED = (
    "ReperaWatchApp.swift",
    "WatchSessionHub.swift",
    "WatchSessionView.swift",
    "WatchConnectivityClient.swift",
    "WatchHealthKitSession.swift",
)


def _watch_compile_sources(pbx: str) -> str:
    """Read the Watch target\'s Sources phase, not file references elsewhere."""
    native = re.search(
        r"/\* ReperaWatch \*/\s*=\s*\{\s*isa = PBXNativeTarget;(.*?)\n\s*\};",
        pbx, re.DOTALL,
    )
    if native is None:
        raise ValueError("El proyecto generado no incluye el target ReperaWatch. Regenera con xcodegen generate --spec project.yml.")
    build_phases = re.search(r"buildPhases = \((.*?)\);", native.group(1), re.DOTALL)
    phase_id = re.search(r"([A-Fa-f0-9]{24}) /\* Sources \*/", build_phases.group(1)) if build_phases else None
    if phase_id is None:
        raise ValueError("El target ReperaWatch no tiene una fase Compile Sources. Regenera XcodeGen.")
    sources = re.search(
        rf"{phase_id.group(1)} /\* Sources \*/\s*=\s*\{{\s*isa = PBXSourcesBuildPhase;(.*?)\n\s*\}};",
        pbx, re.DOTALL,
    )
    if sources is None:
        raise ValueError("No se pudo leer Compile Sources de ReperaWatch. Regenera XcodeGen.")
    return sources.group(1)


def validate(root: Path) -> None:
    app = root / "Apps" / "Repera" / "Sources"
    missing = [name for name in REQUIRED if not list(app.rglob(name))]
    if missing:
        raise ValueError(
            "Faltan fuentes Swift del target Repera: " + ", ".join(missing)
            + ". Ejecuta git pull origin main; no basta con regenerar Xcode."
        )

    watch = root / "Apps" / "ReperaWatch" / "Sources"
    missing_watch = [name for name in WATCH_REQUIRED if not (watch / name).is_file()]
    if missing_watch:
        raise ValueError(
            "Faltan fuentes Swift del Apple Watch: " + ", ".join(missing_watch)
            + ". Ejecuta git pull origin main antes de regenerar Xcode."
        )

    spec = (root / "project.yml").read_text(encoding="utf-8")
    if "- path: Apps/Repera/Sources" not in spec:
        raise ValueError("project.yml ya no incluye el directorio del target Repera.")
    if "  ReperaWatch:" not in spec or "- path: Apps/ReperaWatch/Sources" not in spec:
        raise ValueError("project.yml no incluye todas las fuentes del target ReperaWatch.")
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

    watch_sources = _watch_compile_sources(pbx)
    for name in WATCH_REQUIRED:
        if f"{name} in Sources" not in watch_sources:
            raise ValueError(
                f"ReperaWatch no compila {name}: falta en Build Phases → Compile Sources. "
                "Cierra Xcode, regenera con xcodegen generate --spec project.yml "
                "y vuelve a abrir Repera.xcodeproj."
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
    print("OK: fuentes iOS y ReperaWatch, incluido WatchHealthKitSession.swift, en Compile Sources de sus targets.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
