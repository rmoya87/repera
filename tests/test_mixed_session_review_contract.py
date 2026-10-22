"""Regression guards for mixed WOD/EMOM review and strict exercise comparability.

Source contracts supplement the Swift test that reproduces the last Supabase
workout's structure with push press, deadlift, ring dips and AMRAP.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class MixedSessionReviewContractTests(unittest.TestCase):
    def test_push_press_must_never_be_scored_against_bench_press(self):
        eq = read("Packages/ReperaDomain/Sources/ReperaDomain/ExerciseEquivalence.swift")
        pressing = eq.split("if cf == .press {", 1)[1].split("if cf == .pull", 1)[0]
        self.assertIn("return 0", pressing)
        self.assertNotIn("return 0.92", pressing)
        self.assertIn("if sameName(current.name, prior.name) { return 1.0 }", eq)

    def test_mixed_session_review_uses_records_from_each_block(self):
        engine = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        self.assertIn("mixedSessionReview(", engine)
        self.assertIn("scoredBlockID: primary.id", engine)
        self.assertIn("session.exercises.filter { $0.blockId == block.id }", engine)
        self.assertIn("entry.loggedSets.filter { !$0.isWarmup }.count", engine)
        self.assertIn("let coverage = min(1.0, Double(observed) / Double(prescribed))", engine)
        self.assertIn("Double(wodReview.overallScore) * primaryMinutes", engine)
        self.assertIn("scoreBasis: .sessionEstimate", engine)
        self.assertIn("level: nil", engine)
        self.assertIn("session.displayDurationMinutes", engine)
        self.assertIn("no se utiliza para calcular esta nota", engine)

    def test_only_scored_block_may_adjust_its_wod_score(self):
        engine = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        self.assertIn("session.exercises.filter { $0.blockId == scoredBlockID }", engine)
        self.assertIn("equivalenceAdjustment(from: scoredMovements)", engine)
        self.assertIn("nonEmptySimilarRefs(scoredMovements)", engine)
        self.assertIn("let historyNote = isScaled ? nil", engine)

    def test_recalculation_and_honest_ui_copy(self):
        ui = read("Apps/Repera/Sources/SessionReviewViews.swift")
        self.assertIn("review.scoreBasis == .catalogBands", ui)
        self.assertIn("Valoración orientativa según datos registrados", ui)
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("sessionReviewFormulaVersion = 9", store)
        self.assertIn("refreshSessionReviewsIfNeeded()", store)
        swift = read("Packages/ReperaDomain/Tests/ReperaDomainTests/SessionReviewEngineTests.swift")
        self.assertIn("mixedEMOMsAndAMRAPAreNotGradedFromOnlyTheAMRAP", swift)
        self.assertIn("pushPressCannotBeComparedWithBenchPress", swift)


if __name__ == "__main__":
    unittest.main()
