package dev.repera.mobile

import dev.repera.domain.LiveSport
import dev.repera.domain.TimerCompletionDetails
import org.junit.Assert.assertEquals
import org.junit.Test

class SessionSummaryTilesBuilderTest {

    private fun titles(
        sport: LiveSport? = null,
        scoreSessionJson: String? = null,
        displayResults: List<String> = emptyList(),
        hasWodBlock: Boolean = false,
        volumeKg: Double? = null,
        timerDetails: TimerCompletionDetails? = null,
        averageHeartRateBpm: Double? = null,
        steps: Int? = null,
        distanceMeters: Double? = null
    ) = SessionSummaryTilesBuilder.tiles(
        durationLabel = "42′",
        sport = sport,
        kcal = 320.0,
        steps = steps,
        averageHeartRateBpm = averageHeartRateBpm,
        distanceMeters = distanceMeters,
        paceOrSpeedLabel = "5:30",
        timerDetails = timerDetails,
        volumeKg = volumeKg,
        scoreSessionJson = scoreSessionJson,
        displayResults = displayResults,
        hasWodBlock = hasWodBlock
    ).map { it.title }

    @Test
    fun programmedWodWithMark_tiempoMarcaKcal() {
        val json = """{"wodResults":[{"format":"forTime","elapsedSeconds":754}]}"""
        assertEquals(listOf("Tiempo", "Marca", "Kcal"), titles(scoreSessionJson = json))
        assertEquals(
            "12:34",
            SessionSummaryTilesBuilder.tiles(
                durationLabel = "42′",
                sport = null,
                scoreSessionJson = json
            )[1].value
        )
    }

    @Test
    fun programmedEmomWithoutNumericMark_stillMarcaNotVolumen() {
        // EMOM: per-movement sets → wodResults vacíos o sin elapsed/reps.
        assertEquals(
            listOf("Tiempo", "Marca", "Kcal"),
            titles(hasWodBlock = true, volumeKg = 1120.0)
        )
        val json = """{"wodResults":[{"format":"emom"}],"exercises":[{"blockKind":"wod","loggedSets":[]}]}"""
        assertEquals(listOf("Tiempo", "Marca", "Kcal"), titles(scoreSessionJson = json, volumeKg = 1120.0))
    }

    @Test
    fun programmedForce_tiempoKcalVolumen() {
        assertEquals(
            listOf("Tiempo", "Kcal", "Volumen"),
            titles(volumeKg = 4500.0)
        )
    }

    @Test
    fun programmedMarkFromDisplayResults() {
        assertEquals(
            listOf("Tiempo", "Marca", "Kcal"),
            titles(displayResults = listOf("AMRAP · 3 rondas + 45 reps"))
        )
        assertEquals(
            "3+45",
            SessionSummaryTilesBuilder.compactWodMarkFromDisplayResults(
                listOf("AMRAP · 3 rondas + 45 reps")
            )
        )
    }

    @Test
    fun gpsRunning_tiempoDistanciaRitmo() {
        assertEquals(
            listOf("Tiempo", "Distancia", "Ritmo"),
            titles(sport = LiveSport.RUNNING, distanceMeters = 5000.0)
        )
    }

    @Test
    fun gpsCycling_tiempoDistanciaVelMedia() {
        assertEquals(
            listOf("Tiempo", "Distancia", "Vel. media"),
            titles(sport = LiveSport.CYCLING, distanceMeters = 20000.0)
        )
    }

    @Test
    fun padel_tiempoKcalPasos() {
        assertEquals(
            listOf("Tiempo", "Kcal", "Pasos"),
            titles(sport = LiveSport.PADEL, steps = 4200)
        )
    }

    @Test
    fun yoga_tiempoKcalFc() {
        assertEquals(
            listOf("Tiempo", "Kcal", "FC media"),
            titles(sport = LiveSport.YOGA, averageHeartRateBpm = 95.0)
        )
    }

    @Test
    fun hiitWithHr_tiempoKcalFc() {
        assertEquals(
            listOf("Tiempo", "Kcal", "FC media"),
            titles(sport = LiveSport.HIIT, averageHeartRateBpm = 148.0)
        )
    }

    @Test
    fun hiitWithoutHr_tiempoKcalPasos() {
        assertEquals(
            listOf("Tiempo", "Kcal", "Pasos"),
            titles(sport = LiveSport.HIIT, steps = 1800)
        )
    }

    @Test
    fun swimmingWithDistance_tiempoKcalDistancia() {
        assertEquals(
            listOf("Tiempo", "Kcal", "Distancia"),
            titles(sport = LiveSport.SWIMMING, distanceMeters = 1500.0)
        )
    }

    @Test
    fun timerIntervals_tiempoModalidadRondas() {
        assertEquals(
            listOf("Tiempo", "Modalidad", "Rondas"),
            titles(
                timerDetails = TimerCompletionDetails(
                    modeRaw = "intervals",
                    configuredSeconds = 1200,
                    rounds = 8,
                    workSeconds = 40,
                    restSeconds = 20,
                    countdownSeconds = 3
                )
            )
        )
    }

    @Test
    fun volumeFromLoggedSets() {
        val json = """
            {"wodResults":[],"exercises":[{"blockKind":"strength","loggedSets":[
              {"phase":"work","reps":5,"weightKg":100.0,"isWarmup":false},
              {"phase":"work","reps":5,"weightKg":100.0,"isWarmup":false}
            ]}]}
        """.trimIndent()
        assertEquals(1000.0, SessionSummaryTilesBuilder.volumeKgFromScoreSession(json)!!, 0.01)
    }
}
