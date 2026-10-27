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

    def test_transition_announcements_have_selected_sport_and_voice_gate(self):
        state = (ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/LiveSessionVoiceAnnouncement.swift").read_text(encoding="utf-8")
        self.assertIn("Iniciando \\(spokenSport.lowercased", state)
        self.assertIn("Entrenamiento pausado.", state)
        self.assertIn("Entrenamiento reanudado.", state)
        self.assertIn("Entrenamiento finalizado.", state)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", LIVE)
        self.assertIn("LiveSessionVoiceAnnouncement.started(sportName: selectedSport.title)", LIVE)
        self.assertIn("speakNavigation(LiveSessionVoiceAnnouncement.paused)", LIVE)
        self.assertIn("speakNavigation(LiveSessionVoiceAnnouncement.resumed)", LIVE)
        self.assertIn("speakNavigation(LiveSessionVoiceAnnouncement.finished)", LIVE)

    def test_start_and_finish_announcements_are_not_lifecycle_duplicates(self):
        # Solo se habla al pulsar los botones, no al recuperar el GPS,
        # volver a primer plano ni redibujar SwiftUI.
        recover = LIVE.split("func resumeInterruptedRecordingIfNeeded() {", 1)[1].split(
            "func toggleSpokenGuidance()", 1
        )[0]
        self.assertNotIn("speakNavigation(", recover)
        refresh = LIVE.split("func refreshWhenActive() {", 1)[1].split(
            "func pause() {", 1
        )[0]
        self.assertNotIn("speakNavigation(", refresh)
        self.assertIn("if !(saved && phase == .review && spokenGuidanceEnabled)", LIVE)
        self.assertIn("recorder.phase != .review", LIVE)
        self.assertIn("metricsTrailingActions", LIVE)
        self.assertNotIn('else if recorder.sport.usesGPS {\n                        metricsCircleButton("map", label: "Ver mapa")', LIVE)
        self.assertIn("Desactivar avisos por voz", LIVE)

    def test_audio_visible_before_start_and_preference_persists(self):
        self.assertIn("private var showGuidanceToggle: Bool", LIVE)
        self.assertIn("recorder.phase != .review", LIVE)
        # Hay un altavoz en mapa y otro en métricas; ambos usan el mismo recorder.
        self.assertIn("if showGuidanceToggle {", LIVE)
        self.assertGreaterEqual(LIVE.count("recorder.toggleSpokenGuidance()"), 2)
        self.assertIn('private let spokenGuidanceKey = "repera.live.spokenGuidance.enabled"', LIVE)
        self.assertIn("private(set) var spokenGuidanceEnabled = true", LIVE)
        self.assertIn("UserDefaults.standard.bool(forKey: spokenGuidanceKey)", LIVE)
        self.assertIn("UserDefaults.standard.set(spokenGuidanceEnabled, forKey: spokenGuidanceKey)", LIVE)
        self.assertIn("guard spokenGuidanceEnabled, !message.isEmpty else", LIVE)

    def test_map_starts_flat_and_persists_previous_selection(self):
        self.assertIn(
            '@AppStorage("repera.live.map.navigation3D.enabled") private var navigationMapEnabled = false',
            LIVE
        )
        self.assertNotIn("@State private var navigationMapEnabled = true", LIVE)
        self.assertIn("navigationMapEnabled.toggle()", LIVE)
        self.assertIn(".mapStyle(.standard(elevation: navigationMapEnabled ? .realistic : .flat))", LIVE)
        self.assertIn("if !navigationMapEnabled {", LIVE)
        self.assertIn("pitch: 0", LIVE)
        self.assertIn("pitch: 67", LIVE)
        self.assertIn("center3DMap(on: user)", LIVE)

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
