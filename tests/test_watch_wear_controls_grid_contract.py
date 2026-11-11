#!/usr/bin/env python3
"""Contrato: controles live/plan/timer en rejilla 2×2 solo iconos."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class WatchWearControlsGridContract(unittest.TestCase):
    def test_watch_session_controls_grid_layout(self):
        session = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        live = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        timer = read("Apps/ReperaWatch/Sources/WatchStandaloneTimerView.swift")
        self.assertIn("struct WatchSessionControlsGrid:", session)
        self.assertIn('systemName: isPaused ? "play.fill" : "pause.fill"', session)
        self.assertIn('systemName: "flag.checkered"', session)
        self.assertIn('systemName: "xmark"', session)
        self.assertIn("speaker.slash.fill", session)
        self.assertIn("Color(red: 0.90, green: 0.22, blue: 0.21)", session)
        self.assertIn("WatchSessionControlsGrid(", live)
        self.assertIn("WatchSessionControlsGrid(", timer)
        # Sin filas etiquetadas en la superficie de controles live.
        controls = live.split("} controls: {", 1)[1].split(".task(id:", 1)[0]
        self.assertNotIn('title: "Pausar"', controls)
        self.assertNotIn('title: "Finalizar"', controls)
        self.assertNotIn("Cancelar actividad\", role:", controls)

    def test_wear_live_controls_are_two_by_two_icons(self):
        wear = read(
            "android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt"
        )
        page = wear.split("private fun WearLiveControlsPage(", 1)[1].split(
            "private fun WearLiveReviewPage(", 1
        )[0]
        self.assertIn("Icons.Filled.Pause", page)
        self.assertIn("Icons.Filled.PlayArrow", page)
        self.assertIn("Icons.Filled.Flag", page)
        self.assertIn("Icons.Filled.Close", page)
        self.assertIn("VolumeOff", page)
        self.assertIn("VolumeUp", page)
        self.assertIn("WearOg.red", page)
        self.assertIn("onRequestCancel", page)
        self.assertIn("onToggleAudioMuted", page)

    def test_wear_cancel_command_reaches_phone_and_owned(self):
        main = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        listener = read(
            "android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt"
        )
        self.assertIn('setOf("pause", "resume", "finish", "cancel")', main)
        self.assertIn('"cancel" ->', main)
        self.assertIn('setOf("pause", "resume", "finish", "cancel")', listener)
        self.assertIn('"cancel" ->', listener)
        self.assertIn("runtime.discard()", listener)


if __name__ == "__main__":
    unittest.main()
