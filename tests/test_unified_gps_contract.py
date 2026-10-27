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
        cls.widget = (ROOT / "Apps" / "ReperaRestWidget" /
                      "TrainingLiveActivityWidget.swift").read_text()
        cls.attributes = (ROOT / "Apps" / "Shared" /
                          "TrainingActivityAttributes.swift").read_text()
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


    def test_loaded_route_keeps_navigation_on_screen(self):
        self.assertIn(
            "showingMetrics = recorder.sport.usesGPS && recorder.chosenRoute == nil",
            self.live,
        )
        self.assertNotIn("recorder.upcomingTurnMeters != nil", self.live)
        self.assertIn("if recorder.chosenRoute != nil {", self.live)
        self.assertIn("Sigue el recorrido", self.live)
        self.assertIn("Fuera de ruta", self.live)

    def test_giro_remains_active_at_junction_and_street_is_not_guessed(self):
        self.assertIn("$0.metersAlongRoute >= along - 12", self.live)
        self.assertIn("MKReverseGeocodingRequest(location:", self.live)
        self.assertIn("request.mapItems", self.live)
        self.assertIn("streetRequest?.cancel()", self.live)
        self.assertIn("if let street = recorder.upcomingTurnStreet", self.live)

    def test_navigation_cue_and_metrics_reach_live_activity_widget(self):
        self.assertIn("public var navigation: NavigationCue?", self.attributes)
        self.assertIn("navigation: navigation", self.live)
        self.assertIn("navigation: phase == .completed ? nil : navigation", self.activity)
        self.assertIn("navigationStrip(cue, compact: true)", self.widget)
        self.assertIn("navigationStrip(cue, compact: false)", self.widget)
        self.assertIn("lockMetric(value: timer(context.state)", self.widget)
        self.assertIn("islandMetric(value: timer(context.state)", self.widget)


if __name__ == "__main__":
    unittest.main()
