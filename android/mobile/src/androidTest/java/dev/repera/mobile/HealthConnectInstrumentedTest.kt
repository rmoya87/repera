package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Contrato de degradación de Health Connect SIN datos de salud reales:
 * en el emulador CI (aosp_atd, sin app Health Connect) el SDK no está
 * disponible o no hay permisos; el escritor nunca lanza y devuelve null
 * (entreno intacto en local, «guardar únicamente en Repera» iOS), y el
 * lector declara su contrato documentado en lugar de fallar con crash.
 * No se conceden permisos ni se escriben registros: solo se verifica la
 * ruta segura por defecto.
 */
@RunWith(AndroidJUnit4::class)
class HealthConnectInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun writerReturnsNullAndNeverThrowsWithoutAvailabilityOrPermission() = runBlocking {
        val writer = HealthConnectWriter(context)
        val result = writer.syncFinishedSession(
            sessionId = "synthetic-session",
            title = "Entreno sintético",
            startEpochMs = 1_700_000_000_000L,
            endEpochMs = 1_700_000_003_600_000L,
            storedRecordId = null
        )
        assertNull("sin disponibilidad/permiso no se escribe ni se vincula nada", result)
    }

    @Test fun writerWithStoredLinkStillReturnsNullWithoutAvailability() = runBlocking {
        // Idempotencia: ni con un vínculo persistido se toca Salud si no hay
        // disponibilidad/permiso; el vínculo local se conserva (no se devuelve
        // un id distinto ni se borra nada: la función solo lee/devuelve null).
        val writer = HealthConnectWriter(context)
        val result = writer.syncFinishedSession(
            sessionId = "synthetic-session",
            title = "Entreno sintético",
            startEpochMs = 1_700_000_000_000L,
            endEpochMs = 1_700_000_003_600_000L,
            storedRecordId = "hc-record-sintetico"
        )
        assertNull(result)
    }

    @Test fun readerDeclaresAvailabilityAndPermissionsWithoutThrowing() = runBlocking {
        val reader = HealthConnectReader(context)
        // En el emulador sin HC: available() == false. En un dispositivo con HC
        // pero sin permisos concedidos: hasPermissions() == false. Ambas rutas
        // son seguras y no lanzan.
        if (!reader.available()) {
            assertFalse(reader.hasPermissions())
        } else {
            assertFalse("emulador fresco: sin permisos concedidos", reader.hasPermissions())
        }
    }

    @Test fun readTodayFailsWithDocumentedContractNotCrash() = runBlocking {
        val reader = HealthConnectReader(context)
        try {
            reader.readToday()
            fail("sin disponibilidad/permiso readToday debe rechazar con el contrato documentado")
        } catch (e: IllegalStateException) {
            assertTrue(e.message!!.contains("Health Connect"))
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message!!.contains("Salud"))
        }
        Unit
    }
    @org.junit.Test fun partialReadGrantsDoNotRequireUnrelatedWriteAccess() {
        val read=androidx.health.connect.client.permission.HealthPermission.getReadPermission(androidx.health.connect.client.records.HeartRateRecord::class)
        val write=androidx.health.connect.client.permission.HealthPermission.getWritePermission(androidx.health.connect.client.records.ExerciseSessionRecord::class)
        org.junit.Assert.assertTrue(HealthConnectReader.hasReadablePermission(setOf(read)))
        org.junit.Assert.assertFalse(HealthConnectReader.hasReadablePermission(setOf(write)))
        org.junit.Assert.assertFalse(HealthConnectReader.hasReadablePermission(emptySet()))
    }
    @org.junit.Test fun historyExtensionIsFeatureGatedAndNotARecordGrant() {
        val permission=androidx.health.connect.client.permission.HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY
        assertTrue(HealthConnectReader.historyPermissionsIfAvailable(false).isEmpty())
        org.junit.Assert.assertEquals(setOf(permission),HealthConnectReader.historyPermissionsIfAvailable(true))
        assertFalse(HealthConnectReader.hasReadablePermission(setOf(permission)))
    }
}
