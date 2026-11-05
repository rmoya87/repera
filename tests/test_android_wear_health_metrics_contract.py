"""Contratos sin Android SDK: propiedad Wear, calorías y distancia verificadas."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class WearHealthMetricContracts(unittest.TestCase):
    def test_wear_started_sport_is_never_redirected_to_phone(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        block = wear.split("private fun requestLiveStart(sportId: String)", 1)[1].split(
            "private fun receiveLiveStartAck(", 1
        )[0]
        self.assertIn("startWatchOwnedLive(sportId)", block)
        self.assertNotIn('"/repera/live-start"', block)

    def test_phone_started_activity_uses_native_wrist_exercise(self):
        service = read("android/wear/src/main/java/dev/repera/wear/WearHealthService.kt")
        session = read("android/wear/src/main/java/dev/repera/wear/WearHealthSession.kt")
        self.assertIn("sensors.start(id, sportId = sportId, companion = true)", service)
        self.assertIn("sensors.start(id, sportId = sportId, companion = false)", service)
        self.assertIn("sensors.startMeasure(id)", service)
        self.assertIn("!companion && WearHealthExerciseTypes.usesGps(sportId)", session)
        self.assertIn("DataType.CALORIES_TOTAL", session)
        self.assertIn("averageHeartRateBpm", session)

    def test_total_energy_never_masquerades_as_active(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        writer = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectWriter.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        self.assertIn('payload.put("totalEnergyKcal"', wear)
        self.assertIn('session.put("wearTotalEnergyKcal"', repo)
        self.assertIn("TotalCaloriesBurnedRecord(", writer)
        self.assertNotIn("ActiveCaloriesBurnedRecord(", writer)

    def test_live_metrics_reconcile_when_foreground_or_background(self):
        main = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        listener = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt")
        receiver = read("android/mobile/src/main/java/dev/repera/mobile/WearLiveMetricsReceiver.kt")
        self.assertIn("WearLiveMetricsReceiver.accept(", main)
        self.assertIn("WearLiveMetricsReceiver.accept(", listener)
        self.assertIn("mergeWearMeasuredMetrics(", receiver)
        self.assertIn("java.util.UUID.fromString(id)", receiver)
        self.assertIn("capturedAt !in", receiver)

    def test_iphone_like_one_session_writer_and_no_duplicate_health_metrics(self):
        writer = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectWriter.kt")
        self.assertIn("HealthSessionLink.clientRecordId(sessionId)", writer)
        self.assertIn("LinkDecision.UseExisting", writer)
        self.assertIn("existing != null && existing.isEmpty()", writer)
        self.assertIn('"repera-distance-$sessionId"', writer)
        self.assertIn('"repera-wear-total-$sessionId"', writer)
        self.assertIn("DistanceRecord(", writer)

    def test_sport_mapping_preserved_for_walk_run_cycling_wod_and_classes(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearHealthExerciseTypes.kt")
        repo = read("android/mobile/src/main/java/dev/repera/mobile/WorkoutRepository.kt")
        self.assertIn("LiveSport.WALKING -> ExerciseType.WALKING", wear)
        self.assertIn("LiveSport.RUNNING, LiveSport.TRAIL -> ExerciseType.RUNNING", wear)
        self.assertIn("LiveSport.HIIT, LiveSport.CROSSFIT, LiveSport.HYROX", wear)
        self.assertIn("fun sessionHealthSportId(", repo)
        self.assertIn('LiveSport.CROSSFIT.id', repo)
        self.assertIn("FallbackActivityKind.resolving(title).liveSportId", repo)

    def test_class_without_plan_falls_back_to_gym_or_hiit(self):
        domain = read("android/domain/src/main/java/dev/repera/domain/FallbackActivityKind.kt")
        plus = read("android/mobile/src/main/java/dev/repera/mobile/PlusHubTab.kt")
        screen = read("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        wear = read("android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt")
        writer = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectWriter.kt")
        self.assertIn("fun resolving(title: String)", domain)
        self.assertIn('STRENGTH("strength")', domain)
        self.assertIn('HIIT("hiit")', domain)
        self.assertIn("onStartClassWithoutPlan", plus)
        self.assertIn("startFallbackGymOrHIIT", screen)
        self.assertIn("FallbackActivityKind.resolving", wear)
        self.assertIn("LiveSport.OTHER -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING", writer)

    def test_phone_review_saves_wrist_metrics_and_history_exposes_them(self):
        screen = read("android/mobile/src/main/java/dev/repera/mobile/LiveActivityScreen.kt")
        main = read("android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt")
        history = read("android/mobile/src/main/java/dev/repera/mobile/CompleteHistoryScreen.kt")
        self.assertIn("wearTotalEnergyKcal = runtime.currentWearTotalEnergyKcal()", screen)
        self.assertIn("wearAverageHeartRateBpm = runtime.currentWearAverageHeartRateBpm()", screen)
        self.assertIn("val wearTotalEnergyKcal: Double?", main)
        self.assertIn('workout.wearTotalEnergyKcal', history)

    def test_permissions_opt_in_and_no_fake_calories(self):
        manifest = read("android/mobile/src/main/AndroidManifest.xml")
        reader = read("android/mobile/src/main/java/dev/repera/mobile/HealthConnectReader.kt")
        self.assertIn("WRITE_DISTANCE", manifest)
        self.assertIn("WRITE_TOTAL_CALORIES_BURNED", manifest)
        self.assertIn("TotalCaloriesBurnedRecord::class", reader)
        domain = read("android/domain/src/main/java/dev/repera/domain/WearMeasuredEnergy.kt")
        self.assertIn("kcal?.takeIf { it.isFinite() && it > 0.0 }", domain)


if __name__ == "__main__":
    unittest.main()
