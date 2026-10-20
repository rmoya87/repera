#!/usr/bin/env python3
"""Synchronize Repera's shared Xcode version settings.

XcodeGen's generated .xcodeproj isn't tracked, so version edits in Xcode must
be saved into Configs/Version.xcconfig before the project is regenerated.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "Configs" / "Version.xcconfig"
PROJECT = ROOT / "Repera.xcodeproj"
MARKETING_RE = re.compile(r"\d+(?:\.\d+){0,2}\Z")
BUILD_RE = re.compile(r"\d+(?:\.\d+){0,2}\Z")
KEYS = ("REPERA_MARKETING_VERSION", "REPERA_BUILD_NUMBER")


def validate(marketing: str, build: str) -> tuple[str, str]:
    marketing, build = marketing.strip(), build.strip()
    if not MARKETING_RE.fullmatch(marketing):
        raise ValueError(f"Versión comercial no válida: {marketing!r} (ejemplo: 1.2.3)")
    if not BUILD_RE.fullmatch(build):
        raise ValueError(f"Número de compilación no válido: {build!r} (ejemplo: 42)")
    return marketing, build


def read_config() -> tuple[str, str]:
    data = CONFIG.read_text(encoding="utf-8")
    values = {}
    for key in KEYS:
        matches = re.findall(rf"(?m)^\s*{key}\s*=\s*([^\s/#]+)\s*(?:/[/\*].*)?$", data)
        if len(matches) != 1:
            raise ValueError(f"{CONFIG}: se esperaba una única definición de {key}")
        values[key] = matches[0]
    return validate(values[KEYS[0]], values[KEYS[1]])


def write_config(marketing: str, build: str) -> bool:
    marketing, build = validate(marketing, build)
    original = CONFIG.read_text(encoding="utf-8")
    updated = original
    for key, value in zip(KEYS, (marketing, build)):
        line = re.compile(rf"(?m)^({key}\s*=\s*)([^\r\n]*)(\r?)$")
        updated, n = line.subn(lambda m: m.group(1) + value + m.group(3), updated)
        if n != 1:
            raise ValueError(f"{CONFIG}: se esperaba una única definición de {key}")
    if updated == original:
        return False
    temp = CONFIG.with_suffix(".xcconfig.tmp")
    try:
        temp.write_text(updated, encoding="utf-8")
        temp.replace(CONFIG)
    finally:
        temp.unlink(missing_ok=True)
    return True


def from_project() -> tuple[str, str] | None:
    """Read effective *Repera target* values from the Xcode project before regeneration."""
    if not PROJECT.is_dir():
        return None
    try:
        result = subprocess.run(
            ["xcodebuild", "-project", str(PROJECT), "-target", "Repera",
             "-configuration", "Release", "-showBuildSettings"],
            capture_output=True, text=True, timeout=90, check=True,
        )
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        print(f"Aviso: no se pudieron leer las versiones de Xcode ({exc}); se conserva {CONFIG.name}.", file=sys.stderr)
        return None
    values = {}
    for line in result.stdout.splitlines():
        match = re.match(r"^\s*(MARKETING_VERSION|CURRENT_PROJECT_VERSION)\s*=\s*(.*?)\s*$", line)
        if match:
            values[match.group(1)] = match.group(2)
    if len(values) != 2:
        print("Aviso: Xcode no devolvió ambas versiones; se conserva Version.xcconfig.", file=sys.stderr)
        return None
    return validate(values["MARKETING_VERSION"], values["CURRENT_PROJECT_VERSION"])


def check_wiring() -> None:
    """Check that XcodeGen and source plists use build-setting substitutions."""
    spec = (ROOT / "project.yml").read_text(encoding="utf-8")
    for needle in (
        "Configs/Version.xcconfig", "MARKETING_VERSION: \"$(REPERA_MARKETING_VERSION)\"",
        "CURRENT_PROJECT_VERSION: \"$(REPERA_BUILD_NUMBER)\"",
    ):
        if needle not in spec:
            raise ValueError(f"project.yml no contiene {needle}")
    for path in (
        "Apps/Repera/Resources/Info.plist",
        "Apps/ReperaWatch/Resources/Info.plist",
        "Apps/ReperaRestWidget/Info.plist",
    ):
        import plistlib
        with (ROOT / path).open("rb") as f:
            data = plistlib.load(f)
        if (data.get("CFBundleShortVersionString"), data.get("CFBundleVersion")) != (
            "$(MARKETING_VERSION)", "$(CURRENT_PROJECT_VERSION)"
        ):
            raise ValueError(f"{path}: las claves de versión no utilizan variables de Xcode")


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    actions = cli.add_mutually_exclusive_group(required=True)
    actions.add_argument("--from-env", action="store_true", help="Xcode Scheme Pre-action: recoge los ajustes del target Repera")
    actions.add_argument("--from-project", action="store_true", help="XcodeGen preGenCommand: conserva cambios hechos en Xcode")
    actions.add_argument("--set", nargs=2, metavar=("VERSION", "BUILD"), help="Cambio manual de versión y compilación")
    actions.add_argument("--check", action="store_true", help="Valida configuración y plists")
    args = cli.parse_args()
    try:
        if args.check:
            marketing, build = read_config()
            check_wiring()
            print(f"OK: Repera {marketing} ({build}) — iOS, Watch y widget usan versiones compartidas")
            return 0
        if args.from_env:
            marketing = os.environ.get("MARKETING_VERSION", "")
            build = os.environ.get("CURRENT_PROJECT_VERSION", "")
            if not marketing or not build:
                raise ValueError("Xcode no proporcionó MARKETING_VERSION o CURRENT_PROJECT_VERSION")
            pair = validate(marketing, build)
        elif args.from_project:
            pair = from_project()
            if pair is None:
                return 0  # First generation, CI or an unavailable Xcode project.
        else:
            pair = validate(*args.set)
        changed = write_config(*pair)
        print(f"Repera {pair[0]} ({pair[1]}) — Version.xcconfig {'actualizado' if changed else 'sin cambios'}")
        return 0
    except (OSError, ValueError) as exc:
        print(f"ERROR al sincronizar las versiones: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
