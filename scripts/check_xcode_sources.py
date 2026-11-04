#!/usr/bin/env python3
"""Check the generated Xcode project compiles required iOS and all Watch sources.

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
    "RemoteExerciseCatalogStore.swift",
    "LiveActivityView.swift",
    "LiveActivityLocationName.swift",
    "WorkoutLiveActivityCoordinator.swift",
    "LiveSportHistoryView.swift",
    "OGDuoContextRail.swift",
    "ReperaAnalytics.swift",
)
WATCH_REQUIRED = (
    "ReperaWatchApp.swift",
    "WatchSessionHub.swift",
    "WatchSessionView.swift",
    "WatchConnectivityClient.swift",
    "WatchHealthKitSession.swift",
)
SHARED_WEATHER_REQUIRED = (
    "AppleWeatherConditionsClient.swift",
    "AppleWeatherAttributionView.swift",
)


def _target_compile_sources(pbx: str, target: str) -> str:
    """Inspect the actual target Sources phase, not just project file references."""
    native = re.search(
        rf"/\* {re.escape(target)} \*/\s*=\s*\{{\s*isa = PBXNativeTarget;(.*?)\n\s*\}};",
        pbx, re.DOTALL,
    )
    if native is None:
        raise ValueError(
            f"El proyecto generado no incluye el target {target}. "
            "Regenera con xcodegen generate --spec project.yml."
        )
    phases = re.search(r"buildPhases = \((.*?)\);", native.group(1), re.DOTALL)
    phase_id = re.search(r"([A-Fa-f0-9]{24}) /\* Sources \*/", phases.group(1)) if phases else None
    if phase_id is None:
        raise ValueError(f"El target {target} no tiene fase Compile Sources.")
    source_phase = re.search(
        rf"{phase_id.group(1)} /\* Sources \*/\s*=\s*\{{\s*isa = PBXSourcesBuildPhase;(.*?)\n\s*\}};",
        pbx, re.DOTALL,
    )
    if source_phase is None:
        raise ValueError(f"No se pudo leer Compile Sources del target {target}.")
    return source_phase.group(1)


def _watch_compile_sources(pbx: str) -> str:
    return _target_compile_sources(pbx, "ReperaWatch")


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

    shared = root / "Apps" / "Shared"
    missing_shared = [
        name for name in SHARED_WEATHER_REQUIRED if not (shared / name).is_file()
    ]
    if missing_shared:
        raise ValueError(
            "Faltan fuentes WeatherKit compartidas: " + ", ".join(missing_shared)
            + ". Ejecuta git pull --ff-only origin main antes de regenerar Xcode."
        )

    spec = (root / "project.yml").read_text(encoding="utf-8")
    if "- path: Apps/Repera/Sources" not in spec:
        raise ValueError("project.yml ya no incluye el directorio del target Repera.")
    for name in ("RemoteExerciseCatalogStore.swift", "LiveActivityView.swift",
                 "LiveActivityLocationName.swift",
                 "WorkoutLiveActivityCoordinator.swift", "LiveSportHistoryView.swift",
                 "OGDuoContextRail.swift"):
        if f"- path: Apps/Repera/Sources/{name}" not in spec:
            raise ValueError(
                f"project.yml no incluye expresamente {name}. "
                "Comprueba el target Repera y regenera Xcode."
            )
    if "- path: Apps/Repera/Sources/Analytics/ReperaAnalytics.swift" not in spec:
        raise ValueError(
            "project.yml no incluye expresamente Analytics/ReperaAnalytics.swift. "
            "Comprueba el target Repera y regenera Xcode."
        )
    if "- path: Apps/Shared/TrainingActivityAttributes.swift" not in spec:
        raise ValueError("project.yml no incluye TrainingActivityAttributes.swift para ActivityKit.")
    if "  ReperaWatch:" not in spec or "- path: Apps/ReperaWatch/Sources" not in spec:
        raise ValueError("project.yml no incluye todas las fuentes del target ReperaWatch.")
    if "product: Supabase" not in spec:
        raise ValueError("El target Repera carece de la dependencia de Supabase.")

    # The weather sources live outside the directory-scanned target roots.
    # A stale project.yml or project.pbxproj can therefore compile Watch
    # screens but fail with "Cannot find AppleWeatherConditionsClient in scope".
    for target in ("Repera", "ReperaWatch"):
        section = re.search(
            rf"^  {re.escape(target)}:\n(.*?)(?=^  [A-Za-z][A-Za-z0-9_]*:\n|\Z)",
            spec, re.MULTILINE | re.DOTALL,
        )
        if section is None:
            raise ValueError(f"project.yml no declara el target {target}.")
        for name in SHARED_WEATHER_REQUIRED:
            if f"- path: Apps/Shared/{name}" not in section.group(1):
                raise ValueError(
                    f"project.yml no incluye {name} en {target}. "
                    "Actualiza project.yml desde main y regenera con XcodeGen."
                )

    project = root / "Repera.xcodeproj" / "project.pbxproj"
    if not project.is_file():
        raise ValueError("No existe Repera.xcodeproj. Regenera con xcodegen generate --spec project.yml.")

    pbx = project.read_text(encoding="utf-8")
    app_sources = _target_compile_sources(pbx, "Repera")
    for name in (*REQUIRED, *SHARED_WEATHER_REQUIRED):
        # A file reference alone is not enough: the Swift source must belong to
        # the app's Compile Sources phase, or references to its types will fail.
        if f"{name} in Sources" not in app_sources:
            raise ValueError(
                f"Xcode utiliza un proyecto antiguo sin {name} en Repera. "
                "Cierra Xcode y ejecuta xcodegen generate --spec project.yml."
            )

    watch_sources = _watch_compile_sources(pbx)
    # Verify every current Watch Swift source, not just a fixed list:
    # adding a new view must not silently leave its type out of this target.
    watch_swift = {p.name for p in watch.glob("*.swift")}
    for name in sorted(watch_swift | set(WATCH_REQUIRED) | set(SHARED_WEATHER_REQUIRED)):
        if f"{name} in Sources" not in watch_sources:
            raise ValueError(
                f"ReperaWatch no compila {name}: falta en Build Phases → Compile Sources. "
                "Cierra Xcode, regenera con xcodegen generate --spec project.yml "
                "y vuelve a abrir Repera.xcodeproj."
            )

    # WidgetKit extension: SharedStore defines ReperaComplicationSnapshot.
    # El render usa ReperaIcon del asset catalog; AppIconStore ya no forma parte del target.
    widget_sources = _target_compile_sources(pbx, "ReperaWatchWidget")
    for name in (
        "ReperaWatchWidget.swift",
        "ReperaComplicationSharedStore.swift",
    ):
        if f"{name} in Sources" not in widget_sources:
            raise ValueError(
                f"ReperaWatchWidget no compila {name}: falta en Build Phases → Compile Sources. "
                "Cierra Xcode, regenera con xcodegen generate --spec project.yml "
                "y vuelve a abrir Repera.xcodeproj."
            )
    if "ReperaComplicationAppIconStore.swift in Sources" in widget_sources:
        raise ValueError(
            "ReperaWatchWidget no debe compilar ReperaComplicationAppIconStore.swift; "
            "el icono canónico es ReperaIcon en Assets.xcassets."
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
    print(
        "OK: fuentes iOS, ReperaWatch, Widget, WeatherKit y En vivo "
        "incluidas en Compile Sources."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
