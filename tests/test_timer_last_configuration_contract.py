"""El temporizador autónomo recupera la última configuración.

Contratos de origen; las pruebas de UI se completan en dispositivo iOS.
"""
from pathlib import Path
import unittest

SRC = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"
TIMER = (SRC / "StandaloneTimerView.swift").read_text(encoding="utf-8")
HUB = (SRC / "StartHubSheet.swift").read_text(encoding="utf-8")


class TimerLastConfigurationContract(unittest.TestCase):
    def test_last_configuration_is_stored_and_loaded_across_launches(self):
        store = TIMER.split("private enum StandaloneTimerConfigurationStore {", 1)[1].split(
            "private enum StandaloneTimerCompletionStore {", 1
        )[0]
        self.assertIn('private static let key = "repera.timer.lastConfiguration.v1"', store)
        self.assertIn("UserDefaults.standard.data(forKey: key)", store)
        self.assertIn("JSONDecoder().decode(StandaloneTimerConfig.self, from: data)", store)
        self.assertIn("JSONEncoder().encode(configuration)", store)
        self.assertIn("UserDefaults.standard.set(data, forKey: key)", store)

    def test_new_timer_loads_last_used_but_preserves_explicit_favorite(self):
        init = TIMER.split("struct StandaloneTimerView: View {", 1)[1].split(
            "var body: some View {", 1
        )[0]
        self.assertIn("config: StandaloneTimerConfig? = nil", init)
        self.assertIn("usesLastConfiguration = config == nil", init)
        self.assertIn(
            "config ?? StandaloneTimerConfigurationStore.load() ?? StandaloneTimerConfig()",
            init
        )
        self.assertIn("editingFavoriteId: UUID? = nil", init)
        self.assertIn("StandaloneTimerView(embedsNavigation: false, onSaved: onSavedTimer)", HUB)

    def test_setting_changes_and_opening_clock_persist_the_configuration(self):
        self.assertIn(".onChange(of: config) { _, updated in", TIMER)
        self.assertIn("StandaloneTimerConfigurationStore.save(updated)", TIMER)
        start = TIMER.split("private func prepareAndShowClock() {", 1)[1].split(
            "private func toggleRun()", 1
        )[0]
        self.assertIn("StandaloneTimerConfigurationStore.save(config)", start)

    def test_discard_uses_same_bottom_sheet_as_live_workout(self):
        summary = TIMER.split("private var timerSummaryScreen: some View {", 1)[1].split(
            "private func recordTimerCompletion(", 1
        )[0]
        self.assertIn("VStack(spacing: 8)", summary)
        self.assertIn(".sheet(isPresented: $showDiscardCompletedTimer)", summary)
        self.assertIn("OGConfirmSheet(", summary)
        self.assertIn('confirmTitle: "Descartar sin guardar"', summary)
        self.assertIn("discardCompletedTimer()", summary)
        self.assertNotIn(".confirmationDialog(", summary)
        self.assertNotIn('Image(systemName: "checkmark")', summary)


if __name__ == "__main__":
    unittest.main()
