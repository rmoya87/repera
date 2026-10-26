"""Regressions: finished workouts do not require check for any metric.

Source contracts complement domain XCTest and real iOS HealthKit validation.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"


def read(base, name):
    return (base / name).read_text(encoding="utf-8")


class FinishedWorkoutMetricsContractTests(unittest.TestCase):
    def test_finished_without_check_uses_shared_recorded_or_accepted_sets(self):
        stats = read(DOMAIN, "StatsEngine.swift")
        method = stats.split("public static func confirmedWorkSets(", 1)[1].split(
            "public static func confirmedVolumeKg(", 1
        )[0]
        self.assertIn("workout.phase == .finished || workout.finishedAt != nil", method)
        self.assertNotIn("guard exercise.isCompleted", method)
        self.assertIn("exercise.loggedSets.filter", method)
        self.assertIn("return effectiveWorkSets(exercise, in: workout)", method)
        self.assertIn("set.rir = nil", method)
        self.assertIn("if !exercise.loggedSets.isEmpty { return [] }", method)

    def test_all_major_progress_pipelines_use_same_work_sets(self):
        stats = read(DOMAIN, "StatsEngine.swift")
        for name in ("personalRecords(", "history(", "exerciseProgressSeries(",
                     "confirmedVolumeKg(", "totalSets("):
            self.assertIn(name, stats)
        self.assertGreaterEqual(stats.count("confirmedWorkSets("), 8)
        self.assertIn("confirmedWorkSets(", read(DOMAIN, "MuscleTaxonomy.swift"))
        self.assertIn("confirmedWorkSets(", read(DOMAIN, "MuscleMapEngine.swift"))
        snapshot = read(APP, "ProgressSnapshot.swift")
        for marker in ("MuscleLoadEngine.load(", "MuscleMapEngine.retainedLoad(",
                       "StatsEngine.personalRecords(", "StatsEngine.dailyActivity(",
                       "StatsEngine.confirmedWorkSets("):
            self.assertIn(marker, snapshot)

    def test_new_finished_workouts_and_imported_history_are_normalized(self):
        store = read(APP, "ReperaStore.swift")
        self.assertIn("private func normalizedFinishedWorkout(", store)
        self.assertIn("saved.exercises[i].isCompleted = true", store)
        self.assertIn("state.workouts.append(normalizedFinishedWorkout(session))", store)
        self.assertIn("let saved = normalizedFinishedWorkout(session)", store)
        self.assertIn("guard session.phase == .finished || session.finishedAt != nil", store)
        self.assertIn("func saveWorkout(_ session: WorkoutSession)", store)
        self.assertIn("func endActiveSession(save: Bool = true)", store)
        self.assertIn("func applyWatchSession(_ session: WorkoutSession)", store)

    def test_start_now_sport_generates_weighted_muscle_stimulus_not_fake_sets(self):
        mapper = read(APP, "HealthMuscleMapper.swift")
        snap = read(APP, "ProgressSnapshot.swift")
        live = read(APP, "LiveActivityView.swift")
        self.assertIn("nativeSportStimuli(from workouts:", mapper)
        self.assertIn("workout.activeDurationSeconds", mapper)
        self.assertIn("sport.healthType", mapper)
        self.assertIn("uniqueExternalActivities(", mapper)
        self.assertIn("linkedHealthIDs.contains(activity.id)", mapper)
        self.assertIn("HealthMuscleMapper.nativeSportStimuli(from: input.workouts)", snap)
        self.assertIn("HealthMuscleMapper.uniqueExternalActivities(", snap)
        self.assertIn("liveSportID: sport.rawValue", live)
        self.assertIn("store.saveWorkout(session)", live)

    def test_score_only_wod_does_not_require_check_or_invent_rir(self):
        wod = read(DOMAIN, "MuscleMapEngine.swift")
        tax = read(DOMAIN, "MuscleTaxonomy.swift")
        self.assertNotIn("entry.isCompleted,", wod)
        self.assertIn("workout.wodResults.contains", wod)
        self.assertIn("in workout: WorkoutSession", wod)
        self.assertIn("for: entry, in: workout, hardOnly: hardOnly", tax)


if __name__ == "__main__":
    unittest.main()
