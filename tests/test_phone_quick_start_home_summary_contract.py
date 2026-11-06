"""Contracts: quick Play on phones and no duplicate score in Home daily activity."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class PhoneQuickStartHomeSummaryContractTests(unittest.TestCase):
    def test_ios_preview_plays_directly_and_keeps_start_failure_handling(self):
        preview = read("Apps/Repera/Sources/SessionPreviewView.swift")
        root = read("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("Button {\n                        startVisibleRoutine()\n                    } label: {", preview)
        self.assertIn("store.startSession(from: routine)", preview)
        self.assertIn("started.routineId == routine.id", preview)
        self.assertIn("startFailureMessage = HealthKitStore.shared.lastError", preview)
        self.assertIn("onContinue()", preview)
        self.assertIn("onStart()", preview)
        self.assertNotIn("showStartChoices", preview)
        self.assertNotIn("onRecord:", preview)
        self.assertNotIn("recordPlannedRoutine(", root)

    def test_ios_home_has_no_repeated_workout_score(self):
        home = read("Apps/Repera/Sources/HomeView.swift")
        activity = home.split("private var activityTodayCard: some View {", 1)[1].split(
            "private func homeActivityMetric(", 1
        )[0]
        for label in ('title: "Pasos"', 'title: "Calorías"', 'title: "Tiempo"'):
            self.assertIn(label, activity)
        self.assertNotIn("Puntuación del entrenamiento", activity)
        self.assertNotIn("if let score {", activity)
        self.assertIn("WorkoutRegisterChips.repera(", home)
        chips = read("Apps/Repera/Sources/RegisterSessionChrome.swift")
        self.assertIn("OGRegisterChip(text: review.scoreLabel", chips)

    def test_android_home_and_plan_play_already_match(self):
        home = read("android/mobile/src/main/java/dev/repera/mobile/HomeDayCards.kt")
        activity = home.split("internal fun HomeActivityTodayCard(", 1)[1].split(
            "private fun HomeActivityMetricTile(", 1
        )[0]
        for label in ("home_day_cards_pasos", "home_day_cards_calorias", "home_day_cards_tiempo"):
            self.assertIn(label, activity)
        self.assertNotIn("Puntuación del entrenamiento", activity)
        screen = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        self.assertIn("onStartRoutine(id) {", screen)
        self.assertIn('navController.navigate("entreno-activo")', screen)


if __name__ == "__main__":
    unittest.main()
