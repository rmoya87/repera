"""Regression contracts for native wrist-entered advanced WOD scores.

Source-level checks; compilation and physical watch integration remain separate.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WATCH = (ROOT / "Apps/ReperaWatch/Sources/WatchSessionHub.swift").read_text(encoding="utf-8")
WATCH_UI = (ROOT / "Apps/ReperaWatch/Sources/WatchSessionView.swift").read_text(encoding="utf-8")
WEAR = (ROOT / "android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt").read_text(encoding="utf-8")
WEAR_UI = (ROOT / "android/wear/src/main/java/dev/repera/wear/WearHomeContent.kt").read_text(encoding="utf-8")
PHONE = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt").read_text(encoding="utf-8")


class WristWodScoringContracts(unittest.TestCase):
    def test_watch_records_partials_without_finishing(self):
        partial = WATCH.split("func saveReviewPhaseResult() {", 1)[1].split(
            "    func adjustRounds(", 1
        )[0]
        self.assertIn("ctrl.recordWODResult(score)", partial)
        self.assertIn("phaseResults = rows", partial)
        self.assertIn("participantIndex: athlete", partial)
        self.assertNotIn("finishCurrentBlock()", partial)
        self.assertNotIn("finishWorkout()", partial)
        self.assertIn("Button(\"Guardar parcial\")", WATCH_UI)

    def test_watch_preserves_partials_when_finishing_global_score(self):
        confirm = WATCH.split("func confirmBlock() {", 1)[1].split(
            "func finishWorkout()", 1
        )[0]
        self.assertIn("phaseResults: existing?.phaseResults", confirm)
        self.assertIn("measuredValue:", confirm)
        self.assertIn("canConfirmReviewBlock", confirm)

    def test_wear_sends_partial_without_advancing_on_phone(self):
        partial = WEAR.split("private fun savePartialWodReview() {", 1)[1].split(
            "private fun beginBlockReview()", 1
        )[0]
        self.assertIn("phaseResult", partial)
        self.assertIn('"/repera/wod-score"', partial)
        self.assertNotIn("finishSessionFromWatch(", partial)
        phone = PHONE.split('if (event.path == "/repera/wod-score") {', 1)[1].split(
            'if (event.path != "/repera/log-set")', 1
        )[0]
        self.assertIn('payload.optJSONObject("phaseResult")', phone)
        self.assertIn(".recordWodPhaseResult(", phone)
        self.assertIn(".recordWodScore(rounds, reps, elapsed, measured, metric)", phone)

    def test_wear_has_true_metric_and_participant_ui(self):
        self.assertIn("reviewMeasuredValue", WEAR_UI)
        self.assertIn("reviewPhaseIteration", WEAR_UI)
        self.assertIn("reviewParticipantIndex", WEAR_UI)
        self.assertIn("reviewPartialReps", WEAR_UI)
        self.assertIn('WearPrimaryButton("Guardar parcial")', WEAR_UI)
        self.assertIn('"measuredMetric"', WEAR)
        self.assertIn('"phaseResults"', WEAR)


if __name__ == "__main__":
    unittest.main()
