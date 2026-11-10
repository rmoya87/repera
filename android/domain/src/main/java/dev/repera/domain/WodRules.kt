package dev.repera.domain

/**
 * Mirrors ReperaDomain.Models WODFormat.resultCapture (2026-10-23).
 * Format naming matches Swift raw values for interchange.
 *
 * Canonical public type for mobile/wear/board-scan. Historical name
 * [WODFormat] is a typealias so both import spellings resolve on the
 * `:domain` classpath (avoids unresolved/inaccessible dual-enum drift).
 */
enum class WodFormat(val wireName: String) {
    AMRAP("amrap"), EMOM("emom"), FOR_TIME("forTime"), TABATA("tabata"),
    CHIPPER("chipper"), DEATH_BY("deathBy"), STRENGTH("strength"),
    AFAP("afap"), LADDER("ladder"), PARTNER("partner"),
    BUY_IN_CASH_OUT("buyInCashOut"), ROUNDS_FOR_QUALITY("roundsForQuality"),
    CIRCUIT("circuit"), MAX_EFFORT("maxEffort");

    /** Board-scan / wire alias of [wireName] (Swift `rawValue`). */
    val raw: String get() = wireName

    val displayName: String get() = when (this) {
        AMRAP -> "AMRAP"
        EMOM -> "EMOM"
        FOR_TIME -> "For Time"
        TABATA -> "Tabata"
        CHIPPER -> "Chipper"
        DEATH_BY -> "Muerte por"
        STRENGTH -> "Fuerza / Skill"
        AFAP -> "AFAP"
        LADDER -> "Escalera"
        PARTNER -> "Partner"
        BUY_IN_CASH_OUT -> "Buy-in / Cash-out"
        ROUNDS_FOR_QUALITY -> "Rounds for Quality"
        CIRCUIT -> "Circuito"
        MAX_EFFORT -> "Max effort"
    }

    /** Paridad iOS `WODFormat.detail` (selector de formato). */
    val detail: String get() = when (this) {
        AMRAP -> "Máximas rondas o repeticiones en un tiempo fijo. Configura el time cap en minutos."
        EMOM -> "Cada minuto (o cada X segundos) haces el trabajo marcado. Configura duración total e intervalo."
        FOR_TIME -> "Completa el trabajo lo antes posible. Configura rondas (RFT) y el time cap en minutos y segundos."
        TABATA -> "Intervalos fijos de trabajo y descanso (clásico 20\"/10\"). Configura trabajo, descanso y rondas."
        CHIPPER -> "Lista larga en una sola pasada, lo más rápido posible. Time cap opcional en minutos."
        DEATH_BY -> "Cada intervalo sumas trabajo hasta fallar. Configura rondas objetivo e intervalo."
        STRENGTH -> "Bloque de fuerza o técnica (series×reps, RPE/RIR). Time cap opcional."
        AFAP -> "Haz el trabajo lo más rápido posible, sin rondas fijas. Time cap opcional."
        LADDER -> "Esquema de reps en escalera o pirámide (21-15-9, 30-20-10, ascendente/descendente). Time cap opcional."
        PARTNER -> "Dos atletas (You Go I Go, sync o reps repartidas). Configura rondas y time cap opcional."
        BUY_IN_CASH_OUT -> "Empieza (buy-in) y/o termina (cash-out) con un trabajo fijo aparte del WOD. Time cap opcional."
        ROUNDS_FOR_QUALITY -> "N rondas priorizando técnica, sin prisa de reloj. Configura rondas y time cap opcional."
        CIRCUIT -> "Estaciones o rotación. Configura duración total e intervalo entre estaciones."
        MAX_EFFORT -> "Buscar un máximo (heavy single, max reps o calorías). Time cap opcional."
    }

    val capture: ResultCapture get() = when (this) {
        AMRAP, DEATH_BY, MAX_EFFORT -> ResultCapture.TOTAL_REPS
        FOR_TIME, CHIPPER, AFAP, LADDER, BUY_IN_CASH_OUT -> ResultCapture.ELAPSED_TIME
        else -> ResultCapture.PER_MOVEMENT_SETS
    }

    companion object {
        fun fromWire(name: String): WodFormat? = entries.firstOrNull { it.wireName == name }
    }
}

enum class ResultCapture { TOTAL_REPS, ELAPSED_TIME, PER_MOVEMENT_SETS }

data class WodBlockScore(
    val blockId: String,
    val format: WodFormat,
    val roundsCompleted: Int? = null,
    val additionalReps: Int? = null,
    val elapsedSeconds: Int? = null
) {
    init {
        require(roundsCompleted == null || roundsCompleted >= 0)
        require(additionalReps == null || additionalReps >= 0)
        require(elapsedSeconds == null || elapsedSeconds >= 0)
        require(
            when (format.capture) {
                ResultCapture.TOTAL_REPS -> elapsedSeconds == null
                ResultCapture.ELAPSED_TIME -> roundsCompleted == null && additionalReps == null
                ResultCapture.PER_MOVEMENT_SETS -> roundsCompleted == null &&
                    additionalReps == null && elapsedSeconds == null
            }
        )
    }
}
