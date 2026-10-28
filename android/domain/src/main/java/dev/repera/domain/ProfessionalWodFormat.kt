package dev.repera.domain

/** ReperaStore.professionalWorkoutForWatchToday's explicit wire aliases. */
object ProfessionalWodFormat {
    fun normalize(raw:String):String = when(raw.lowercase().replace("_","")) {
        "rft","fortime" -> "forTime"
        "emom","every" -> "emom"
        "amrap" -> "amrap"
        "tabata" -> "tabata"
        "chipper" -> "chipper"
        "circuit" -> "circuit"
        "ladder" -> "ladder"
        "strength" -> "strength"
        else -> raw
    }
}
