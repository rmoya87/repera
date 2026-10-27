package dev.repera.wear
import org.junit.Test
import org.junit.Assert.*
class WearHealthPermissionsInstrumentedTest {
 @Test fun heartPermissionMigratesAt36WithoutRequestingBackgroundAccess() {
  for(sdk in listOf(30,33,35)) assertEquals("android.permission.BODY_SENSORS",WearHealthPermissions.heartRate(sdk))
  for(sdk in listOf(36,37)) {
   assertEquals("android.permission.health.READ_HEART_RATE",WearHealthPermissions.heartRate(sdk))
   assertFalse(WearHealthPermissions.requested(sdk).contains("android.permission.BODY_SENSORS"))
  }
  for(sdk in 30..37) {
   assertTrue(WearHealthPermissions.requested(sdk).contains("android.permission.ACTIVITY_RECOGNITION"))
   assertFalse(WearHealthPermissions.requested(sdk).any {it.contains("BACKGROUND")})
  }
 }
}
