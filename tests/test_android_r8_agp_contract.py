"""Contrato: AGP con R8 outliner seguro para Comenzar release.

AGP 9.4.0 puede emitir DEX que ART rechaza al componer LiveActivityScreen
(VerifyError: register Undefined but expected Integer; b/551348855).
No sustituye instalar un AAB release en hardware.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID_ROOT = ROOT / "android"


def _agp_versions(build_gradle: str) -> list[tuple[int, int, int]]:
    found: list[tuple[int, int, int]] = []
    for match in re.finditer(
        r'id\("com\.android\.(?:application|library)"\)\s+version\s+"(\d+)\.(\d+)\.(\d+)"',
        build_gradle,
    ):
        found.append(tuple(int(part) for part in match.groups()))  # type: ignore[arg-type]
    return found


class AndroidR8AgpContractTests(unittest.TestCase):
    def test_agp_at_least_9_4_1_for_r8_outliner_fix(self):
        build = (ANDROID_ROOT / "build.gradle.kts").read_text(encoding="utf-8")
        versions = _agp_versions(build)
        self.assertGreaterEqual(len(versions), 2, "application + library AGP pins missing")
        for version in versions:
            self.assertGreaterEqual(
                version,
                (9, 4, 1),
                f"AGP {'.'.join(map(str, version))} < 9.4.1: R8 outliner VerifyError en Comenzar",
            )

    def test_live_activity_screen_still_has_release_sensitive_signature(self):
        # La firma que falló en dispositivo: defaults Compose + flags changed.
        src = (
            ANDROID_ROOT
            / "mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("onSavedAndEdit: (sessionId: String) -> Unit = onSaved", src)
        self.assertIn("autoStartAfterChoose: Boolean = false", src)
        self.assertIn("@Composable\ninternal fun LiveActivityScreen(", src)

    def test_release_still_minifies_with_optimize_defaults(self):
        mobile = (ANDROID_ROOT / "mobile/build.gradle.kts").read_text(encoding="utf-8")
        self.assertIn("isMinifyEnabled = true", mobile)
        self.assertIn("proguard-android-optimize.txt", mobile)


if __name__ == "__main__":
    unittest.main()
