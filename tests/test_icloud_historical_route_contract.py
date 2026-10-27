"""Contratos de rutas históricas sincronizadas y textos para usuario.

No sustituye compilar con Xcode ni probar dos iPhone con el mismo iCloud.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"


def read(path):
    return path.read_text(encoding="utf-8")


class ICloudHistoricalRouteContracts(unittest.TestCase):
    def test_full_personal_state_contains_route_points(self):
        models = read(DOMAIN / "Models.swift")
        self.assertIn("public var routePoints: [WorkoutRoutePoint]", models)
        self.assertIn("routePoints = try c.decodeIfPresent([WorkoutRoutePoint].self", models)
        self.assertIn("try c.encode(routePoints, forKey: .routePoints)", models)

    def test_conflict_recovery_preserves_only_matching_recorded_routes(self):
        local = read(IOS / "LocalStore.swift")
        resolver = read(DOMAIN / "SyncConflictResolver.swift")
        self.assertIn("restoringMissingWorkoutRoutes(", local)
        self.assertIn("case reconciledRouteData(AppState)", local)
        self.assertIn("let otherByID = Dictionary(other.workouts.map", resolver)
        self.assertIn("guard let original = otherByID[id] else { continue }", resolver)
        self.assertIn("original.routePoints.count >= 2", resolver)

    def test_recovered_routes_are_flushed_and_published(self):
        store = read(IOS / "ReperaStore.swift")
        self.assertIn("case .reconciledRouteData(let recovered):", store)
        self.assertIn("await store.persistAndFlush(state)", store)
        self.assertIn("await store.pushToiCloudIfSafe(state)", store)
        self.assertIn("workoutsEpoch &+= 1", store)

    def test_history_route_refreshes_without_reopening(self):
        history = read(IOS / "HistoryView.swift")
        self.assertIn(".onChange(of: store.workoutsEpoch)", history)
        self.assertIn("await store.refreshFromiCloud()", history)
        self.assertIn('Label("Recorrido no disponible", systemImage: "map")', history)
        self.assertNotIn("no viajan por Supabase", history)

    def test_manual_sync_starts_with_complete_icloud_copy(self):
        settings = read(IOS / "SettingsView.swift")
        sync = settings.split('Text((isManualSyncing || workoutSync.isSyncing)', 1)[0]
        self.assertIn("await store.refreshFromiCloud()", sync)
        self.assertIn("await LocalStore.shared.persistAndFlush(store.state)", sync)
        self.assertLess(sync.index("await store.refreshFromiCloud()"),
                        sync.index("await LocalStore.shared.persistAndFlush(store.state)"))
        self.assertIn("isManualSyncing", settings)

    def test_visible_messages_do_not_expose_internal_storage_provider(self):
        history = read(IOS / "HistoryView.swift")
        settings = read(IOS / "SettingsView.swift")
        self.assertNotIn('Text("Los entrenos finalizados se guardan localmente y se envían a Supabase', settings)
        self.assertNotIn('puntos GPS no viajan por Supabase', history)
        sync = read(IOS / "BusinessWorkoutSyncStore.swift")
        self.assertNotIn('lastError = "La sincronización con Supabase', sync)


if __name__ == "__main__":
    unittest.main()
