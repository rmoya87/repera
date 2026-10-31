package dev.repera.domain

/**
 * Catálogo de deportes "En vivo". Port literal del enum LiveSport
 * (Apps/Repera/Sources/LiveActivityView.swift, referencia Apple 37837401).
 * Los IDs son datos PERSISTIDOS en WorkoutSession, favoritos GPX y sesiones
 * interrumpidas: no se renombran ni se reordenan. `symbol` conserva el
 * nombre SF Symbol de Apple como dato; la UI Android lo mapea a su icono.
 */
enum class LiveSport(val id: String, val title: String, val symbol: String, val group: String) {
    RUNNING("running", "Carrera", "figure.run", "A pie"),
    TRAIL("trail", "Carrera de montaña", "figure.run", "A pie"),
    WALKING("walking", "Caminata", "figure.walk", "A pie"),
    HIKING("hiking", "Senderismo", "figure.hiking", "A pie"),
    CYCLING("cycling", "Ciclismo de carretera", "figure.outdoor.cycle", "Ciclismo"),
    MOUNTAIN_BIKE("mountainBike", "Ciclismo de montaña", "bicycle", "Ciclismo"),
    GRAVEL("gravel", "Bicicleta de gravel", "bicycle", "Ciclismo"),
    CROSSFIT("crossfit", "CrossFit", "figure.cross.training", "Fuerza y fitness"),
    STRENGTH("strength", "Entrenamiento", "figure.strengthtraining.traditional", "Fuerza y fitness"),
    HIIT("hiit", "HIIT", "timer", "Fuerza y fitness"),
    HYROX("hyrox", "HYROX", "figure.run", "Fuerza y fitness"), // ExerciseCategorySymbols.discipline("HYROX") = figure.run,
    TENNIS("tennis", "Tenis", "figure.tennis", "Deportes de raqueta"),
    PADEL("padel", "Pádel", "figure.tennis", "Deportes de raqueta"),
    SURFING("surfing", "Surf", "surfboard", "Deportes acuáticos"),
    SWIMMING("swimming", "Natación", "figure.pool.swim", "Deportes acuáticos"),
    WINDSURFING("windsurfing", "Windsurf", "figure.sailing", "Deportes acuáticos"),
    KITESURFING("kitesurfing", "Kitesurf", "figure.surfing", "Deportes acuáticos"),
    KAYAKING("kayaking", "Kayak", "figure.rower", "Deportes acuáticos"),
    ROWING("rowing", "Remo", "figure.outdoor.rowing", "Deportes acuáticos"),
    CANOEING("canoeing", "Piragua", "oar.2.crossed", "Deportes acuáticos"),
    SAILING("sailing", "Vela", "sailboat", "Deportes acuáticos"),
    GOLF("golf", "Golf", "figure.golf", "Otros deportes"),
    SKIING("skiing", "Esquí alpino", "figure.skiing.downhill", "Deportes de invierno"),
    ICE_SKATING("iceSkating", "Patinaje sobre hielo", "figure.ice.skating", "Deportes de invierno"),
    SNOWBOARDING("snowboarding", "Snowboard", "figure.snowboarding", "Deportes de invierno"),
    CROSS_COUNTRY_SKIING("crossCountrySkiing", "Esquí de fondo", "figure.skiing.crosscountry", "Deportes de invierno"),
    SOCCER("soccer", "Fútbol", "figure.indoor.soccer", "Deportes de equipo"),
    BASKETBALL("basketball", "Baloncesto", "figure.basketball", "Deportes de equipo"),
    VOLLEYBALL("volleyball", "Voleibol", "figure.volleyball", "Deportes de equipo"),
    CLIMBING("climbing", "Escalada", "figure.climbing", "Otros deportes"),
    DANCE("dance", "Baile", "figure.dance", "Otros deportes"),
    PILATES("pilates", "Pilates", "figure.pilates", "Otros deportes"),
    SKATEBOARDING("skateboarding", "Skateboard", "figure.skating", "Otros deportes"),
    BOXING("boxing", "Boxeo", "figure.boxing", "Combate"),
    KICKBOXING("kickboxing", "Kickboxing", "figure.kickboxing", "Combate"),
    MARTIAL_ARTS("martialArts", "Artes marciales", "figure.martial.arts", "Combate"),
    WRESTLING("wrestling", "Lucha", "figure.wrestling", "Combate"),
    BADMINTON("badminton", "Bádminton", "figure.badminton", "Deportes de raqueta"),
    PICKLEBALL("pickleball", "Pickleball", "figure.pickleball", "Deportes de raqueta"),
    SQUASH("squash", "Squash", "figure.squash", "Deportes de raqueta"),
    FUNCTIONAL_STRENGTH("functionalStrength", "Fuerza funcional", "dumbbell", "Cardio y gimnasio"),
    CORE_TRAINING("coreTraining", "Core", "figure.core.training", "Cardio y gimnasio"),
    /** Legacy: fuera del picker; sesiones antiguas / Health Connect. */
    ELLIPTICAL("elliptical", "Elíptica", "figure.mixed.cardio", "Cardio y gimnasio"),
    /** Legacy: fuera del picker. */
    STAIR_CLIMBING("stairClimbing", "Subida de escaleras", "figure.mixed.cardio", "Cardio y gimnasio"),
    AMERICAN_FOOTBALL("americanFootball", "Fútbol americano", "figure.american.football", "Deportes de equipo"),
    BASEBALL("baseball", "Béisbol", "figure.baseball", "Deportes de equipo"),
    /** Legacy: fuera del picker. */
    SOFTBALL("softball", "Sóftbol", "figure.baseball", "Deportes de equipo"),
    HOCKEY("hockey", "Hockey", "figure.field.hockey", "Deportes de equipo"),
    LACROSSE("lacrosse", "Lacrosse", "figure.lacrosse", "Deportes de equipo"),
    RUGBY("rugby", "Rugby", "figure.rugby", "Deportes de equipo"),
    YOGA("yoga", "Yoga", "figure.yoga", "Otros deportes"),
    MOBILITY("mobility", "Movilidad", "figure.flexibility", "Otros deportes"),
    OTHER("other", "Otra actividad", "figure.mixed.cardio", "Otros deportes");

    /** Gravel y «Otra» siguen; elíptica / escaleras / sóftbol no salen en Comenzar. */
    val isSelectable: Boolean
        get() = when (this) {
            ELLIPTICAL, STAIR_CLIMBING, SOFTBALL -> false
            else -> true
        }

    /** Clave de tipo de actividad (misma que usa HealthMuscleMapper); espejo de LiveSport.healthType de Apple. */
    val healthKey: String
        get() = when (this) {
            RUNNING, TRAIL -> "running"
            CYCLING, MOUNTAIN_BIKE, GRAVEL -> "cycling"
            WALKING -> "walking"
            HIKING -> "hiking"
            CROSSFIT, HYROX -> "crossTraining"
            STRENGTH -> "traditionalStrengthTraining"
            FUNCTIONAL_STRENGTH -> "functionalStrengthTraining"
            CORE_TRAINING -> "coreTraining"
            ELLIPTICAL -> "elliptical"
            STAIR_CLIMBING -> "stairClimbing"
            HIIT -> "highIntensityIntervalTraining"
            TENNIS, PADEL -> "tennis"
            BADMINTON -> "badminton"
            PICKLEBALL -> "pickleball"
            SQUASH -> "squash"
            SURFING, WINDSURFING, KITESURFING -> "surfingSports"
            SWIMMING -> "swimming"
            KAYAKING, CANOEING -> "paddleSports"
            ROWING -> "rowing"
            SAILING -> "sailing"
            GOLF -> "golf"
            SKIING -> "downhillSkiing"
            ICE_SKATING, SKATEBOARDING -> "skatingSports"
            SNOWBOARDING -> "snowboarding"
            CROSS_COUNTRY_SKIING -> "crossCountrySkiing"
            SOCCER -> "soccer"
            BASKETBALL -> "basketball"
            VOLLEYBALL -> "volleyball"
            AMERICAN_FOOTBALL -> "americanFootball"
            BASEBALL -> "baseball"
            SOFTBALL -> "softball"
            HOCKEY -> "hockey"
            LACROSSE -> "lacrosse"
            RUGBY -> "rugby"
            BOXING -> "boxing"
            KICKBOXING -> "kickboxing"
            MARTIAL_ARTS -> "martialArts"
            WRESTLING -> "wrestling"
            CLIMBING -> "climbing"
            DANCE -> "dance"
            PILATES -> "pilates"
            YOGA -> "yoga"
            MOBILITY -> "flexibility"
            OTHER -> "other"
        }

    /** GPS únicamente para modalidades con recorrido exterior verificable.
     *  Ni la piscina, las pistas ni la escalada interior fabrican distancia. */
    val usesGPS: Boolean
        get() = when (this) {
            RUNNING, CYCLING, WALKING, HIKING, TRAIL, MOUNTAIN_BIKE,
            GRAVEL, SURFING, WINDSURFING, KITESURFING, KAYAKING,
            ROWING, CANOEING, SAILING, GOLF, SKIING,
            SNOWBOARDING, CROSS_COUNTRY_SKIING, SKATEBOARDING -> true
            else -> false
        }

    /** Apple LiveSport.isWaterSport (live main): selects the water palette of the speed trace. */
    val isWaterSport: Boolean
        get() = this in setOf(SURFING, SWIMMING, WINDSURFING, KITESURFING, KAYAKING, ROWING, CANOEING, SAILING)
    val isCycling: Boolean
        get() = this == CYCLING || this == MOUNTAIN_BIKE || this == GRAVEL

    /** Velocidad (km/h) en lugar de ritmo (min/km) para deportes rápidos. */
    val displaysSpeed: Boolean
        get() = when (this) {
            CYCLING, MOUNTAIN_BIKE, GRAVEL, SURFING, WINDSURFING,
            KITESURFING, KAYAKING, ROWING, CANOEING, SAILING,
            GOLF, SKIING, SNOWBOARDING, CROSS_COUNTRY_SKIING, SKATEBOARDING -> true
            else -> false
        }

    /** Elevación y vel. mín/media/máx en ficha (paridad iOS showsElevationAndSpeedStats). */
    val showsElevationAndSpeedStats: Boolean
        get() = when (this) {
            WALKING, HIKING,
            CYCLING, MOUNTAIN_BIKE, GRAVEL,
            SKIING, SNOWBOARDING, SURFING, SKATEBOARDING -> true
            else -> false
        }

    /** Solo calcular desnivel cuando la actividad tiene sentido en pendiente. */
    val tracksElevation: Boolean get() = showsElevationAndSpeedStats

    /** Pádel/tenis/raqueta: tiles Tiempo · Kcal · Pasos. */
    val usesRacketSummaryTiles: Boolean
        get() = this in setOf(TENNIS, PADEL, BADMINTON, PICKLEBALL, SQUASH)

    /** Equipo / combate / raqueta: Tiempo · Kcal · Pasos. */
    val usesStepsKcalSummaryTiles: Boolean
        get() = usesRacketSummaryTiles || this in setOf(
            SOCCER, BASKETBALL, VOLLEYBALL, AMERICAN_FOOTBALL, BASEBALL,
            SOFTBALL, HOCKEY, LACROSSE, RUGBY,
            BOXING, KICKBOXING, MARTIAL_ARTS, WRESTLING
        )

    /** Indoor suave: Tiempo · Kcal · FC. */
    val usesHeartRateSummaryTiles: Boolean
        get() = this in setOf(YOGA, PILATES, MOBILITY, DANCE, CORE_TRAINING)

    /** HIIT / CrossFit / HYROX / fuerza Comenzar: Tiempo · Kcal · FC|Pasos. */
    val usesFitnessClassSummaryTiles: Boolean
        get() = this in setOf(HIIT, CROSSFIT, HYROX, STRENGTH, FUNCTIONAL_STRENGTH)

    /** Un salto medio tras un cierre debe ser razonable para el deporte.
     *  No usar el límite más permisivo de picos GPS reales. (Apple 0a640da8) */
    val recoveryMaximumSpeedMps: Double
        get() = when (this) {
            WALKING, HIKING, GOLF -> 2.8
            RUNNING, TRAIL -> 7.5
            CYCLING, MOUNTAIN_BIKE, GRAVEL -> 20.0
            SKIING, SNOWBOARDING, WINDSURFING, KITESURFING -> 35.0
            else -> minOf(12.0, maxGPSMetersPerSecond)
        }

    /** Evita descartar las muestras auténticas de deportes rápidos como
     *  kitesurf y esquí, manteniendo el filtro de saltos GPS. */
    val maxGPSMetersPerSecond: Double
        get() = when (this) {
            SKIING, SNOWBOARDING -> 50.0
            WINDSURFING, KITESURFING, SAILING -> 42.0
            CROSS_COUNTRY_SKIING, SKATEBOARDING -> 24.0
            CYCLING, MOUNTAIN_BIKE, GRAVEL -> 22.0
            else -> 12.0
        }

    /** Las métricas de sensores se muestran únicamente cuando existen datos
     *  reales en Salud, nunca como un contador simulado. */
    val metricDescription: String
        get() = if (usesGPS) {
            val motion = if (displaysSpeed) "velocidad" else "ritmo"
            if (tracksElevation) "Tiempo · distancia · $motion · desnivel GPS"
            else "Tiempo · distancia · $motion"
        } else "Tiempo · pulso y calorías si están disponibles"

    companion object {
        /** Orden de grupos tal como Apple lo presenta en el picker. */
        val groups: List<String> = listOf(
            "A pie", "Ciclismo", "Fuerza y fitness", "Deportes de raqueta",
            "Deportes acuáticos", "Deportes de invierno", "Deportes de equipo",
            "Combate", "Cardio y gimnasio", "Otros deportes"
        )

        val selectableCases: List<LiveSport>
            get() {
                val collator = java.text.Collator.getInstance(java.util.Locale("es"))
                return entries.filter { it.isSelectable }.sortedWith { a, b ->
                    if (a == OTHER) return@sortedWith 1
                    if (b == OTHER) return@sortedWith -1
                    val result = collator.compare(a.title, b.title)
                    if (result == 0) a.id.compareTo(b.id) else result
                }
            }

        fun byId(id: String): LiveSport? = entries.firstOrNull { it.id == id }

        /**
         * Deportes que representan tiempo cardio real en Progreso
         * (StatsEngine.cardioLiveSports de Apple). No fabrican kcal, FC ni
         * carga muscular. Incluye ids legacy (elíptica / escaleras / sóftbol).
         */
        val cardioLiveSports: Set<String> = setOf(
            "running", "cycling", "walking", "hiking", "trail", "mountainBike",
            "gravel", "tennis", "padel", "surfing", "swimming", "skiing",
            "windsurfing", "kitesurfing", "kayaking", "rowing", "canoeing",
            "sailing", "iceSkating", "snowboarding", "crossCountrySkiing",
            "soccer", "basketball", "volleyball", "climbing", "dance",
            "skateboarding", "hiit", "hyrox", "crossfit",
            "boxing", "kickboxing", "martialArts", "wrestling",
            "badminton", "pickleball", "squash",
            "elliptical", "stairClimbing",
            "americanFootball", "baseball", "softball",
            "hockey", "lacrosse", "rugby"
        )
    }
}
