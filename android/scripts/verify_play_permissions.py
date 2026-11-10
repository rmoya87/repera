#!/usr/bin/env python3
"""Block Google Play release if the final, merged release manifest has ad IDs.

These are final Android Gradle Plugin artifacts, NOT the source manifest:
tools:node="remove" is intentionally retained to prevent transitive permissions.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

ADS = {
    "com.google.android.gms.permission.AD_ID",
    "android.permission.ACCESS_ADSERVICES_AD_ID",
    "android.permission.ACCESS_ADSERVICES_ATTRIBUTION",
    "android.permission.ACCESS_ADSERVICES_TOPICS",
}
NS = "{http://schemas.android.com/apk/res/android}"


def read_permissions(path: Path) -> set[str]:
    root = ET.parse(path).getroot()
    return {
        node.get(NS + "name", "")
        for node in root
        if node.tag in {"uses-permission", "uses-permission-sdk-23", "uses-permission-sdk-m"}
    }


def validate_release_manifest(root: Path) -> list[Path]:
    if not root.is_dir():
        raise FileNotFoundError(f"No hay artefactos de manifiesto: {root}")
    matches = [
        p for p in root.rglob("AndroidManifest.xml")
        if "release" in p.parts and any(
            "merged_manifest" in section or "packaged_manifest" in section
            for section in p.parts
        )
    ]
    if not matches:
        raise FileNotFoundError("No hay manifiesto merged/packaged de release para verificar")
    for path in sorted(matches):
        found = ADS.intersection(read_permissions(path))
        if found:
            raise ValueError(f"Permisos publicitarios en {path}: {', '.join(sorted(found))}")
    return matches


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("intermediates", type=Path)
    args = parser.parse_args()
    matches = validate_release_manifest(args.intermediates)
    print(f"Permisos publicitarios ausentes en {len(matches)} manifest(s) release verificados")


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError, ET.ParseError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
