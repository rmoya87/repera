"""Contratos de exportación de métricas reales a Apple Salud / Fitness.

No sustituyen la prueba en Apple Watch físico: validan rutas críticas que
anteriormente exportaban un workout sin kcal o con mapa pero sin distancia.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class HealthKitActivityExportContractTests(unittest.TestCase):
    def test_sport_started_on_watch_is_owned_by_watch(self):
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        play = hub.split("func playHubSport(", 1)[1].split(
            "private func scheduleCompanionStartTimeout", 1
        )[0]
        self.assertIn("startWatchOwnedLive(sport: sport)", play)
        self.assertNotIn("connectivity.sendStartLive", play)
        self.assertIn("startMirroringToCompanionDevice", source(
            "Apps/ReperaWatch/Sources/WatchHealthKitSession.swift"
        ))

    def test_all_watch_sports_use_native_activity_mapping(self):
        catalog = source("Apps/ReperaWatch/Sources/WatchLiveSportCatalog.swift")
        self.assertIn("case .walking: .walking", catalog)
        self.assertIn("case .hiking: .hiking", catalog)
        self.assertIn("case .cycling, .mountainBike, .gravel: .cycling", catalog)
        self.assertIn("case .crossfit, .hyrox: .crossTraining", catalog)
        self.assertIn("case .strength: .traditionalStrengthTraining", catalog)
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("activityType: sport.healthKitActivityType", hub)
        phone = source("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("return sport.healthType", phone)
        self.assertIn("if hasWOD { return .crossTraining }", phone)

    def test_watch_writes_measured_gps_distance_before_finishing_workout(self):
        watch = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        hub = source("Apps/ReperaWatch/Sources/WatchSessionHub.swift")
        self.assertIn("updateRecordedRouteDistance(self.watchLiveDistanceMeters)", hub)
        self.assertIn("recordedRouteDistanceMeters >= 20", watch)
        self.assertIn("if native <= 0", watch)
        self.assertIn("try await builder.addSamples([sample])", watch)
        self.assertLess(
            watch.index("try await builder.addSamples([sample])"),
            watch.index("try await builder.endCollection(at: date)"),
        )
        self.assertIn("identifier = .distanceWalkingRunning", watch)
        self.assertIn("identifier = .distanceCycling", watch)
        self.assertIn("HKSeriesType.workoutRoute()", watch)

    def test_iphone_uses_gps_distance_without_overwriting_native_distance(self):
        phone = source("Apps/Repera/Sources/HealthKitStore.swift")
        store = source("Apps/Repera/Sources/ReperaStore.swift")
        self.assertIn("recordedDistanceMeters: Double? = nil", phone)
        self.assertIn("recordedDistanceMeters: session.recordedDistanceMeters", store)
        self.assertIn("guard existing <= 0 else { return }", phone)
        self.assertIn("try await builder.addSamples([sample])", phone)
        self.assertIn("activityType: activityType, locationType: locationType", phone)
        self.assertIn("HKMetadataKeyWorkoutBrandName: \"Repera\"", phone)

    def test_energy_is_verified_never_estimated_from_heart_rate_or_met(self):
        watch = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        phone = source("Apps/Repera/Sources/HealthKitStore.swift")
        self.assertIn("energyCandidates.first(where: { $0 > 0 })", watch)
        self.assertIn("liveActiveEnergyKcal = await externalWorkoutEnergyKcal", phone)
        self.assertIn("_ = fallbackKcal", phone)
        self.assertNotIn("estimateActiveEnergyKcal(", watch)

    def test_both_apple_targets_embed_a_real_app_icon(self):
        phone_icon = source(
            "Apps/Repera/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json"
        )
        watch_icon = source(
            "Apps/ReperaWatch/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json"
        )
        project = source("project.yml")
        self.assertIn('"filename" : "AppIcon.png"', phone_icon)
        self.assertIn('"filename" : "AppIcon.png"', watch_icon)
        self.assertGreaterEqual(
            project.count("ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon"), 2
        )

    def test_permissions_cover_numeric_distance_and_workout_route(self):
        watch = source("Apps/ReperaWatch/Sources/WatchHealthKitSession.swift")
        phone = source("Apps/Repera/Sources/HealthKitStore.swift")
        self.assertIn("share.insert(distanceType)", watch)
        self.assertIn("read.insert(distanceType)", watch)
        for distance in (
            ".distanceWalkingRunning", ".distanceCycling",
            ".distanceSwimming", ".distanceDownhillSnowSports"
        ):
            self.assertIn(distance, phone)
        self.assertIn("HKSeriesType.workoutRoute()", phone)


if __name__ == "__main__":
    unittest.main()
