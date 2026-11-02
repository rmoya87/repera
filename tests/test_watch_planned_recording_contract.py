"""Flujo del entreno programado: vivo o grabación y edición en el iPhone."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WATCH = ROOT / "Apps/ReperaWatch/Sources"
IOS = ROOT / "Apps/Repera/Sources"


class WatchPlannedRecordingContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.view = (WATCH / "WatchSessionView.swift").read_text(encoding="utf-8")
        cls.hub = (WATCH / "WatchSessionHub.swift").read_text(encoding="utf-8")
        cls.store = (IOS / "ReperaStore.swift").read_text(encoding="utf-8")
        cls.root = (IOS / "RootTabView.swift").read_text(encoding="utf-8")
        cls.home = (IOS / "HomeView.swift").read_text(encoding="utf-8")

    def test_ready_plan_has_two_start_modes_no_duplicate_summary(self):
        ready = self.view.split("private func readyView(", 1)[1].split(
            "private func runningView(", 1
        )[0]
        self.assertIn('Text("Iniciar")', ready)
        self.assertIn("showStartMethodPicker = true", ready)
        self.assertNotIn('Button("Resumen")', ready)
        self.assertNotIn('"Iniciar bloque"', ready)
        self.assertIn('Button("Comenzar en vivo") { hub.play() }', self.view)
        self.assertIn('Button("Grabar entreno")', self.view)
        self.assertIn("hub.recordScheduledWorkout()", self.view)
        self.assertIn('Button("Descartar", role: .destructive)', ready)

    def test_recording_keeps_plan_but_no_performed_sets(self):
        entry = self.hub.split("func recordScheduledWorkout()", 1)[1].split(
            "private func startWatchOwnedLive(", 1
        )[0]
        self.assertIn("discardActiveSession()", entry)
        self.assertIn("recordedPlan = plan", entry)
        self.assertIn("startWatchOwnedLive(sport: sport)", entry)
        finish = self.hub.split("func finishWatchLive()", 1)[1].split(
            "func saveStandaloneTimer(", 1
        )[0]
        for field in ["routineId: planned?.routineId",
                      "routineBlocks: planned?.routineBlocks",
                      "copy.loggedSets = []", "copy.completedReps = 0",
                      "copy.isCompleted = false", "liveSportID: sport.rawValue",
                      "self.connectivity.sendFinished(session)"]:
            self.assertIn(field, finish)
        self.assertIn("recordedPlan: recordedPlan", self.hub)
        self.assertIn("recordedPlan = snapshot.recordedPlan", self.hub)
        self.assertIn("discardedPlanExecutionID = plan.id", self.hub)
        self.assertIn("if session?.id == self.discardedPlanExecutionID { return }", self.hub)

    def test_edit_opens_once_after_successful_phone_persistence(self):
        completed = self.store.split(
            "func applyWatchSession(_ session: WorkoutSession)", 1
        )[1].split("func reconcileWatchHealthMetrics()", 1)[0]
        self.assertIn("let receivedNewRecordedPlan = !state.workouts.contains", completed)
        self.assertIn("await LocalStore.shared.persistAndFlush(snapshot)", completed)
        self.assertIn("guard LocalStore.shared.lastPersistenceError == nil", completed)
        self.assertIn("if receivedNewRecordedPlan {", completed)
        self.assertIn("self.pendingRecordedPlanEditID = session.id", completed)
        self.assertIn("store.acknowledgeRecordedPlanEdit(id)", self.root)
        self.assertIn("focusEditSessionID: recordedPlanEditID", self.root)
        self.assertIn("editOwnCompletedWorkout(session)", self.home)
        self.assertIn("CompletedWorkoutEditing.applying(", self.home)
        self.assertIn("onApplyCompleted(edited, detailsToSave, recordNewSetsAsPerformed)",
                      (IOS / "PlanView.swift").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
