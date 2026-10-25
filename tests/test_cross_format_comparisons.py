"""Regression contracts: verified levels 1/2/3, without invented scores."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding="utf-8")

class CrossFormatRatingContracts(unittest.TestCase):
    def test_identical_wod_has_precedence_before_stimulus(self):
        s=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("wodEvidence(result: result, session: session, prior: prior)", s)
        self.assertIn("?? calibratedStimulusEvidence(result: result, session: session, prior: prior)", s)
        self.assertIn("tier: 1",s)
        self.assertIn("tier = 2",s)
        self.assertIn("tier: 3",s)

    def test_same_exercise_can_compare_across_strength_emom_when_rir_known(self):
        s=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("readings(allowOtherContext: false)",s)
        self.assertIn("readings(allowOtherContext: true)",s)
        self.assertIn("sameExercise(candidate.exercise, entry.exercise)",s)
        self.assertIn("entry.exercise.loggingStyle == .loadAndReps",s)
        self.assertIn("guard let a = currentSet.rir",s)
        self.assertIn("abs(a - b) <= 1.5",s)
        self.assertIn("guard days.count >= minimumPriorSessions",s)
        self.assertIn("tier == 1 ? 5 : 3",s)

    def test_stimulus_needs_three_days_same_movement_and_comparable_load(self):
        s=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("minimumStimulusReferenceDays = 3",s)
        self.assertIn("priorDays.count >= minimumStimulusReferenceDays",s)
        self.assertIn("ExerciseEquivalence.sameName(move.name, old.name)",s)
        self.assertIn("max(currentSeconds, priorSeconds) / min(currentSeconds, priorSeconds) <= 1.5",s)
        self.assertIn("Double(max(a, b)) / Double(min(a, b)) <= 1.25",s)
        self.assertIn("abs(a - b) / max(a, b) <= 0.05",s)
        self.assertIn("!currentScaled.contains(where: { $0.hasWODScaling })",s)
        self.assertIn("case .forTime, .afap, .chipper:",s)
        self.assertIn("case .amrap:",s)
        self.assertIn("performed = rounds * perCycle + partial",s)

    def test_confidence_reflects_comparison_strength_and_ui_exposes_it(self):
        s=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        ui=read("Apps/Repera/Sources/SessionReviewViews.swift")
        model=read("Packages/ReperaDomain/Sources/ReperaDomain/SessionReview.swift")
        self.assertIn("let weakestTier = eligible.map(\\.tier).max() ?? 1",s)
        self.assertIn('confidence = "Baja · estímulo estimado"',s)
        self.assertIn('confidence = "Media · distinto contexto"',s)
        self.assertIn("public var comparisonLevel: Int?",model)
        self.assertIn('Text(tier == 1 ? "Nivel 1 · Referencia idéntica"',ui)
        self.assertIn("if indicator.score != nil, let tier = indicator.comparisonLevel",ui)

    def test_old_scoring_stays_gated_and_new_version_forces_review(self):
        s=read("Packages/ReperaDomain/Sources/ReperaDomain/VerifiedSessionReviewEngine.swift")
        self.assertIn("minimumEvidenceCoverage = 0.60",s)
        self.assertIn("guard coverage >= minimumEvidenceCoverage else { return nil }",s)
        self.assertIn("referenceSessions: movementEvidence.map",s)
        self.assertIn("dimension: .adherence,\n                score: nil",s)
        self.assertIn("sessionReviewFormulaVersion = 11",read("Apps/Repera/Sources/ReperaStore.swift"))
        # HomeView no longer renders the removed dayScore tile: the scoring gate
        # remains protected above by the domain-level evidence requirements.

if __name__ == "__main__": unittest.main()
