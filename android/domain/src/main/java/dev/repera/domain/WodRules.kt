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
        EMOM -> "EMOM / Every X'"
        FOR_TIME -> "For Time / RFT"
        TABATA -> "Tabata"
        CHIPPER -> "Chipper"
        DEATH_BY -> "Muerte por"
        STRENGTH -> "Fuerza / Skill"
        AFAP -> "AFAP"
        LADDER -> "Ladder / 21-15-9"
        PARTNER -> "Partner / YGIG"
        BUY_IN_CASH_OUT -> "Buy-in / Cash-out"
        ROUNDS_FOR_QUALITY -> "Rounds for Quality"
        CIRCUIT -> "Circuito"
        MAX_EFFORT -> "Max effort"
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
