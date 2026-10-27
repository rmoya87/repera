package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Cadena completa de recuperación de cierre imprevisto (Apple ca3c0383):
 *  LiveGPSOdometer (bridging) + LiveActivityState.restore (auto-reanudación). */
class InterruptedRecoveryBridgeTest {

    private val t0 = 1_800_000_000_000L
    private fun fix(lat: Double, lon: Double, at: Long, acc: Double = 5.0) =
        LiveGPSOdometer.Fix(lat, lon, at, acc)
    private fun anchor() = WorkoutRoutePoint(0, 40.500, -3.900, t0)

    @Test fun firstFixAfterInterruptedStartBridgesPlausibleGap() {
        val o = LiveGPSOdometer()
        assertTrue(o.start("s1", t0 + 120_000, LiveSport.WALKING,
            existingPoints = listOf(anchor()), existingDistanceMeters = 100.0,
            bridgeInterruptedGap = true,
            recoveryMaximumSpeedMps = LiveSport.WALKING.recoveryMaximumSpeedMps))
        val update = o.accept(fix(40.501, -3.900, t0 + 120_000), t0 + 120_000)!!
        assertTrue(update.bridgedPoints.isNotEmpty())
        assertTrue(update.bridgedPoints.all { it.isEstimated == true })
        assertTrue(update.bridgedDistanceMeters > 100)
        // ids consecutivos: estimados tras los existentes, el real al final.
        assertEquals(update.bridgedPoints.size + 1, update.point.id)
        assertEquals(100.0 + update.bridgedDistanceMeters, update.distanceMeters, 0.001)
        // El ancla se consume: la segunda muestra NO vuelve a puentear.
        val second = o.accept(fix(40.5011, -3.900, t0 + 125_000), t0 + 125_000)!!
        assertTrue(second.bridgedPoints.isEmpty())
    }

    @Test fun manualResumeNeverBridges() {
        val o = LiveGPSOdometer()
        assertTrue(o.start("s1", t0 + 120_000, LiveSport.WALKING,
            existingPoints = listOf(anchor()), existingDistanceMeters = 100.0,
            bridgeInterruptedGap = false))
        val update = o.accept(fix(40.501, -3.900, t0 + 120_000), t0 + 120_000)!!
        assertTrue(update.bridgedPoints.isEmpty())
        assertEquals(100.0, update.distanceMeters, 0.001)
    }

    @Test fun implausibleOrStaleGapNeverCreatesSyntheticRoute() {
        val o = LiveGPSOdometer()
        o.start("s1", t0 + 90_000, LiveSport.WALKING, listOf(anchor()), 0.0, true, 2.8)
        // Salto de 111 km en 90 s: imposible andando.
        assertTrue(o.accept(fix(41.5, -3.9, t0 + 90_000), t0 + 90_000)!!.bridgedPoints.isEmpty())
        val o2 = LiveGPSOdometer()
        o2.start("s2", t0 + 3_600_000, LiveSport.WALKING, listOf(anchor()), 0.0, true, 2.8)
        // Hueco de 1 h: supera el máximo de 30 min.
        assertTrue(o2.accept(fix(40.501, -3.9, t0 + 3_600_000), t0 + 3_600_000)!!.bridgedPoints.isEmpty())
    }

    private fun snapshot(phase: LiveActivityState.Phase, savedAt: Long) =
        LiveActivityState.Snapshot("walking", phase, t0, null, 0.0, 100.0,
            listOf(anchor()), savedAt, null, emptyList(), 0.0, "gps-1")

    @Test fun restoreAutoResumesRecentInterruptedRecording() {
        val s = LiveActivityState()
        assertTrue(s.restore(snapshot(LiveActivityState.Phase.RECORDING, t0 + 600_000), t0 + 610_000))
        assertEquals(LiveActivityState.Phase.RECORDING, s.phase)
        assertTrue(s.needsInterruptedGPSRecovery)
    }

    @Test fun restoreKeepsManualPauseAndOldSnapshotsPaused() {
        val paused = LiveActivityState()
        paused.restore(snapshot(LiveActivityState.Phase.PAUSED, t0 + 600_000), t0 + 610_000)
        assertEquals(LiveActivityState.Phase.PAUSED, paused.phase)
        assertFalse(paused.needsInterruptedGPSRecovery)
        val old = LiveActivityState()
        old.restore(snapshot(LiveActivityState.Phase.RECORDING, t0), t0 + 3 * 60 * 60 * 1000 + 1)
        assertEquals(LiveActivityState.Phase.PAUSED, old.phase)
        assertFalse(old.needsInterruptedGPSRecovery)
        // Compatibilidad: llamadas antiguas sin nowMillis siempre pausan.
        val legacy = LiveActivityState()
        legacy.restore(snapshot(LiveActivityState.Phase.RECORDING, t0 + 600_000))
        assertEquals(LiveActivityState.Phase.PAUSED, legacy.phase)
    }

    @Test fun receiveAppendsBridgedPointsBeforeTheRealFix() {
        val s = LiveActivityState()
        s.restore(snapshot(LiveActivityState.Phase.RECORDING, t0 + 600_000), t0 + 610_000)
        val bridged = listOf(WorkoutRoutePoint(1, 40.5005, -3.9, t0 + 630_000, isEstimated = true))
        val real = WorkoutRoutePoint(2, 40.501, -3.9, t0 + 660_000)
        assertTrue(s.receive("gps-1", real, 250.0, bridged))
        assertEquals(3, s.points.size)
        assertEquals(true, s.points[1].isEstimated)
        assertNull(s.points[2].isEstimated)
        assertEquals(250.0, s.distanceMeters, 0.001)
    }

    @Test fun estimatedRecoveryMetersAccumulatesAndSurvivesSnapshot() {
        // Apple 63905025: total extrapolado sobre huecos, distinto de lo medido.
        val s = LiveActivityState()
        s.restore(snapshot(LiveActivityState.Phase.RECORDING, t0 + 600_000), t0 + 610_000)
        val bridged = listOf(WorkoutRoutePoint(1, 40.5005, -3.9, t0 + 630_000, isEstimated = true))
        val real = WorkoutRoutePoint(2, 40.501, -3.9, t0 + 660_000)
        assertTrue(s.receive("gps-1", real, 250.0, bridged, bridgedDistanceMeters = 150.0))
        assertEquals(150.0, s.estimatedRecoveryMeters, 0.001)
        // Un fix sin bridging no suma nada.
        val next = WorkoutRoutePoint(3, 40.5015, -3.9, t0 + 690_000)
        assertTrue(s.receive("gps-1", next, 300.0))
        assertEquals(150.0, s.estimatedRecoveryMeters, 0.001)
        // Sobrevive al snapshot/restore.
        val snap = s.snapshot(t0 + 700_000)!!
        assertEquals(150.0, snap.estimatedRecoveryMeters, 0.001)
        val r = LiveActivityState()
        assertTrue(r.restore(snap, t0 + 700_000))
        assertEquals(150.0, r.estimatedRecoveryMeters, 0.001)
    }
}
