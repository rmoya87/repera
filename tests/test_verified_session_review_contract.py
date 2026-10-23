"""Ensure no part of the app surfaces a grade without comparable personal history."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path): return (ROOT / path).read_text(encoding="utf-8")

class VerifiedSessionScoreContractTests(unittest.TestCase):
    def test_legacy_block_scoring_unwraps_optional_exercise_uuid(self):
        source = read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        self.assertIn("guard let exerciseID = movement.exerciseId else { return false }", source)
        self.assertIn("return scoredIDs.contains(exerciseID)", source)
        self.assertNotIn("scoredIDs.contains($0.exerciseId)", source)

    def test_only_verified_engine_publishes_scores(self):
        engine=read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        verified=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("VerifiedSessionReviewEngine.review(session: session, history: history, now: now)",engine)
        self.assertIn("minimumPriorSessions = 2",verified)
        self.assertIn("minimumEvidenceCoverage = 0.60",verified)
        self.assertIn("historyHorizonDays = 180",verified)
        self.assertIn("days.count >= minimumPriorSessions",verified)
        self.assertIn("refs.count >= minimumPriorSessions",verified)
        self.assertIn("guard coverage >= minimumEvidenceCoverage else { return nil }",verified)
        self.assertIn("Calendar.current.startOfDay",verified)
        self.assertIn("matchesCatalogIdentity",verified)
        self.assertIn("samePrescription(currentBlock, block)",verified)
        self.assertIn("sameScaling(scaled, previousScaled)",verified)

    def test_compliance_is_not_added_to_global_performance_score(self):
        verified=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("let eligible = movementEvidence + wodEvidence",verified)
        self.assertIn("let weighted = eligible.reduce",verified)
        self.assertIn("dimension: .adherence",verified)
        self.assertIn("score: nil",verified)
        self.assertIn("No mide intensidad ni técnica",verified)
        self.assertNotIn("registrationScore",verified)

    def test_views_hide_legacy_or_absent_scores(self):
        review=read("Apps/Repera/Sources/SessionReviewViews.swift")
        home=read("Apps/Repera/Sources/HomeView.swift")
        model=read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReview.swift")
        self.assertIn("review.scoreBasis == .personalHistory",review)
        self.assertIn("review.indicators.count == ReviewDimension.allCases.count",review)
        self.assertIn("if isVerified {",review)
        self.assertIn("Text(\"NOTA GLOBAL\")",review)
        for label in ("Evolución personal","Cumplimiento","Rendimiento WOD"):
            self.assertIn(label,model)
        self.assertIn("if let score {",home)
        self.assertIn("review.scoreBasis == .personalHistory",home)
        self.assertIn("private static let sessionReviewFormulaVersion = 11",
                      read("Apps/Repera/Sources/ReperaStore.swift"))

    def test_synthetic_cardio_points_not_in_new_engine(self):
        e=read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReviewEngine.swift")
        entry=e.split("public static func review(",1)[1].split("// MARK: - WOD score",1)[0]
        self.assertNotIn("SessionCardioEffort.apply",entry)
        self.assertNotIn("scoreFromMovementPace",entry)

if __name__=="__main__": unittest.main()
