"""Contract for spoken GPX turns regardless of lock-screen / active UI."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS = (ROOT / "Apps/Repera/Sources/LiveActivityView.swift").read_text()
ANDROID = (ROOT / "android/domain/src/main/java/dev/repera/domain/LiveRouteGuidance.kt").read_text()
RUNTIME = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveActivityRuntime.kt").read_text()


class GPXTurnVoiceContractTests(unittest.TestCase):
    def test_ios_voice_is_triggered_by_gps_not_screen_redraw(self):
        receive = IOS.split("private func receive(_ update: WorkoutGPSUpdate)", 1)[1].split(
            "/// GPS vertical orientativo", 1
        )[0]
        guidance = IOS.split("private func updateUpcomingTurn(position: CLLocation)", 1)[1].split(
            "private func notifyDuringBackground", 1
        )[0]
        self.assertIn("updateUpcomingTurn(position: fix.location)", receive)
        self.assertIn("let didSpeak = speakNavigation(spokenTurn)", guidance)
        self.assertNotIn("UIApplication.shared.applicationState", guidance)
        self.assertIn("if phase == .recording && (shouldAnnounceNear || shouldAnnounceApproach)", guidance)
        self.assertIn("announcedApproachTurnIndices.insert(next.routeIndex)", guidance)
        self.assertIn("announcedTurnIndices.insert(next.routeIndex)", guidance)

    def test_two_stages_match_on_iphone_android(self):
        for source in (IOS, ANDROID):
            self.assertIn("250.0", source)
            self.assertIn("450.0", source)
            self.assertIn("70.0", source)
            self.assertIn("120.0", source)
        self.assertIn("remaining>nearDistance", ANDROID)
        self.assertIn("announcedNear.add(next.routeIndex)", ANDROID)
        self.assertIn("announcedApproach.add(next.routeIndex)", ANDROID)

    def test_android_voice_belongs_to_runtime_not_compose(self):
        self.assertIn("guidance?.update(update.point)", RUNTIME)
        self.assertIn("voice.speak(it, queue = true)", RUNTIME)
        self.assertIn("if (spokenGuidanceEnabled)", RUNTIME)


if __name__ == "__main__":
    unittest.main()
