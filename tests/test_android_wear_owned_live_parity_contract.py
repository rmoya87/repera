"""Wear-owned Live on Android: transport, account isolation and recovery contracts.

These source-level guards complement (but do not replace) tests on paired
Android/Wear OS devices, notifications and background service lifecycle.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


WEAR = "android/wear/src/main/java/dev/repera/wear/WearMainActivity.kt"
WEAR_SERVICE = "android/wear/src/main/java/dev/repera/wear/WearHealthService.kt"
PUBLISHER = "android/wear/src/main/java/dev/repera/wear/WearOwnedLivePublisher.kt"
PHONE_MIRROR = "android/mobile/src/main/java/dev/repera/mobile/WearOwnedLiveMirror.kt"
PHONE_SERVICE = "android/mobile/src/main/java/dev/repera/mobile/LiveActivityService.kt"
PHONE_LISTENER = "android/mobile/src/main/java/dev/repera/mobile/WearLiveCommandListener.kt"
MAIN = "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
BRIDGE = "android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt"


class WearOwnedLiveParityTests(unittest.TestCase):
    def test_watch_remembers_original_account_owner(self):
        bridge, wear, publisher = read(BRIDGE), read(WEAR), read(PUBLISHER)
        self.assertIn('dataMap.putString("ownerScope"', bridge)
        self.assertIn('putString("mobileOwnerScope", incomingScope)', wear)
        self.assertIn('put("ownerScope", sessionCache.getString("mobileOwnerScope"', wear)
        self.assertIn('val scope = live.optString("ownerScope")', publisher)
        self.assertIn('if (id.isBlank() || scope.isBlank()', publisher)

    def test_watch_live_start_pause_resume_finish_and_sensor_background_republish(self):
        wear, service = read(WEAR), read(WEAR_SERVICE)
        self.assertIn('WearOwnedLivePublisher.publish(this, live, force = true)', wear)
        self.assertIn('WearOwnedLivePublisher.close(this, it)', wear)
        self.assertIn('WearOwnedLivePublisher.publish(this, it)', service)
        publisher = read(PUBLISHER)
        self.assertIn('"/repera/watch-owned-live"', publisher)
        self.assertIn('now - lastSentAt < 30_000L', publisher)
        self.assertIn('PutDataMapRequest.create("/repera/watch-owned-live")', publisher)
        self.assertIn('Wearable.getDataClient(context).putDataItem(request)', publisher)

    def test_android_mirror_is_account_scoped_read_only_and_durable(self):
        mirror = read(PHONE_MIRROR)
        self.assertIn('payload.optString("ownerScope") != account.uniqueId', mirror)
        self.assertIn('prefs.getString("revision", null) != revision', mirror)
        self.assertIn('WearOwnedLiveDeliveryPolicy.accepts(', mirror)
        self.assertIn('previousAt, id in closed', mirror)
        policy = read(
            "android/domain/src/main/java/dev/repera/domain/WearOwnedLiveDeliveryPolicy.kt"
        )
        self.assertIn('capturedAtMillis > previousCapturedAtMillis', policy)
        self.assertIn('!isClosed', policy)
        self.assertIn('prefs.edit().putString("closed"', mirror)
        self.assertIn('WearOwnedLiveMirror', read(MAIN))
        self.assertNotIn('HealthConnectWriter(', mirror)
        self.assertNotIn('startForegroundService(', mirror)
        self.assertNotIn('.startGPS(', mirror)
        self.assertIn('val phone = LiveActivityRuntime.forAccount(', mirror)
        self.assertIn('.setTimeoutAfter(180_000L)', mirror)

    def test_final_save_closes_mirror_even_if_final_state_arrived_first(self):
        listener, main, mirror = read(PHONE_LISTENER), read(MAIN), read(PHONE_MIRROR)
        self.assertIn('WearOwnedLiveMirror.closeSaved(this, id)', listener)
        self.assertIn('WearOwnedLiveMirror.closeSaved(this@MainActivity, sessionId)', main)
        self.assertIn('markClosed(prefs, closedIds(', mirror)
        self.assertIn('prefs.edit().putLong("captured", maxOf(previousAt, captured))', mirror)
        self.assertIn('The durable live-save may arrive before the first live packet', mirror)
        self.assertIn('WearOwnedLiveMirror.clearForSignOut(this@MainActivity)', main)

    def test_foreground_and_background_receive_same_watch_message(self):
        listener, main = read(PHONE_LISTENER), read(MAIN)
        self.assertIn('if (event.path == "/repera/watch-owned-live")', listener)
        self.assertIn('if (event.path == "/repera/watch-owned-live")', main)
        self.assertIn('if (!WearUiPresence.active)', listener)
        self.assertIn('WearOwnedLiveMirror.accept(this, payload)', listener)
        self.assertIn('WearOwnedLiveMirror.accept(this, payload)', main)
        self.assertIn('override fun onDataChanged(events: DataEventBuffer)', listener)
        self.assertIn('event.dataItem.uri.path != "/repera/watch-owned-live"', listener)
        self.assertIn('Wearable.getDataClient(this).dataItems', main)
        self.assertIn('WearOwnedLiveMirror.accept(this, snapshot)', main)

    def test_wear_exercise_service_restarts_by_reattaching_not_duplicating_health(self):
        service = read(WEAR_SERVICE)
        sensors = read("android/wear/src/main/java/dev/repera/wear/WearHealthSession.kt")
        self.assertIn("return START_REDELIVER_INTENT", service)
        self.assertIn("if(id.isNullOrBlank() || !isCurrent(id))", service)
        self.assertIn('cache.getString("sensorEndedSessionId",null)==id', service)
        self.assertIn("ExerciseOwnership.OWNED", sensors)
        self.assertIn("Reattach, never replace our surviving exercise", sensors)
        self.assertIn('binding.getString("sessionId",null)!=sessionId', sensors)
        teardown = service.split("override fun onDestroy()", 1)[1].split(
            "companion object", 1
        )[0]
        self.assertIn("sensors.detach()", teardown)
        self.assertNotIn("sensors.stop(", teardown)

    def test_android_phone_owned_service_recovery_still_checks_uuid_and_account(self):
        service = read(PHONE_SERVICE)
        self.assertIn('return START_REDELIVER_INTENT', service)
        self.assertIn('return START_NOT_STICKY', service)
        self.assertIn('incoming.matches(', service)
        shutdown = service.split('override fun onDestroy()', 1)[1].split(
            'private fun notification(', 1
        )[0]
        self.assertIn('checkpoint(true)', shutdown)
        self.assertNotIn('.pause()', shutdown)


if __name__ == "__main__":
    unittest.main()
