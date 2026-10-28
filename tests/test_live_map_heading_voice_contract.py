"""Regression contracts: GPS preview arrow and spoken navigation in background.

These source-level checks are not a substitute for listening on a physical iPhone
with a locked screen, Bluetooth devices and another audio app playing.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps/Repera/Sources"
LIVE = (SRC / "LiveActivityView.swift").read_text(encoding="utf-8")
TRACKER = (SRC / "Location/WorkoutLocationTracker.swift").read_text(encoding="utf-8")
HISTORY = (SRC / "HistoryView.swift").read_text(encoding="utf-8")
ANDROID = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveActivityRuntime.kt").read_text(encoding="utf-8")
TTS = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/LiveSpokenGuidance.kt").read_text(encoding="utf-8")
PROJECT = (ROOT / "project.yml").read_text(encoding="utf-8")


class LiveMapHeadingVoiceContracts(unittest.TestCase):
    def test_preview_uses_existing_location_owner_and_stops_compass_on_background(self):
        self.assertIn("CLLocationManager.headingAvailable()", TRACKER)
        self.assertIn("manager.startUpdatingHeading()", TRACKER)
        self.assertIn("manager.stopUpdatingHeading()", TRACKER)
        self.assertIn("didUpdateHeading heading: CLHeading", TRACKER)
        self.assertIn("private(set) var previewHeadingDegrees: Double?", TRACKER)
        self.assertIn("private var mapHeadingDegrees: Double?", LIVE)
        self.assertIn("recorder.currentCourseDegrees ?? locationTracker.previewHeadingDegrees", LIVE)
        self.assertIn(".onDisappear { stopMapHeadingIfNeeded() }", LIVE)
        self.assertIn("else { stopMapHeadingIfNeeded() }", LIVE)
        self.assertIn('Image(systemName: "location.north.fill")', LIVE)
        self.assertNotIn("if let course = recorder.currentCourseDegrees", LIVE)
        self.assertIn("mapHeadingDegrees == nil ? 0.48 : 1", LIVE)

    def test_history_speed_legend_centers_mean_inline(self):
        legend = HISTORY.split("private var speedLegend: some View {", 1)[1].split("var body: some View {", 1)[0]
        self.assertIn('"Media " + ReperaNumberFormat.decimal($0.medianMps * 3.6) + " km/h"', legend)
        self.assertEqual(legend.count(".frame(width: 196"), 2)
        self.assertNotIn('"Habitual "', legend)
        self.assertIn("minimumScaleFactor(0.8)", legend)

    def test_ios_spoken_guidance_ducks_other_audio_and_can_play_locked(self):
        self.assertIn("speechSynthesizer.usesApplicationAudioSession = true", LIVE)
        self.assertIn(".playback, mode: .spokenAudio", LIVE)
        self.assertIn("options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]", LIVE)
        self.assertIn("guard pendingGuidanceUtterances.isEmpty, guidanceAudioActive", LIVE)
        self.assertIn("try audio.setActive(true)", LIVE)
        self.assertIn("try AVAudioSession.sharedInstance().setActive(", LIVE)
        self.assertIn("speechSynthesizer.speak(phrase)", LIVE)
        self.assertIn("notifyDuringBackground(", LIVE)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", LIVE)
        self.assertIn("if modes.contains(\"location\")", TRACKER)
        self.assertIn("          - location\n          - audio", PROJECT)

    def test_kilometers_and_turns_are_announced_by_recorder_not_swiftui(self):
        self.assertIn("updateUpcomingTurn(position: fix.location)", LIVE)
        self.assertIn("reportKilometer(split, elapsedActiveSeconds: crossingSeconds)", LIVE)
        self.assertIn("KilometerVoiceAnnouncement.message(", LIVE)
        self.assertIn("splitSeconds: split.seconds", LIVE)
        self.assertIn("let didSpeak = speakNavigation(spokenTurn)", LIVE)
        self.assertIn("speakNavigation(message)", LIVE)
        self.assertIn("onUpdate: { [weak self] update in self?.receive(update) }", LIVE)
        self.assertIn("if phase == .recording && (shouldAnnounceNear || shouldAnnounceApproach)", LIVE)

    def test_android_guidance_uses_foreground_service_and_audio_focus(self):
        self.assertIn("guidance?.update(update.point)", ANDROID)
        self.assertIn("voice.speak(it, queue = true)", ANDROID)
        self.assertIn("AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK", TTS)
        self.assertIn("USAGE_ASSISTANCE_NAVIGATION_GUIDANCE", TTS)


if __name__ == "__main__":
    unittest.main()
