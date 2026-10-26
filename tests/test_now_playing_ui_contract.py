"""Static UI contracts for Music in timers and Comenzar.

These checks verify wiring and privacy boundaries; Xcode + real devices must
still validate MediaPlayer permissions, Spotify fallback, and layout.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


def source(name):
    return (SRC / name).read_text(encoding="utf-8")


class NowPlayingUIContract(unittest.TestCase):
    def test_shared_player_uses_only_public_music_apis(self):
        player = source("DigitalClockDisplay.swift")
        self.assertIn("import MediaPlayer", player)
        self.assertIn("import AVFoundation", player)
        self.assertIn("MPMusicPlayerController.systemMusicPlayer", player)
        self.assertIn("MPMediaLibrary.authorizationStatus()", player)
        self.assertIn("MPMediaLibrary.requestAuthorization", player)
        self.assertIn("AVAudioSession.sharedInstance().isOtherAudioPlaying", player)
        self.assertIn("skipToPreviousItem()", player)
        self.assertIn("skipToNextItem()", player)
        self.assertIn("player.pause()", player)
        self.assertIn("player.play()", player)
        self.assertNotIn("MPRemoteCommandCenter", player)
        self.assertNotIn("MediaRemote", player)
        self.assertNotIn("MPNowPlayingInfoCenter", player)

    def test_unavailable_player_hides_all_chrome(self):
        player = source("DigitalClockDisplay.swift")
        self.assertIn("if snapshot.isVisible", player)
        self.assertIn("if showsSeparator", player)
        self.assertIn("if cardStyle", player)
        self.assertIn("Controles en el Centro de Control", player)
        self.assertIn("Audio en reproducción", player)
        self.assertIn("!otherAudio", player)

    def test_now_playing_scope_survives_stale_xcode_project(self):
        # DigitalClockDisplay.swift ya se compilaba antes de añadir la UI de música.
        # En el archivo antiguo solo hay un comentario de compatibilidad.
        screen = source("DigitalClockDisplay.swift")
        legacy = source("ReperaNowPlayingBar.swift")
        self.assertEqual(screen.count("struct ReperaNowPlayingBar: View"), 1)
        self.assertEqual(screen.count("struct ReperaNowPlayingSnapshot"), 1)
        self.assertNotIn("struct ReperaNowPlayingBar: View", legacy)
        self.assertIn("import MediaPlayer", screen)
        self.assertIn("import AVFoundation", screen)

    def test_both_timer_modes_use_same_miniplayer(self):
        screen = source("DigitalClockDisplay.swift")
        self.assertGreaterEqual(screen.count("ReperaNowPlayingBar(darkAppearance: true)"), 2)
        self.assertIn("BlockTimerScreen(", source("WorkoutView.swift"))
        self.assertIn("BlockTimerScreen(", source("StandaloneTimerView.swift"))

    def test_comenzar_idle_and_running_ui_are_integrated(self):
        live = source("LiveActivityView.swift")
        self.assertIn("ReperaNowPlayingBar(\n                        horizontalPadding: 12, showsSeparator: true, bottomPadding: 8", live)
        self.assertIn("ReperaNowPlayingBar(horizontalPadding: 8, showsSeparator: true)", live)
        self.assertIn("cardStyle: true, bottomPadding: 12", live)
        self.assertIn("private var mapMetricStrip: some View", live)
        self.assertIn("private var metricsView: some View", live)

    def test_empty_routines_uses_white_card_on_iphone_and_duo(self):
        plan = source("PlanView.swift")
        phone = plan.split("private var routinesContent", 1)[1].split("} else {", 1)[0]
        duo = plan.split("private var expandedEmptyRoutines", 1)[1].split("private var routinesContent", 1)[0]
        for body in (phone, duo):
            self.assertIn(".background(OG.surface, in: RoundedRectangle(", body)
            self.assertIn('Text("Sin rutinas")', body)
            self.assertIn("newRoutineGreenButton", body)

    def test_recovery_cards_shrink_graph_and_readiness_together(self):
        recovery = source("HealthRecovery.swift")
        self.assertIn("(width - OG.pad * 2) * (2.0 / 3.0)", recovery)
        self.assertIn(".frame(height: readinessChartHeight)", recovery)
        self.assertIn(".frame(minHeight: readinessChartHeight", recovery)
        self.assertIn("usesExpandedLayout ? 76 : 95", recovery)
        self.assertNotIn("readinessRowMinHeight", recovery)

    def test_music_privacy_info_exists_in_both_manifest_sources(self):
        plist = (ROOT / "Apps" / "Repera" / "Resources" / "Info.plist").read_text(encoding="utf-8")
        project = (ROOT / "project.yml").read_text(encoding="utf-8")
        self.assertIn("<key>NSAppleMusicUsageDescription</key>", plist)
        self.assertIn("NSAppleMusicUsageDescription:", project)


if __name__ == "__main__":
    unittest.main()
