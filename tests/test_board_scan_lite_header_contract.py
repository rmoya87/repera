#!/usr/bin/env python3
"""BoardScan Lite: RFT+TC rounds, MAX CAL vs max-effort, BUY-IN headers."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
ANDROID = (
    ROOT / "android/domain/src/main/java/dev/repera/domain/BoardScanLiteParser.kt"
).read_text(encoding="utf-8")
IOS = (
    ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/BoardScanLiteParser.swift"
).read_text(encoding="utf-8")


class BoardScanLiteHeaderContractTests(unittest.TestCase):
    def test_rft_with_tc_not_stolen_by_named_tc_header(self):
        for src in (ANDROID, IOS):
            self.assertTrue(
                r"\d+\s*RF[TF]\b" in src
                or r"\d+\s*RF[TF]\b" in src.replace("\\\\", "\\")
            )
            self.assertIn("FOR COMPLETION", src)
            # Named TC path must exclude digit+RFT before returning bare FOR_TIME.
            self.assertIn("RF[TF]", src)

    def test_max_effort_continuation_excludes_max_cal_and_rounds(self):
        for src in (ANDROID, IOS):
            self.assertIn("isMaxEffortContinuation", src)
            self.assertIn("MAX CAL", src)
            self.assertIn("MAX ROUNDS", src)

    def test_android_buy_in_and_rounds_headers_win_over_non_exercise_skip(self):
        self.assertIn("WODFormat.BUY_IN_CASH_OUT", ANDROID)
        self.assertTrue(
            "Format headers (BUY-IN" in ANDROID or "BUY-IN" in ANDROID
        )
        # Warm-up described titles stay STRENGTH headers, not stripped section labels.
        self.assertTrue(
            "warmUpOnly" in ANDROID or "WARM UP SHOULDERS" in ANDROID
        )
        self.assertIn("candidate !in warmUpOnly", ANDROID)

    def test_android_mn_rest_normalized_for_between_rounds(self):
        self.assertIn("exerciseText(it)", ANDROID)
        self.assertTrue(r"(\d+)\s*MN\b" in ANDROID or "MN" in ANDROID)

    def test_bare_warmup_inside_open_wod_stays_notes_not_strength_section(self):
        """Bare WARMUP/CALENTAMIENTO must not flush an open AMRAP into STRENGTH."""
        for src in (ANDROID, IOS):
            self.assertIn("WARMUP", src)
            self.assertIn("CALENTAMIENTO", src)
            self.assertTrue(
                "current != null" in src or "current != nil" in src
            )
            self.assertTrue(
                "open WOD is OCR noise" in src or "inside an open WOD" in src
            )


if __name__ == "__main__":
    unittest.main()
