"""Regresiones de múltiples sesiones, swipe y sincronización local-first.

Estos contratos verifican código y flujos; no sustituyen Xcode/Watch físico.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps/Repera/Sources"
DOMAIN = ROOT / "Packages/ReperaDomain/Sources/ReperaDomain"


def read(base, name):
    return (base / name).read_text(encoding="utf-8")


class MultiSessionAndSyncTests(unittest.TestCase):
    def test_independent_scheduled_workouts_same_date(self):
        store = read(IOS, "ReperaStore.swift")
        saved = store.split("func saveRoutine(_ routine:", 1)[1].split(
            "func deleteRoutine(", 1
        )[0]
        self.assertIn("state.routines.append(draft)", saved)
        self.assertIn("draft.scheduledDate = Calendar.current.startOfDay(for: scheduled)", saved)
        self.assertNotIn("removeIds", saved)
        self.assertNotIn("state.routines.removeAll", saved)
        self.assertIn("func scheduledRoutines(on date: Date) -> [Routine]", store)
        self.assertIn("func removeScheduledRoutine(id: UUID)", store)
        self.assertIn("guard let source = state.routines.first(where: { $0.id == routineId }) else", store)

        board = store.split("func saveBoardToDay(", 1)[1].split(
            "private static func dateForISOWeekday(", 1
        )[0]
        self.assertIn("saveRoutine(imported)", board)
        self.assertNotIn("existing.blocks.append", board)
        copied = store.split("func copyPreviousWeekSchedule(", 1)[1].split(
            "func assignRoutine(", 1
        )[0]
        self.assertIn("let originallyOccupied =", copied)
        self.assertNotIn("scheduledRoutine(on: copyDate) == nil", copied)

    def test_diary_and_home_display_each_independent_session(self):
        diary = read(IOS, "PlanView.swift")
        home = read(IOS, "HomeView.swift")
        self.assertIn("let routines = store.scheduledRoutines(on: date)", diary)
        self.assertIn("ForEach(routines) { routine in", diary)
        self.assertIn("store.removeScheduledRoutine(id: routine.id)", diary)
        self.assertIn("assigningDay = date", diary)
        self.assertIn("let planned = plannedRoutinesForSelectedDay", home)
        self.assertIn("ForEach(planned) { routine in", home)
        self.assertIn("let completedIDs = Set(workoutsOnSelectedDay.compactMap", home)
        self.assertIn("!completedIDs.contains($0.id) && $0.id != activeID", home)
        self.assertIn("ForEach(workouts) { session in", home)
        self.assertIn("store.removeScheduledRoutine(id: routine.id)", home)

    def test_play_swipes_each_series_and_persists_deletion(self):
        play = read(IOS, "WorkoutView.swift")
        board = play.split("private func setsBoard(", 1)[1].split(
            "private func liveSetRow(", 1
        )[0]
        self.assertIn("WorkoutSetSwipeDeleteRow(", board)
        self.assertNotIn('Image(systemName: "minus.circle")', board)
        self.assertIn("DragGesture(minimumDistance: 18)", play)
        self.assertIn("liveSets.remove(at: index)", play)
        self.assertIn("performedSets: recorded", play)
        self.assertNotIn("guard liveSets.count > 1", play)
        self.assertIn("let total = max(planned.count, max(logged.count, retained.count))", play)
        controller = read(DOMAIN, "SessionController.swift")
        models = read(DOMAIN, "Models.swift")
        update = controller.split("public mutating func updateExerciseDraft(", 1)[1].split(
            "public static func from(", 1
        )[0]
        self.assertNotIn("guard !plannedSets.isEmpty", update)
        self.assertIn("session.exercises[index].plannedSets = plannedSets", update)
        self.assertIn("if let explicit = movement.explicitPlannedSets {", models)
        self.assertNotIn("if let explicit = movement.explicitPlannedSets, !explicit.isEmpty", models)

    def test_comenzar_sports_use_healthkit_and_muscle_stimuli(self):
        sports = read(IOS, "LiveActivityView.swift")
        muscles = read(IOS, "HealthMuscleMapper.swift")
        progress = read(IOS, "ProgressSnapshot.swift")
        for token in (".boxing", ".kickboxing", ".martialArts", ".wrestling",
                      ".badminton", ".pickleball", ".squash", ".coreTraining",
                      ".elliptical", ".stairClimbing", ".americanFootball",
                      ".baseball", ".softball", ".hockey", ".lacrosse", ".rugby"):
            self.assertIn(token, sports)
        self.assertIn("nativeSportStimuli(from workouts:", muscles)
        self.assertIn("muscleLoad(for: sport.healthType", muscles)
        self.assertIn("HealthMuscleMapper.uniqueExternalActivities(", progress)
        self.assertIn("HealthMuscleMapper.nativeSportStimuli(", progress)
        stats = read(DOMAIN, "StatsEngine.swift")
        for sport in ('"crossfit"', '"boxing"', '"kickboxing"', '"badminton"',
                      '"pickleball"', '"squash"', '"elliptical"', '"stairClimbing"',
                      '"americanFootball"', '"hockey"', '"rugby"'):
            self.assertIn(sport, stats)
        self.assertIn(".coreTraining, .yoga, .pilates, .flexibility, .cooldown, .other:", muscles)

    def test_finished_saves_trigger_supabase_after_local_flush(self):
        store = read(IOS, "ReperaStore.swift")
        sync = read(IOS, "BusinessWorkoutSyncStore.swift")
        settings = read(IOS, "SettingsView.swift")
        persist = store.split("private func persistWorkouts(", 1)[1].split(
            "private func scheduleHealthActivitiesResync", 1
        )[0]
        self.assertIn("persist(immediate: immediate, touchWorkouts: true)", persist)
        self.assertLess(persist.index("await LocalStore.shared.persistAndFlush(snapshot)"),
                        persist.index("BusinessWorkoutSyncStore.shared.sync(store: self)"))
        self.assertIn('client.from("athlete_workout_mirror")', sync)
        self.assertIn("for batch in pending.chunked", sync)
        self.assertIn("lastError = ", sync)
        self.assertIn("Sincronizar ahora", settings)
        self.assertIn("workoutSync.lastSyncAt", settings)
        self.assertIn("workoutSync.lastError", settings)

    def test_multiple_recording_paths_reach_completed_history(self):
        store = read(IOS, "ReperaStore.swift")
        live = read(IOS, "LiveActivityView.swift")
        quick = read(IOS, "QuickLogSheet.swift")
        scanner = read(IOS, "DayPlusSheet.swift")
        workout = read(IOS, "WorkoutView.swift")
        self.assertIn("func endActiveSession(save: Bool = true)", store)
        self.assertIn("upsertWorkout(session)", store)
        self.assertIn("func logQuickSets(", store)
        self.assertIn("upsertWorkout(saved)", store)
        self.assertIn("store.logQuickSets(", quick)
        self.assertIn("store.saveWorkout(session)", live)
        self.assertIn("store.startSessionFromBoard(", scanner)
        self.assertIn("store.endActiveSession(save: true)", workout)
        stats = read(DOMAIN, "StatsEngine.swift")
        self.assertIn("guard workout.phase == .finished || workout.finishedAt != nil", stats)


if __name__ == "__main__":
    unittest.main()
