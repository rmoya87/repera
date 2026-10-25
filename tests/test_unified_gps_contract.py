"""Contracts for a single native GPS route owner across Comenzar and Play.

These guard architecture regressions. Physical iPhone background tests are still
required for location delivery, AudioSession interruptions and battery usage.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Apps" / "Repera" / "Sources"
DOMAIN = ROOT / "Packages" / "ReperaDomain" / "Sources" / "ReperaDomain"


class UnifiedGPSContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gps = (SOURCES / "Location" / "WorkoutLocationTracker.swift").read_text()
        cls.live = (SOURCES / "LiveActivityView.swift").read_text()
        cls.store = (SOURCES / "ReperaStore.swift").read_text()
        cls.health = (SOURCES / "HealthKitStore.swift").read_text()
        cls.activity = (SOURCES / "WorkoutLiveActivityCoordinator.swift").read_text()
        cls.domain = (DOMAIN / "Models.swift").read_text()

    def test_single_active_core_location_sensor(self):
        self.assertEqual(self.gps.count("CLLocationManager()"), 1)
        self.assertNotIn("CLLocationManager()", self.live)
        self.assertIn("tracker.startRouteTracking(", self.live)
        self.assertIn("tracker.startRouteTracking(", self.store)

    def test_both_flow_updates_are_centralized(self):
        self.assertIn("private func accept(_ fix: WorkoutGPSFix)", self.gps)
        self.assertIn("recordedDistanceMeters += delta", self.gps)
        self.assertIn("onAccepted?(WorkoutGPSUpdate(", self.gps)
        self.assertIn("private func receive(_ update: WorkoutGPSUpdate)", self.live)
        self.assertIn("recordedDistanceMeters = update.distanceMeters", self.live)
        self.assertIn("publishPlannedGPSMetrics", self.store)
        self.assertIn("WorkoutLocationTracker.shared", self.activity)

    def test_raw_points_preserved_with_actual_accuracy(self):
        self.assertNotIn("maxRoutePoints = 400", self.gps)
        self.assertNotIn("downsample(routeBuffer", self.gps)
        self.assertIn("horizontalAccuracyMeters: fix.accuracy", self.gps)
        self.assertIn("horizontalAccuracyMeters: Double? = nil", self.domain)
        self.assertIn("verticalAccuracyMeters: Double? = nil", self.domain)
        self.assertNotIn("horizontalAccuracy: 15", self.health)

    def test_background_sensor_and_pause_boundaries(self):
        self.assertIn("CLBackgroundActivitySession()", self.gps)
        self.assertIn('modes.contains("location")', self.gps)
        self.assertIn("lastAccepted = nil", self.gps)
        self.assertIn("seconds <= 30", self.gps)
        self.assertIn("meters / seconds <= limit", self.gps)
        self.assertIn("sessionID: gpsSessionID, clear: clear", self.live)

    def test_healthkit_route_linked_by_exact_workout(self):
        self.assertIn("HKWorkoutRouteBuilder(", self.health)
        self.assertIn("insertRouteData(batch)", self.health)
        self.assertIn("finishRecordedGPSRoute(sessionID:", self.health)
        self.assertIn("finishRoute(with: workout, metadata: nil)", self.health)
        self.assertIn('workout.metadata?["ReperaSessionID"]', self.health)
        self.assertIn("await fetchRoutes(for: workout)", self.health)
        self.assertIn("guard let workoutUUID, let workout = await fetchWorkout", self.health)
        fetch_impl = self.health.split("private func fetchRoutePoints(", 1)[1].split(
            "private func mapLocationsToRoutePoints(", 1
        )[0]
        self.assertNotIn("fetchRoutes(overlappingStart:", fetch_impl)
        self.assertIn("await HealthKitStore.shared.finishRecordedGPSRoute(", self.store)

    def test_planned_outdoor_workout_is_not_strength_by_default(self):
        self.assertIn("workoutHealthType(for: session)", self.store)
        self.assertIn("locationType: outdoor ? .outdoor : .indoor", self.store)
        self.assertIn("activityType: workoutHealthType(for: session)", self.store)
        self.assertIn('secondaryLabel: outdoor ? "Distancia (km)" : "Series"', self.activity)


if __name__ == "__main__":
    unittest.main()
