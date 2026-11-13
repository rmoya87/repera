"""Contrato: AGP + keep Compose seguros para release minificado.

AGP 9.4.0 podía emitir DEX que ART rechaza (VerifyError outliner,
b/551348855) en LiveActivityScreen. AGP 9.4.1 mitigó ese caso, pero Play
2026.11.9 (vc 455809) con 9.4.1 aún VerifyError al abrir «Añadir entreno»
(clase ofuscada Compose). Pin ≥ 9.5.1 + keep @Composable + disableOutlining.
No sustituye instalar un AAB/APK release en hardware.
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
    def test_agp_at_least_9_5_1_for_r8_compose_verifyerror(self):
        build = (ANDROID_ROOT / "build.gradle.kts").read_text(encoding="utf-8")
        versions = _agp_versions(build)
        self.assertGreaterEqual(len(versions), 2, "application + library AGP pins missing")
        for version in versions:
            self.assertGreaterEqual(
                version,
                (9, 5, 1),
                f"AGP {'.'.join(map(str, version))} < 9.5.1: VerifyError Compose/R8 en Play",
            )

    def test_proguard_keeps_compose_methods_from_r8_outline_bugs(self):
        rules = (ANDROID_ROOT / "mobile/proguard-rules.pro").read_text(encoding="utf-8")
        self.assertIn(
            "@androidx.compose.runtime.Composable <methods>",
            rules,
        )
        self.assertIn("class androidx.**", rules)
        self.assertIn("class dev.repera.mobile.**", rules)

    def test_gradle_disables_r8_outlining(self):
        props = (ANDROID_ROOT / "gradle.properties").read_text(encoding="utf-8")
        self.assertIn("com.android.tools.r8.disableOutlining=true", props)

    def test_live_activity_screen_still_has_release_sensitive_signature(self):
        # La firma que falló en dispositivo: defaults Compose + flags changed.
        src = (
            ANDROID_ROOT
            / "mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("onSavedAndEdit: (sessionId: String) -> Unit = onSaved", src)
        self.assertIn("autoStartAfterChoose: Boolean = false", src)
        self.assertIn("@Composable\ninternal fun LiveActivityScreen(", src)

    def test_day_plus_sheet_is_composable_entry(self):
        src = (
            ANDROID_ROOT / "mobile/src/main/java/dev/repera/mobile/DayPlusSheet.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("@Composable\ninternal fun DayPlusSheet(", src)
        self.assertIn("Añadir entreno", src)

    def test_release_still_minifies_with_optimize_defaults(self):
        mobile = (ANDROID_ROOT / "mobile/build.gradle.kts").read_text(encoding="utf-8")
        self.assertIn("isMinifyEnabled = true", mobile)
        self.assertIn("proguard-android-optimize.txt", mobile)


if __name__ == "__main__":
    unittest.main()
