#!/usr/bin/env python3
"""Emit the explicit AndroidJUnitRunner 'class' selector for enabled device tests.

The runner/Gradle bridge reports excluded (@Ignore/notClass) tests as blank
<failure/> XML elements in this SDK combination. Those were never executed,
and must neither fail the enabled suite nor be counted as successful.
Keep the excluded class list versioned in ci-instrumented-quarantine.txt.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ANDROID = Path(__file__).resolve().parent
SOURCES = ANDROID / "mobile/src/androidTest/java"
QUARANTINE = ANDROID / "ci-instrumented-quarantine.txt"

def selected_tests() -> list[str]:
    excluded = {
        line.strip() for line in QUARANTINE.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    discovered: set[str] = set()
    for path in sorted(SOURCES.rglob("*Test.kt")):
        content = path.read_text(encoding="utf-8")
        package = re.search(r"(?m)^\s*package\s+([a-zA-Z0-9_.]+)", content)
        if package is None:
            raise RuntimeError(f"Missing package for test source {path}")
        class_name = path.stem
        if not re.search(r"\bclass\s+" + re.escape(class_name) + r"\b", content):
            raise RuntimeError(f"Test class does not match source filename: {path}")
        discovered.add(package.group(1) + "." + class_name)

    unknown = excluded - discovered
    if unknown:
        raise RuntimeError(f"Quarantine references missing test classes: {sorted(unknown)}")
    selected = sorted(discovered - excluded)
    if len(selected) < 45:
        raise RuntimeError(f"Enabled instrumented test inventory unexpectedly small: {len(selected)}")
    print(
        f"CI selected {len(selected)} classes; "
        f"excluded {len(excluded)} quarantined classes (not claimed as passing)",
        file=sys.stderr,
    )
    return selected

if __name__ == "__main__":
    print(",".join(selected_tests()))
