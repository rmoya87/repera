#!/usr/bin/env python3
"""Validate ReperaWatchWidget's source and packaged Info.plist before installation.

XcodeGen creates the project locally; source plist checks alone cannot prove
the .appex that CoreSimulator actually installs has the required keys.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import plistlib
import sys

ROOT = Path(__file__).resolve().parents[1]
BUNDLE_ID = "com.app.repera.watchkitapp.widget"
BUNDLE_NAME = "ReperaWatch"
EXTENSION_POINT = "com.apple.widgetkit-extension"


def read_plist(path: Path) -> dict:
    with path.open("rb") as stream:
        return plistlib.load(stream)


def require_text(data: dict, key: str, path: Path, expected: str | None = None) -> None:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{path}: {key} debe contener texto no vacío")
    if expected is not None and value != expected:
        raise ValueError(f"{path}: {key} debe ser {expected!r}, no {value!r}")


def validate_source(root: Path) -> None:
    path = root / "Apps/ReperaWatchWidget/Info.plist"
    data = read_plist(path)
    require_text(data, "CFBundleName", path, BUNDLE_NAME)
    require_text(data, "CFBundleDisplayName", path)
    require_text(data, "CFBundleExecutable", path)
    require_text(data, "CFBundleIdentifier", path)
    require_text(data, "CFBundleInfoDictionaryVersion", path, "6.0")
    require_text(data, "CFBundlePackageType", path, "XPC!")
    if data.get("NSExtension", {}).get("NSExtensionPointIdentifier") != EXTENSION_POINT:
        raise ValueError(f"{path}: NSExtensionPointIdentifier incorrecto")

    spec_path = root / "project.yml"
    spec = spec_path.read_text(encoding="utf-8")
    target = spec.partition("\n  ReperaWatchWidget:\n")[2].partition("\n  ReperaUITests:\n")[0]
    if not target:
        raise ValueError(f"{spec_path}: falta el target ReperaWatchWidget")
    for setting in (
        "INFOPLIST_FILE: Apps/ReperaWatchWidget/Info.plist",
        "GENERATE_INFOPLIST_FILE: false",
        "CFBundleName: ReperaWatch",
        "CFBundleInfoDictionaryVersion: \"6.0\"",
    ):
        if setting not in target:
            raise ValueError(f"{spec_path}: ReperaWatchWidget debe contener {setting}")


def validate_built(path: Path) -> None:
    data = read_plist(path)
    for key, expected in (
        ("CFBundleName", BUNDLE_NAME),
        ("CFBundleIdentifier", BUNDLE_ID),
        ("CFBundlePackageType", "XPC!"),
        ("CFBundleInfoDictionaryVersion", "6.0"),
    ):
        require_text(data, key, path, expected)
    for key in ("CFBundleExecutable", "CFBundleShortVersionString", "CFBundleVersion"):
        require_text(data, key, path)
        if "$(" in data[key]:
            raise ValueError(f"{path}: {key} conserva una variable Xcode sin resolver")
    if data.get("NSExtension", {}).get("NSExtensionPointIdentifier") != EXTENSION_POINT:
        raise ValueError(f"{path}: la extensión compilada no es WidgetKit")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--built", type=Path, help="Info.plist real dentro de ReperaWatchWidget.appex")
    args = parser.parse_args()
    try:
        validate_source(args.root)
        if args.built is not None:
            validate_built(args.built)
    except (OSError, ValueError, TypeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print("OK: ReperaWatchWidget Info.plist declara CFBundleName y la extensión WidgetKit.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
