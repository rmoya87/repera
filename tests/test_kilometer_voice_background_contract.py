"""Contrato de los avisos por kilómetro de Comenzar en iOS 27.

No sustituye una prueba de GPS, Bluetooth y audio en un iPhone físico.
"""
import pathlib
import plistlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LIVE = (ROOT / "Apps/Repera/Sources/LiveActivityView.swift").read_text(encoding="utf-8")
DOMAIN = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/KilometerVoiceAnnouncement.swift").read_text(encoding="utf-8")


class KilometerVoiceBackgroundContractTests(unittest.TestCase):
    def test_crossing_notifies_immediately_using_gps_crossing_seconds(self):
        self.assertIn("reportKilometer(split, elapsedActiveSeconds: crossingSeconds)", LIVE)
        self.assertIn("KilometerVoiceAnnouncement.message(", LIVE)
        self.assertIn("splitSeconds: split.seconds", LIVE)
        self.assertIn("elapsedSeconds: elapsedActiveSeconds", LIVE)
        self.assertIn("let didSpeak = speakNavigation(message)", LIVE)

    def test_every_gps_sport_including_walking_gets_speed_in_kmh(self):
        self.assertIn("case .walking: \"Caminata\"", LIVE)
        self.assertIn("case .walking, .hiking", LIVE)
        self.assertIn("Velocidad media del tramo:", DOMAIN)
        self.assertIn("Velocidad media desde el inicio:", DOMAIN)
        self.assertNotIn("sport.displaysSpeed\n                ?", LIVE)

    def test_pending_speech_is_not_deactivated_between_utterances(self):
        self.assertIn("pendingGuidanceUtterances: Set<ObjectIdentifier>", LIVE)
        self.assertIn("pendingGuidanceUtterances.insert(ObjectIdentifier(phrase))", LIVE)
        self.assertIn("guard pendingGuidanceUtterances.isEmpty, guidanceAudioActive", LIVE)
        self.assertIn("finishGuidanceUtterance(id)", LIVE)
        self.assertIn("private func stopGuidanceAudio()", LIVE)

    def test_native_background_modes_are_present_in_source_and_xcodegen(self):
        info = plistlib.loads((ROOT / "Apps/Repera/Resources/Info.plist").read_bytes())
        self.assertTrue({"location", "audio"}.issubset(set(info["UIBackgroundModes"])))
        project = (ROOT / "project.yml").read_text(encoding="utf-8")
        self.assertIn("UIBackgroundModes:", project)
        self.assertIn("          - location\n          - audio", project)
        self.assertIn("CLBackgroundActivitySession()", (
            ROOT / "Apps/Repera/Sources/Location/WorkoutLocationTracker.swift"
        ).read_text(encoding="utf-8"))

    def test_speech_failure_fallback_is_not_a_duplicate_notification(self):
        self.assertIn("if spokenGuidanceEnabled && !didSpeak", LIVE)
        self.assertIn("fallbackWhenSpeechFailed: true", LIVE)
        self.assertIn("(!spokenGuidanceEnabled || fallbackWhenSpeechFailed)", LIVE)


if __name__ == "__main__":
    unittest.main()
