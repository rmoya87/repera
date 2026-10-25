package dev.repera.domain

/**
 * Catálogo de deportes "En vivo". Port literal del enum LiveSport
 * (Apps/Repera/Sources/LiveActivityView.swift, referencia Apple 5890215d).
 * Los IDs son datos PERSISTIDOS en WorkoutSession, favoritos GPX y sesiones
 * interrumpidas: no se renombran ni se reordenan. `symbol` conserva el
 * nombre SF Symbol de Apple como dato; la UI Android lo mapea a su icono.
 */
enum class LiveSport(val id: String, val title: String, val symbol: String, val group: String) {
    RUNNING("running", "Carrera", "figure.run", "A pie"),
    TRAIL("trail", "Carrera de montaña", "figure.run", "A pie"),
    WALKING("walking", "Caminata", "figure.walk", "A pie"),
    HIKING("hiking", "Senderismo", "figure.hiking", "A pie"),
    CYCLING("cycling", "Bicicleta", "bicycle", "Ciclismo"),
    MOUNTAIN_BIKE("mountainBike", "Bicicleta de montaña", "bicycle", "Ciclismo"),
    GRAVEL("gravel", "Bicicleta de gravel", "bicycle", "Ciclismo"),
    CROSSFIT("crossfit", "CrossFit", "figure.cross.training", "Fuerza y fitness"),
    STRENGTH("strength", "Entrenamiento con pesas", "dumbbell", "Fuerza y fitness"),
    HIIT("hiit", "HIIT", "timer", "Fuerza y fitness"),
    HYROX("hyrox", "HYROX", "figure.run", "Fuerza y fitness"), // ExerciseCategorySymbols.discipline("HYROX") = figure.run,
    TENNIS("tennis", "Tenis", "tennis.racket", "Deportes de raqueta"),
    PADEL("padel", "Pádel", "figure.tennis", "Deportes de raqueta"),
    SURFING("surfing", "Surf", "surfboard", "Deportes acuáticos"),
    SWIMMING("swimming", "Natación", "figure.pool.swim", "Deportes acuáticos"),
    WINDSURFING("windsurfing", "Windsurf", "wind", "Deportes acuáticos"),
    KITESURFING("kitesurfing", "Kitesurf", "wind", "Deportes acuáticos"),
    KAYAKING("kayaking", "Kayak", "figure.rower", "Deportes acuáticos"),
    ROWING("rowing", "Remo", "figure.rower", "Deportes acuáticos"),
    CANOEING("canoeing", "Piragua", "figure.rower", "Deportes acuáticos"),
    SAILING("sailing", "Vela", "sailboat", "Deportes acuáticos"),
    GOLF("golf", "Golf", "figure.golf", "Otros deportes"),
    SKIING("skiing", "Esquí alpino", "figure.skiing.downhill", "Deportes de invierno"),
    ICE_SKATING("iceSkating", "Patinaje sobre hielo", "figure.skating", "Deportes de invierno"),
    SNOWBOARDING("snowboarding", "Snowboard", "figure.snowboarding", "Deportes de invierno"),
    CROSS_COUNTRY_SKIING("crossCountrySkiing", "Esquí de fondo", "figure.skiing.crosscountry", "Deportes de invierno"),
    SOCCER("soccer", "Fútbol", "soccerball", "Deportes de equipo"),
    BASKETBALL("basketball", "Baloncesto", "basketball", "Deportes de equipo"),
    VOLLEYBALL("volleyball", "Voleibol", "volleyball", "Deportes de equipo"),
    CLIMBING("climbing", "Escalada", "figure.climbing", "Otros deportes"),
    DANCE("dance", "Baile", "figure.dance", "Otros deportes"),
    PILATES("pilates", "Pilates", "figure.pilates", "Otros deportes"),
    SKATEBOARDING("skateboarding", "Skateboard", "figure.skating", "Otros deportes"),
    YOGA("yoga", "Yoga", "figure.flexibility", "Otros deportes"),
    MOBILITY("mobility", "Movilidad", "figure.flexibility", "Otros deportes"),
    OTHER("other", "Entrenamiento", "figure.mixed.cardio", "Otros deportes");

    companion object {
        /** Orden de grupos tal como Apple lo presenta en el picker. */
        val groups: List<String> = listOf(
            "A pie", "Ciclismo", "Fuerza y fitness", "Deportes de raqueta",
            "Deportes acuáticos", "Deportes de invierno", "Deportes de equipo",
            "Otros deportes"
        )

        fun byId(id: String): LiveSport? = entries.firstOrNull { it.id == id }

        /**
         * Deportes que representan tiempo cardio real en Progreso
         * (StatsEngine.cardioLiveSports de Apple). No fabrican kcal, FC ni
         * carga muscular.
         */
        val cardioLiveSports: Set<String> = setOf(
            "running", "cycling", "walking", "hiking", "trail", "mountainBike",
            "gravel", "tennis", "padel", "surfing", "swimming", "skiing",
            "windsurfing", "kitesurfing", "kayaking", "rowing", "canoeing",
            "sailing", "iceSkating", "snowboarding", "crossCountrySkiing",
            "soccer", "basketball", "volleyball", "climbing", "dance",
            "skateboarding", "hiit", "hyrox"
        )
    }
}
