"""Contrato: instrumented phone en lotes + conteos del seed empaquetado.

AGP 9.4 + un único -Pclass=a,b,c… truncaba el InstrumentationRunner y solo
ejecutaba la primera clase (falso verde, 2 tests). El runner por lotes y los
assert del seed 447 deben permanecer.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
SEED = ANDROID / "mobile/src/main/assets/catalog_seed.json"


class AndroidInstrumentedBatchContractTests(unittest.TestCase):
    def test_ci_runs_selected_tests_in_batches(self):
        wf = (ROOT / ".github/workflows/android-native-ci.yml").read_text(encoding="utf-8")
        self.assertIn("bash android/ci_run_selected_android_tests.sh", wf)
        self.assertNotIn(
            'testInstrumentationRunnerArguments.class="$SELECTED_CLASSES"',
            wf,
        )
        script = (ANDROID / "ci_run_selected_android_tests.sh").read_text(encoding="utf-8")
        self.assertIn("BATCH_SIZE", script)
        self.assertIn("connectedDebugAndroidTest", script)
        # Path del XML como argv de python3 (heredoc detrás rompe sys.argv → exit 126).
        self.assertIn('python3 - "$xml" <<\'PY\'', script)

    def test_bundled_catalog_seed_count_is_447(self):
        seed = json.loads(SEED.read_text(encoding="utf-8"))
        self.assertEqual(447, len(seed))

    def test_instrumented_catalog_asserts_match_seed(self):
        hyrox = (
            ANDROID
            / "mobile/src/androidTest/java/dev/repera/mobile/HyroxCatalogInstrumentedTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("assertEquals(447, catalog.length())", hyrox)
        refresh = (
            ANDROID
            / "mobile/src/androidTest/java/dev/repera/mobile/CatalogRefreshInstrumentedTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("assertEquals(357, catalog.length())", refresh)
        detail = (
            ANDROID
            / "mobile/src/androidTest/java/dev/repera/mobile/ExerciseDetailInstrumentedTest.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("assertEquals(529, total)", detail)


if __name__ == "__main__":
    unittest.main()
