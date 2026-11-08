"""Al iniciar live desde Watch, el iPhone debe abrir Comenzar y mostrar métricas reales en la Live Activity."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WatchStartPhoneMirrorContractTests(unittest.TestCase):
    def test_receiving_watch_owned_live_opens_comenzar_tab(self):
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        block = store.split(
            "func phoneConnectivityDidReceiveWatchOwnedLive(", 1
        )[1]
        block = block.split(
            "func phoneConnectivityDidReceive(session:", 1
        )[0]
        self.assertIn('repera.openComenzarFromWatch', block)
        self.assertIn("updateWatchOwned(snapshot)", block)

    def test_indoor_watch_owned_live_activity_uses_heart_and_energy(self):
        coordinator = read("Apps/Repera/Sources/WorkoutLiveActivityCoordinator.swift")
        block = coordinator.split("func updateWatchOwned(", 1)[1]
        block = block.split("func finishWatchOwned(", 1)[0]
        sport = block.split("case .sport:", 1)[1]
        self.assertIn("heartRateBpm", sport)
        self.assertIn("activeEnergyKcal", sport)
        # Indoor must not hardcode em-dash for both primary/secondary.
        self.assertNotIn('primaryValue: isGPS ? pace : "—"', sport)
        self.assertNotIn('secondaryValue: isGPS\n                    ? String(format: "%.2f", max(0, snapshot.distanceMeters) / 1000)\n                    : "—"', sport)


if __name__ == "__main__":
    unittest.main()
