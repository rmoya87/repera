"""Guardar/descartar temporizador conserva fecha real y no inventa datos de Salud.

Son contratos del código; la UI y HealthKit deben validarse en dispositivo.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"

def read(p): return p.read_text(encoding="utf-8")

TIMER = read(IOS / "StandaloneTimerView.swift")
STORE = read(IOS / "ReperaStore.swift")
HOME = read(IOS / "HomeView.swift")
HISTORY = read(IOS / "HistoryView.swift")
MODEL = read(DOMAIN / "Models.swift")
CHIPS = read(IOS / "RegisterSessionChrome.swift")

class TimerHistoryPersistenceContractTests(unittest.TestCase):
    def test_save_creates_finished_workout_with_real_timestamps(self):
        save = TIMER.split("private func saveCompletedTimer()", 1)[1].split(
            "private var clockScreen:", 1
        )[0]
        for snippet in (
            "id: summary.id", "phase: .finished",
            "startedAt: summary.startedAt", "finishedAt: summary.finishedAt",
            "locationPin: summary.locationPin", "timerDetails: details",
            "store.saveWorkout(session)", "dismissCompletedTimer()",
        ):
            self.assertIn(snippet, save)
        self.assertIn("if !store.state.workouts.contains(where: { $0.id == summary.id })", save)
        self.assertNotIn("HealthKitStore", save)

    def test_discard_does_not_write_a_session(self):
        discard = TIMER.split("private func discardCompletedTimer()", 1)[1].split(
            "private func saveCompletedTimer()", 1
        )[0]
        self.assertIn("dismissCompletedTimer()", discard)
        self.assertNotIn("store.saveWorkout", discard)
        dismiss = TIMER.split("private func dismissCompletedTimer()", 1)[1].split(
            "private func discardCompletedTimer()", 1
        )[0]
        self.assertIn("StandaloneTimerCompletionStore.clear()", dismiss)
        self.assertIn("showClock = false", dismiss)

    def test_pending_completion_survives_process_restart_without_double_save(self):
        self.assertIn("let id: UUID", TIMER)
        self.assertIn("let startedAt: Date", TIMER)
        self.assertIn("guard completedSummary == nil else { return }", TIMER)
        self.assertIn("StandaloneTimerCompletionStore.load()", TIMER)
        self.assertIn("StandaloneTimerCompletionStore.save(summary)", TIMER)
        self.assertIn("timerStartedAt = nil", TIMER)
        self.assertIn("timerStartedAt = end", TIMER)
        self.assertIn("let endedAt = phaseEndDate ?? now", TIMER)

    def test_save_closes_create_and_focuses_actual_session_day(self):
        root = read(IOS / "RootTabView.swift")
        start = read(IOS / "StartHubSheet.swift")
        favorites = read(IOS / "FavoritesHubView.swift")
        save = TIMER.split("private func saveCompletedTimer()", 1)[1].split(
            "private var clockScreen:", 1
        )[0]
        self.assertIn("savedDateToOpenOnDismiss = summary.startedAt", save)
        self.assertIn("onSaved?(date)", TIMER)
        self.assertIn(".fullScreenCover(isPresented: $showClock, onDismiss:", TIMER)
        self.assertIn("onSavedTimer: ((Date) -> Void)? = nil", start)
        self.assertIn("StandaloneTimerView(embedsNavigation: false, onSaved: onSavedTimer)", start)
        self.assertIn("onSaved: onSavedTimer", favorites)
        self.assertIn("onSavedTimer: { date in", root)
        callback = root.split("onSavedTimer: { date in", 1)[1].split(
            ".ogSheetChrome(detents:", 1
        )[0]
        self.assertIn("homeFocusDay = date", callback)
        self.assertIn("showStartHub = false", callback)
        self.assertIn("tab = .home", callback)
        self.assertIn(".onChange(of: focusDay)", HOME)
        self.assertIn("rebuildDayBuckets()", HOME)
        self.assertIn("rebuildWeekChrome()", HOME)

    def test_save_does_not_close_when_session_is_missing(self):
        save = TIMER.split("private func saveCompletedTimer()", 1)[1].split(
            "private var clockScreen:", 1
        )[0]
        self.assertIn("guard store.state.workouts.contains(where:", save)
        self.assertIn("completionSaveError =", save)
        self.assertLess(
            save.index("guard store.state.workouts.contains(where:"),
            save.index("savedDateToOpenOnDismiss = summary.startedAt"),
        )

    def test_historic_workouts_preserve_timer_details_with_optional_codable_field(self):
        self.assertIn("public struct TimerCompletionDetails: Codable, Sendable, Equatable", MODEL)
        self.assertIn("public var timerDetails: TimerCompletionDetails?", MODEL)
        self.assertIn("timerDetails: TimerCompletionDetails? = nil", MODEL)
        self.assertIn("try c.decodeIfPresent(TimerCompletionDetails.self, forKey: .timerDetails)", MODEL)
        self.assertIn("try c.encodeIfPresent(timerDetails, forKey: .timerDetails)", MODEL)

    def test_apple_health_sync_and_reviews_ignore_timer_only_sessions(self):
        sync = STORE.split("private func syncWorkoutToHealth", 1)[1].split(
            "func syncMissingWorkoutsToHealth()", 1
        )[0]
        self.assertIn("session.timerDetails == nil", sync)
        pending = STORE.split("func syncMissingWorkoutsToHealth()", 1)[1].split(
            "func removeLastSet()", 1
        )[0]
        self.assertGreaterEqual(pending.count("$0.timerDetails == nil"), 2)
        self.assertIn("if draft.phase == .finished && draft.timerDetails == nil", STORE)
        self.assertIn("guard session.timerDetails == nil else", STORE)

    def test_calendar_and_history_use_original_start_day(self):
        self.assertIn("(w.liveSportID != nil || w.timerDetails != nil)", HOME)
        self.assertIn("(w.startedAt ?? finishedAt)", HOME)
        self.assertIn("session.timerDetails != nil ? \"timer\"", HOME)
        self.assertIn("s.timerDetails != nil", HISTORY)
        self.assertIn("(s.startedAt ?? s.finishedAt ?? .distantPast)", HISTORY)
        self.assertIn('systemName: session.timerDetails == nil', HISTORY)
        self.assertIn('OGRegisterChip(text: timer.modeTitle', CHIPS)
        self.assertIn("DurationText.format(timer.configuredSeconds)", CHIPS)

    def test_timer_detail_shows_configuration_not_fake_metrics(self):
        detail = HISTORY.split("struct WorkoutDetailView: View", 1)[1]
        self.assertIn("if let timer = session.timerDetails", detail)
        self.assertIn("LabeledContent(\"Modalidad\", value: timer.modeTitle)", detail)
        self.assertIn("LabeledContent(\"Rondas\", value: \"\\(timer.rounds)\")", detail)
        self.assertIn("healthExtras = nil", detail)
        self.assertIn('session.timerDetails == nil, sessionMapContent(session)', detail)


if __name__ == "__main__":
    unittest.main()
