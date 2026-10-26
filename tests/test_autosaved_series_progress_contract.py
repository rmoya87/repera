"""Contratos de fuente: no hay ✓ por serie y Progreso no pierde series reales.

Los contratos no sustituyen Swift tests, Xcode, iCloud ni la comprobación
visual con los entrenamientos locales del atleta.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "Apps/Repera/Sources"
DOMAIN = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain"


def source(directory, filename):
    return (directory / filename).read_text(encoding="utf-8")


class AutosavedSeriesProgressTests(unittest.TestCase):
    def test_play_series_has_no_manual_confirm_and_records_as_user_types(self):
        play = source(APP, "WorkoutView.swift")
        board = play.split("private func setsBoard(", 1)[1].split(
            "private func cacheLiveSets(", 1
        )[0]
        self.assertGreaterEqual(board.count("showsConfirmation: false"), 2)
        self.assertIn("completed: false", board)
        self.assertNotIn("completeLiveSet(", play)
        self.assertNotIn("onConfirm: {\n                    guard store.state.activeSession", board)
        self.assertIn("onConfirm: { }", board)
        self.assertIn("performedSets: recorded", play)
        self.assertIn("existingByID[row.id] ?? LoggedSet(", play)
        self.assertIn("id: row.id", play)
        self.assertIn("result.weightKg = recordedWeight", play)
        self.assertIn("result.reps = row.reps", play)
        self.assertIn("result.rir = style.usesRIR ? row.rir : nil", play)

    def test_store_and_domain_save_real_rows_without_duplicates(self):
        store = source(APP, "ReperaStore.swift")
        controller = source(DOMAIN, "SessionController.swift")
        self.assertIn("performedSets: [LoggedSet]? = nil", store)
        self.assertIn("controller.replaceRecordedSets(exerciseID: id, sets: $0)", store)
        self.assertIn("func replaceRecordedSets(", controller)
        self.assertIn("session.exercises[index].loggedSets != sets", controller)
        self.assertIn("session.exercises[index].loggedSets = sets", controller)

    def test_all_muscle_charts_count_confirmed_results_not_plans(self):
        engine = source(DOMAIN, "StatsEngine.swift")
        weights = source(DOMAIN, "MuscleTaxonomy.swift")
        fatigue = source(DOMAIN, "MuscleMapEngine.swift")
        snapshot = source(APP, "ProgressSnapshot.swift")
        card = source(APP, "MuscleBalanceCard.swift")
        self.assertIn("public static func confirmedWorkSets(", engine)
        self.assertIn("guard workout.phase == .finished || workout.finishedAt != nil else { return [] }", engine)
        self.assertNotIn("guard exercise.isCompleted", engine)
        self.assertIn("set.rir = nil", engine)
        self.assertIn("confirmedVolumeKg(in: workout)", engine)
        self.assertIn("StatsEngine.confirmedWorkSets(entry, in: workout)", weights)
        self.assertIn("StatsEngine.confirmedWorkSets(entry, in: workout)", fatigue)
        self.assertIn("StatsEngine.confirmedWorkSets(entry, in: session)", snapshot)
        self.assertIn("StatsEngine.confirmedWorkSets(entry, in: session)", card)
        self.assertIn("StatsEngine.confirmedWorkSets(entry, in: workout)", snapshot)

    def test_volume_pr_and_recent_exercise_trends_use_actual_work(self):
        session = source(DOMAIN, "Models.swift")
        stats = source(DOMAIN, "StatsEngine.swift")
        snapshot = source(APP, "ProgressSnapshot.swift")
        self.assertIn("StatsEngine.confirmedVolumeKg(in: self)", session)
        self.assertIn("for set in confirmedWorkSets(exercise, in: workout)", stats)
        self.assertIn("let work = confirmedWorkSets(exercise, in: session)", stats)
        self.assertIn("confirmedVolumeKg(in: workout)", stats)
        self.assertIn("let performed = !StatsEngine.confirmedWorkSets(", snapshot)


if __name__ == "__main__":
    unittest.main()
