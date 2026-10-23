"""Mixed EMOM + AMRAP must not receive points from logging or weak history."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
def read(p): return (ROOT / p).read_text(encoding="utf-8")

class MixedSessionReviewContractTests(unittest.TestCase):
    def test_no_bench_press_equivalence(self):
        eq = read("Packages/ReperaDomain/Sources/ReperaDomain/ExerciseEquivalence.swift")
        pressing = eq.split("if cf == .press {", 1)[1].split("if cf == .pull", 1)[0]
        self.assertIn("return 0", pressing)
        self.assertNotIn("return 0.92", pressing)

    def test_only_verified_personal_history_is_used(self):
        engine = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        trusted = read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("VerifiedSessionReviewEngine.review(session: session, history: history", engine)
        self.assertIn("minimumPriorSessions = 2", trusted)
        self.assertIn("minimumEvidenceCoverage = 0.60", trusted)
        self.assertIn("days.count >= minimumPriorSessions", trusted)
        self.assertIn("refs.count >= minimumPriorSessions", trusted)
        self.assertIn("guard coverage >= minimumEvidenceCoverage else { return nil }", trusted)
        self.assertNotIn("registrationScore", trusted)
        self.assertNotIn("SessionCardioEffort.apply", engine.split("public static func review(", 1)[1].split("// MARK: - WOD score", 1)[0])

    def test_old_scores_are_recalculated_and_ui_is_honest(self):
        ui = read("Apps/Repera/Sources/SessionReviewViews.swift")
        home = read("Apps/Repera/Sources/HomeView.swift")
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("review.scoreBasis == .personalHistory", ui)
        self.assertIn("review.indicators.count == ReviewDimension.allCases.count", ui)
        self.assertIn("if let score {", home)
        self.assertIn("review.scoreBasis == .personalHistory", home)
        self.assertIn("sessionReviewFormulaVersion = 11", store)
        self.assertIn("refreshSessionReviewsIfNeeded()", store)

if __name__ == "__main__":
    unittest.main()
