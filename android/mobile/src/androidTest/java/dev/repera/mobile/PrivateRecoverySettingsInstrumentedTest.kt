package dev.repera.mobile
import android.content.Context
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.Assert.*
class PrivateRecoverySettingsInstrumentedTest {
 private fun context():Context {
  val base=InstrumentationRegistry.getInstrumentation().targetContext
  val dir=java.io.File(base.cacheDir,"private-recovery-${java.util.UUID.randomUUID()}").apply {mkdirs()}
  return object:android.content.ContextWrapper(base) {override fun getNoBackupFilesDir()=dir}
 }
 @Test fun noImplicitSleepPermissionAndDecisionIsLocalPersistentAndReversible() {
  val c=context();val store=PrivateRecoverySettings(c)
  assertFalse(store.sleepEnabled());assertFalse(store.sleepDecisionMade())
  val permission=androidx.health.connect.client.permission.HealthPermission.getReadPermission(androidx.health.connect.client.records.SleepSessionRecord::class)
  assertFalse(HealthConnectReader.permissions.contains(permission))
  assertFalse(HealthConnectReader(c).requestedPermissions().contains(permission))
  store.setSleep(true)
  assertTrue(PrivateRecoverySettings(c).sleepEnabled());assertTrue(PrivateRecoverySettings(c).sleepDecisionMade())
  assertTrue(HealthConnectReader(c).requestedPermissions().contains(permission))
  store.setSleep(false)
  assertFalse(PrivateRecoverySettings(c).sleepEnabled());assertTrue(PrivateRecoverySettings(c).sleepDecisionMade())
  assertFalse(HealthConnectReader(c).requestedPermissions().contains(permission))
 }
 @Test fun cycleChoiceIsIndependentExcludedFromGeneralRequestAndSurvivesSleepChanges() {
  val c=context();val store=PrivateRecoverySettings(c)
  val permission=androidx.health.connect.client.permission.HealthPermission.getReadPermission(androidx.health.connect.client.records.MenstruationFlowRecord::class)
  assertFalse(store.cycleEnabled());assertFalse(store.cycleDecisionMade())
  assertFalse(HealthConnectReader.permissions.contains(permission))
  assertFalse(HealthConnectReader(c).requestedPermissions().contains(permission))
  store.setCycle(true);store.setSleep(true);store.setSleep(false)
  assertTrue(PrivateRecoverySettings(c).cycleEnabled())
  assertTrue(PrivateRecoverySettings(c).cycleDecisionMade())
  assertTrue(HealthConnectReader(c).requestedPermissions().contains(permission))
  store.setCycle(false)
  assertFalse(HealthConnectReader(c).requestedPermissions().contains(permission))
  assertFalse(PrivateRecoverySettings(c).sleepEnabled())
 }
 @Test fun concurrentChoicesFromDifferentInstancesDoNotOverwriteEachOther() {
  val c=context();val start=java.util.concurrent.CountDownLatch(1)
  val pool=java.util.concurrent.Executors.newFixedThreadPool(2)
  try {
   val sleep=pool.submit {start.await();PrivateRecoverySettings(c).setSleep(true)}
   val cycle=pool.submit {start.await();PrivateRecoverySettings(c).setCycle(true)}
   start.countDown();sleep.get(5,java.util.concurrent.TimeUnit.SECONDS);cycle.get(5,java.util.concurrent.TimeUnit.SECONDS)
   val restored=PrivateRecoverySettings(c)
   assertTrue(restored.sleepEnabled());assertTrue(restored.cycleEnabled())
   assertTrue(restored.sleepDecisionMade());assertTrue(restored.cycleDecisionMade())
  } finally {pool.shutdownNow()}
 }
 @Test fun interruptedAtomicWriteDoesNotReplaceTheConfirmedChoices() {
  val c=context();PrivateRecoverySettings(c).setCycle(true)
  val file=android.util.AtomicFile(java.io.File(c.noBackupFilesDir,"repera-private-recovery.json"))
  val incomplete=file.startWrite();incomplete.write("invalid".toByteArray());incomplete.close()
  assertTrue(PrivateRecoverySettings(c).cycleEnabled())
  PrivateRecoverySettings(c).setSleep(true)
  assertTrue(PrivateRecoverySettings(c).sleepEnabled());assertTrue(PrivateRecoverySettings(c).cycleEnabled())
 }
}
