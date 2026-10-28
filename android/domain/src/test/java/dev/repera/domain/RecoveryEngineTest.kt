package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class RecoveryEngineTest {

    private val today = LocalDate.of(2026, 6, 15)

    @Test
    fun `sleep index relativo al objetivo`() {
        // 8h con media 8h -> objetivo 8 -> 100.
        assertEquals(100, RecoveryEngine.sleepIndex(8.0, 8.0))
        // 4h -> 50.
        assertEquals(50, RecoveryEngine.sleepIndex(4.0, 8.0))
        // Media no válida -> objetivo 8 por defecto.
        assertEquals(100, RecoveryEngine.sleepIndex(8.0, null))
        // Sin horas -> null.
        assertNull(RecoveryEngine.sleepIndex(null, 8.0))
        assertNull(RecoveryEngine.sleepIndex(0.0, 8.0))
        // Objetivo mínimo 7: media 6h -> target 7 -> 7h = 100.
        assertEquals(100, RecoveryEngine.sleepIndex(7.0, 6.0))
    }

    @Test
    fun `vital context sin 7 dias no calibra`() {
        val history = (1..6).map {
            RecoveryEngine.DailyVitals(today.minusDays(it.toLong()),
                hrvMilliseconds = 60.0, restingHeartRateBpm = 55.0)
        } + RecoveryEngine.DailyVitals(today,
            hrvMilliseconds = 30.0, restingHeartRateBpm = 70.0)
        val ctx = RecoveryEngine.vitalContext(today, history)
        assertEquals(0, ctx.calibratedSignals)
        assertEquals(0.0, ctx.penalty, 1e-9)
        assertTrue(ctx.notes.isEmpty())
    }

    @Test
    fun `vital context penaliza VFC baja y pulso alto`() {
        val history = (1..8).map {
            RecoveryEngine.DailyVitals(today.minusDays(it.toLong()),
                hrvMilliseconds = 60.0, restingHeartRateBpm = 55.0,
                respiratoryRateBpm = 14.0)
        } + RecoveryEngine.DailyVitals(today,
            hrvMilliseconds = 40.0,          // < 70% de 60 -> +0.9
            restingHeartRateBpm = 66.0,      // +11 sobre 55 -> +0.85
            respiratoryRateBpm = 14.0)       // sin cambio
        val ctx = RecoveryEngine.vitalContext(today, history)
        assertEquals(3, ctx.calibratedSignals)
        assertEquals(1.75, ctx.penalty, 1e-9)
        assertEquals(2, ctx.notes.size)
        assertTrue(ctx.notes.any { it.contains("VFC considerablemente") })
        assertTrue(ctx.notes.any { it.contains("Pulso en reposo claramente") })
    }

    @Test
    fun `vital context respeta tope de penalizacion`() {
        // VFC muy baja (0.9) + pulso alto (0.85) + respiracion alta (0.4) = 2.15 -> 1.8.
        val history = (1..8).map {
            RecoveryEngine.DailyVitals(today.minusDays(it.toLong()),
                hrvMilliseconds = 60.0, restingHeartRateBpm = 55.0,
                respiratoryRateBpm = 14.0)
        } + RecoveryEngine.DailyVitals(today,
            hrvMilliseconds = 35.0, restingHeartRateBpm = 70.0,
            respiratoryRateBpm = 20.0)
        val ctx = RecoveryEngine.vitalContext(today, history)
        assertEquals(1.8, ctx.penalty, 1e-9)
    }

    @Test
    fun `readiness sin sueno no estima`() {
        assertNull(RecoveryEngine.trainingReadiness(
            nowMillis = 0, sleepHours = null, recentAverageSleepHours = null,
            workouts = emptyList()))
    }

    @Test
    fun `readiness noche corta no llega a usual`() {
        // 5h de sueño: score máximo 5 -> consejo rest.
        val now = java.time.ZonedDateTime.of(2026, 6, 15, 10, 0, 0, 0,
            java.time.ZoneId.of("Europe/Madrid")).toInstant().toEpochMilli()
        val yesterday = StatsWorkout(
            epochMillis = now - 20 * 3_600_000, durationMinutes = 50.0,
            exercises = listOf(StatsExercise(
                exerciseId = "press_banca", exerciseName = "Press de banca",
                muscleGroup = "Pecho",
                sets = listOf(StatsSet(reps = 6, weightKg = 100.0, rir = 1.0)))))
        val r = RecoveryEngine.trainingReadiness(nowMillis = now,
            sleepHours = 5.0, recentAverageSleepHours = 8.0,
            workouts = listOf(yesterday))!!
        assertTrue(r.score <= 5.0)
        assertEquals(RecoveryEngine.TrainingReadinessAdvice.REST, r.advice)
    }

    @Test
    fun `readiness sin carga medible no estima`() {
        val now = java.time.ZonedDateTime.of(2026, 6, 15, 10, 0, 0, 0,
            java.time.ZoneId.of("Europe/Madrid")).toInstant().toEpochMilli()
        // Sueño bien pero ninguna actividad en 7 días -> null.
        assertNull(RecoveryEngine.trainingReadiness(nowMillis = now,
            sleepHours = 8.0, recentAverageSleepHours = 8.0,
            workouts = emptyList()))
    }

    @Test
    fun `cycle phase con historial regular`() {
        val starts = listOf(
            LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 29),
            LocalDate.of(2026, 4, 26), LocalDate.of(2026, 5, 24))
        val flowDays = starts.flatMap { listOf(it, it.plusDays(1), it.plusDays(2)) }
        // Ciclo medio 28: un día de flujo registrado es menstrual (sin
        // registros futuros, como exige el guard de iOS).
        assertEquals(RecoveryEngine.CyclePhase.MENSTRUAL,
            RecoveryEngine.cyclePhase(
                flowDays.filter { !it.isAfter(LocalDate.of(2026, 5, 24)) },
                LocalDate.of(2026, 5, 24)))
        // Ovulatorio ~día 14 del ciclo (28-14=14 tras el inicio).
        assertEquals(RecoveryEngine.CyclePhase.OVULATORY,
            RecoveryEngine.cyclePhase(flowDays, LocalDate.of(2026, 6, 7)))
        // Folicular antes, lútea después.
        assertEquals(RecoveryEngine.CyclePhase.FOLLICULAR,
            RecoveryEngine.cyclePhase(flowDays, LocalDate.of(2026, 5, 30)))
        assertEquals(RecoveryEngine.CyclePhase.LUTEAL,
            RecoveryEngine.cyclePhase(flowDays, LocalDate.of(2026, 6, 12)))
    }

    @Test
    fun `cycle phase irregular o escaso es desconocida`() {
        assertEquals(RecoveryEngine.CyclePhase.UNKNOWN,
            RecoveryEngine.cyclePhase(emptyList(), today))
        // Solo dos inicios.
        val two = listOf(LocalDate.of(2026, 4, 26), LocalDate.of(2026, 5, 24))
        assertEquals(RecoveryEngine.CyclePhase.UNKNOWN,
            RecoveryEngine.cyclePhase(two, LocalDate.of(2026, 6, 1)))
        // Intervalos muy variables (>7 de diferencia).
        val wild = listOf(LocalDate.of(2026, 3, 1),
            LocalDate.of(2026, 3, 25), LocalDate.of(2026, 5, 1))
        assertEquals(RecoveryEngine.CyclePhase.UNKNOWN,
            RecoveryEngine.cyclePhase(wild, LocalDate.of(2026, 5, 20)))
    }
}

class SleepCombinerTest {

    private fun at(day: LocalDate, hour: Int, minute: Int = 0): Long =
        day.atTime(hour, minute).atZone(java.time.ZoneId.of("Europe/Madrid"))
            .toInstant().toEpochMilli()

    @Test
    fun `una noche agrupa fases tras medianoche`() {
        // Dormir de 23:00 a 07:00: punto medio 03:00 -> noche del día siguiente.
        val monday = LocalDate.of(2026, 6, 8)
        val tuesday = monday.plusDays(1)
        val samples = listOf(
            SleepStageSample(at(monday, 23), at(tuesday, 1), "LIGHT", "watch"),
            SleepStageSample(at(tuesday, 1), at(tuesday, 3), "DEEP", "watch"),
            SleepStageSample(at(tuesday, 3), at(tuesday, 5), "REM", "watch"),
            SleepStageSample(at(tuesday, 5), at(tuesday, 7), "LIGHT", "watch"))
        val nights = combineSleepNights(samples)
        assertEquals(1, nights.size)
        assertEquals(tuesday, nights[0].day)
        assertEquals(8.0, nights[0].hours, 0.01)
        assertEquals(2.0, nights[0].deepHours, 0.01)
        assertEquals(2.0, nights[0].remHours, 0.01)
    }

    @Test
    fun `intervalos solapados cuentan una vez`() {
        val monday = LocalDate.of(2026, 6, 8)
        val tuesday = monday.plusDays(1)
        val samples = listOf(
            SleepStageSample(at(monday, 23), at(tuesday, 3), "LIGHT", "watch"),
            SleepStageSample(at(tuesday, 1), at(tuesday, 5), "LIGHT", "watch"))
        val nights = combineSleepNights(samples)
        assertEquals(6.0, nights[0].hours, 0.01)
    }

    @Test
    fun `fuente con mas fases especificas gana`() {
        val monday = LocalDate.of(2026, 6, 8)
        val tuesday = monday.plusDays(1)
        // phone: 8h sin fases; watch: 7h con fases -> gana watch.
        val samples = listOf(
            SleepStageSample(at(monday, 23), at(tuesday, 7), "OTRO", "phone"),
            SleepStageSample(at(monday, 23), at(tuesday, 3), "LIGHT", "watch"),
            SleepStageSample(at(tuesday, 3), at(tuesday, 6), "DEEP", "watch"))
        val nights = combineSleepNights(samples)
        assertEquals(7.0, nights[0].hours, 0.01)
        assertEquals(3.0, nights[0].deepHours, 0.01)
    }

    @Test
    fun `noches de menos de 15 minutos se descartan`() {
        val monday = LocalDate.of(2026, 6, 8)
        val tuesday = monday.plusDays(1)
        val samples = listOf(
            SleepStageSample(at(tuesday, 3), at(tuesday, 3, 10), "LIGHT", "watch"))
        assertTrue(combineSleepNights(samples).isEmpty())
    }
}
