"""Contratos: paridad Fitness / Health Connect (ruta, cáscara 0 kcal, históricos).

No sustituyen hardware. Verifican que el código deja de abandonar cáscaras
iPhone, escribe HKWorkoutRoute desde Watch outdoor y repara entrenos ya
pasados con ruta local. Android: live-save Wear exporta track y refine HC.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class HealthFitnessParityContractTests(unittest.TestCase):
    def test_phone_shell_zero_kcal_is_deleted_when_watch_wins(self):
        health = read("Apps/Repera/Sources/HealthKitStore.swift")
        # Al preferir el HKWorkout del Watch, la cáscara iPhone 0 kcal debe
        # borrarse de Salud (no solo dejar de enlazarla en Repera).
        self.assertIn("deleteExternalWorkout(id: owned.uuid)", health)
        shell_branch = health.split("let phoneShell = Self.isReperaSource", 1)[1].split(
            "} else if let external {", 1
        )[0]
        self.assertIn("deleteExternalWorkout(id: owned.uuid)", shell_branch)

    def test_watch_outdoor_writes_healthkit_route(self):
        watch = read("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        hub = read("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("HKWorkoutRouteBuilder", watch)
        self.assertIn("insertRouteData", watch)
        self.assertIn("finishRoute", watch)
        self.assertIn("HKSeriesType.workoutRoute()", watch)
        self.assertIn("appendRouteLocations", watch)
        # El hub alimenta Salud con los mismos fixes GPS del live outdoor.
        self.assertIn("health.appendRouteLocations", hub)

    def test_iphone_repairs_past_sessions_routes_and_orphan_shells(self):
        store = read("Apps/Repera/Sources/ReperaStore.swift")
        health = read("Apps/Repera/Sources/HealthKitStore.swift")
        self.assertIn("repairPastHealthKitExports", store)
        self.assertIn("attachRecordedRouteIfNeeded", store)
        # Reparación de cáscaras huérfanas: buscar y borrar shells 0 kcal
        # cuando ya hay workout Watch enlazado a la misma sesión.
        self.assertIn("deleteOrphanPhoneShells", health)
        self.assertIn("repairPastHealthKitExports", store)

    def test_live_activities_doc_no_longer_claims_route_export_pending(self):
        live = read("docs/LIVE_ACTIVITIES.md")
        self.assertNotIn(
            "La exportación adicional del trazado como HKWorkoutRoute de Apple Salud queda pendiente",
            live,
        )

    def test_android_wear_owned_exports_route_and_refines_health(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        main = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        listener = read(
            "android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt"
        )
        # Payload live-save incluye routePoints cuando hubo GPS outdoor.
        self.assertIn('"routePoints"', wear)
        self.assertIn("routePoints", repo.split("fun saveWearOwnedLiveActivity", 1)[1]
                      .split("fun saveLiveActivity", 1)[0])
        # Tras live-save watch-owned se llama refine (HC + attach ruta).
        live_save = main.split('if (event.path == "/repera/live-save")', 1)[1].split(
            'if (event.path == "/repera/session-finish")', 1
        )[0]
        self.assertIn("refineFinishedSessionWithHealth(sessionId)", live_save)
        self.assertIn("HealthConnectWriter", listener)
        self.assertIn("syncFinishedSession", listener)
        self.assertIn("routePoints", listener)


if __name__ == "__main__":
    unittest.main()
