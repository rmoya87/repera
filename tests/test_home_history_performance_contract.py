"""Contratos de rendimiento: Inicio, carrusel y navegación de históricos.

No sustituye medir en Instruments ni compilar en un iPhone real.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"


def source(name):
    return (IOS / name).read_text(encoding="utf-8")


class HomeHistoryPerformanceContractTests(unittest.TestCase):
    def test_week_taps_only_rebuild_seven_cells_not_entire_year(self):
        home = source("HomeView.swift")
        on_week = home.split(".onChange(of: weekOffset)", 1)[1].split(
            ".onChange(of: health.isAuthorized)", 1
        )[0]
        self.assertIn("rebuildSelectedWeekChrome()", on_week)
        self.assertNotIn("rebuildWeekChrome()", on_week)
        selected = home.split("private func rebuildSelectedWeekChrome()", 1)[1].split(
            "private func rebuildWeekChrome()", 1
        )[0]
        self.assertIn("cachedWeekDays = makeWeekDays(", selected)
        self.assertNotIn("cachedCalendarDays =", selected)
        self.assertIn("cachedCalendarLookup", selected)

    def test_home_does_not_refetch_seven_days_of_steps_on_each_tap(self):
        home = source("HomeView.swift")
        day_task = home.split('.task(id: "\\(dayKey(selectedDay))', 1)[1].split(
            ".task(id: store.isHydrated)", 1
        )[0]
        self.assertIn("await health.steps(for: requestedDay)", day_task)
        self.assertNotIn("dailySteps(endingAt:", day_task)
        self.assertIn("stepsByDayKey[requestedKey]", day_task)
        self.assertIn("Task.isCancelled", day_task)

    def test_back_navigation_does_not_rebuild_without_new_epochs(self):
        home = source("HomeView.swift")
        self.assertIn("guard lastProcessedWorkoutsEpoch != store.workoutsEpoch", home)
        self.assertIn("guard lastProcessedHealthRevision != health.healthDataRevision", home)
        appearance = home.split('.onAppear {\n                LaunchTiming.mark("HomeView.onAppear")', 1)[1].split(
            ".onChange(of: store.state.settings.profileAvatarJPEG)", 1
        )[0]
        self.assertIn("if !didBuildDayBuckets", appearance)
        self.assertIn("if !didBuildCalendarChrome", appearance)
        self.assertIn("if !didBuildStreakChrome", appearance)

    def test_historical_details_do_not_repair_entire_workout_history(self):
        history = source("HistoryView.swift")
        detail = history.split("struct WorkoutDetailView: View", 1)[1].split(
            "struct HealthActivityDetailView", 1
        )[0]
        loading = detail.split(".task(id: sessionId)", 1)[1].split(
            ".navigationDestination(isPresented: $showFullScreenRoute)", 1
        )[0]
        self.assertNotIn("repairHistoricalWODExercisesIfNeeded()", loading)
        self.assertIn("await Task.yield()", loading)
        self.assertIn("if session.sessionReview == nil", loading)

    def test_unchanged_review_never_triggers_backup_or_sync(self):
        store = source("ReperaStore.swift")
        ensure = store.split("func ensureSessionReview(for sessionId:", 1)[1].split(
            "func refreshSessionReviewsIfNeeded()", 1
        )[0]
        self.assertIn("if let existing = state.workouts[idx].sessionReview", ensure)
        self.assertIn("session.sessionReview != state.workouts[idx].sessionReview", ensure)
        cardio = store.split("func refreshSessionReviewWithCardio(", 1)[1].split(
            "private static let sessionReviewFormulaVersion", 1
        )[0]
        self.assertIn("guard state.workouts[idx].sessionReview != session.sessionReview", cardio)

    def test_edit_route_prepares_once_and_retains_model_while_popping(self):
        home = source("HomeView.swift")
        history = source("HistoryView.swift")
        self.assertIn("editingOwnSessionRoutine = CompletedWorkoutEditing.routine(", home)
        self.assertIn("routine: editingOwnSessionRoutine", home)
        self.assertIn("preparedCompletedRoutine = CompletedWorkoutEditing.routine(", history)
        self.assertIn("routine: preparedCompletedRoutine", history)
        self.assertNotIn("preparedCompletedRoutine = nil", history)


if __name__ == "__main__":
    unittest.main()
