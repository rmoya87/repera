"""Watch→iPhone Comenzar: misma LiveActivityView que phone-start (no espejo de cards)."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WatchStartLiveActivityParityTests(unittest.TestCase):
    def test_sport_watch_owned_uses_live_activity_view_not_card_mirror(self):
        root = read("Apps/Repera/Sources/RootTabView.swift")
        tab = root.split('value: AppTab.start', 1)[1].split("SwiftUI.Tab(", 1)[0]
        self.assertIn("watchLive.kind == .planned", tab)
        self.assertIn("LiveActivityView(", tab)
        self.assertIn("WatchOwnedLiveMirrorView(", tab)
        # El espejo de cards solo aplica a planes; el deporte usa LiveActivityView.
        planned = tab.split("watchLive.kind == .planned", 1)[1]
        self.assertLess(
            planned.index("WatchOwnedLiveMirrorView("),
            planned.index("LiveActivityView("),
        )

    def test_recorder_adopts_watch_owned_sport_mirror(self):
        live = read("Apps/Repera/Sources/LiveActivityView.swift")
        self.assertIn("func adoptWatchOwnedSportMirror(", live)
        self.assertIn("func applyWatchOwnedSportMirror(", live)
        self.assertIn("func clearWatchOwnedSportMirror(", live)
        self.assertIn("isWatchOwnedMirror", live)
        self.assertIn('watchOwnedCommandHandler?("pause")', live)
        self.assertIn('watchOwnedCommandHandler?("finish")', live)
        self.assertIn("guard !isWatchOwnedMirror else { return }", live)

    def test_store_wires_mirror_and_commands(self):
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("watchOwnedCommandHandler", store)
        self.assertIn("adoptWatchOwnedSportMirror(snapshot)", store)
        self.assertIn("clearWatchOwnedSportMirror()", store)


if __name__ == "__main__":
    unittest.main()
