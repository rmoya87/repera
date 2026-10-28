package dev.repera.domain

/**
 * Port of CatalogWODs.swift: benchmark WOD templates (Girls, Heroes, Open...)
 * with published score bands. Data mirrors the iOS seed verbatim.
 */
data class WodTemplateMovement(
    val name: String,
    val reps: Int? = null,
    val distanceMeters: Int? = null,
    val calories: Int? = null,
    val weightMaleKg: Double? = null,
    val weightFemaleKg: Double? = null,
    val notes: String? = null
)

data class WodScoreBands(
    val eliteMaxSeconds: Int? = null,
    val advancedMaxSeconds: Int? = null,
    val intermediateMaxSeconds: Int? = null,
    val beginnerMaxSeconds: Int? = null,
    val eliteMinRounds: Double? = null,
    val advancedMinRounds: Double? = null,
    val intermediateMinRounds: Double? = null,
    val beginnerMinRounds: Double? = null
)

data class WodTemplate(
    val id: String,
    val name: String,
    val format: WodFormat,
    val timeCapMinutes: Int? = null,
    val rounds: Int? = null,
    val workSeconds: Int? = null,
    val restSeconds: Int? = null,
    val emomIntervalSeconds: Int? = null,
    val movements: List<WodTemplateMovement>,
    val muscles: List<String>,
    val typicalMinutes: Int? = null,
    val scoreBands: WodScoreBands? = null,
    val notes: String? = null
) {
    val formatLabel: String get() = format.displayName
    val typicalLabel: String? get() = typicalMinutes?.let { "~$it min" }
    val musclesLabel: String get() = muscles.joinToString(" · ")
}

object CatalogWods {
    fun seed(): List<WodTemplate> = all

    fun template(id: String): WodTemplate? = all.firstOrNull { it.id == id }

    fun search(query: String): List<WodTemplate> {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return all
        return all.filter {
            it.name.lowercase().contains(q) ||
                it.format.displayName.lowercase().contains(q) ||
                it.muscles.any { muscle -> muscle.lowercase().contains(q) }
        }
    }

    private fun m(
        name: String,
        reps: Int? = null,
        meters: Int? = null,
        calories: Int? = null,
        male: Double? = null,
        female: Double? = null,
        notes: String? = null
    ) = WodTemplateMovement(name, reps, meters, calories, male, female, notes)

    private val all: List<WodTemplate> = listOf(
        // Girls
        WodTemplate(
            id = "fran",
            name = "Fran",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 10,
            movements = listOf(
                m("Thruster", reps = 21, male = 43.0, female = 29.0),
                m("Dominadas", reps = 21),
                m("Thruster", reps = 15, male = 43.0, female = 29.0),
                m("Dominadas", reps = 15),
                m("Thruster", reps = 9, male = 43.0, female = 29.0),
                m("Dominadas", reps = 9),
            ),
            muscles = listOf("Piernas", "Hombros", "Espalda"),
            typicalMinutes = 5,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 3 * 60,
                advancedMaxSeconds = 5 * 60,
                intermediateMaxSeconds = 8 * 60,
                beginnerMaxSeconds = 10 * 60
            ),
            notes = "21-15-9 thrusters + pull-ups"
        ),
        WodTemplate(
            id = "cindy",
            name = "Cindy",
            format = WodFormat.AMRAP,
            timeCapMinutes = 20,
            movements = listOf(
                m("Dominadas", reps = 5),
                m("Flexiones", reps = 10),
                m("Air squat", reps = 15),
            ),
            muscles = listOf("Espalda", "Pecho", "Piernas"),
            typicalMinutes = 20,
            scoreBands = WodScoreBands(
                eliteMinRounds = 20.0,
                advancedMinRounds = 15.0,
                intermediateMinRounds = 10.0,
                beginnerMinRounds = 6.0
            ),
            notes = "AMRAP 20'"
        ),
        WodTemplate(
            id = "helen",
            name = "Helen",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 15,
            rounds = 3,
            movements = listOf(
                m("Cinta / carrera", meters = 400),
                m("Swing kettlebell", reps = 21, male = 24.0, female = 16.0),
                m("Dominadas", reps = 12),
            ),
            muscles = listOf("Cardio", "Core", "Espalda"),
            typicalMinutes = 10,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 8 * 60,
                advancedMaxSeconds = 10 * 60,
                intermediateMaxSeconds = 13 * 60,
                beginnerMaxSeconds = 15 * 60
            ),
            notes = "3 RFT"
        ),
        WodTemplate(
            id = "grace",
            name = "Grace",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 10,
            movements = listOf(
                m("Cargada y envión", reps = 30, male = 61.0, female = 43.0),
            ),
            muscles = listOf("Piernas", "Hombros", "Espalda"),
            typicalMinutes = 3,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 90,
                advancedMaxSeconds = 3 * 60,
                intermediateMaxSeconds = 5 * 60,
                beginnerMaxSeconds = 10 * 60
            ),
            notes = "30 clean & jerk"
        ),
        WodTemplate(
            id = "isabel",
            name = "Isabel",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 10,
            movements = listOf(
                m("Arrancada", reps = 30, male = 61.0, female = 43.0),
            ),
            muscles = listOf("Piernas", "Hombros", "Espalda"),
            typicalMinutes = 3,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 90,
                advancedMaxSeconds = 3 * 60,
                intermediateMaxSeconds = 5 * 60,
                beginnerMaxSeconds = 10 * 60
            ),
            notes = "30 snatches"
        ),
        WodTemplate(
            id = "annie",
            name = "Annie",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 12,
            movements = listOf(
                m("Dobles de comba", reps = 50),
                m("Sit-up", reps = 50),
                m("Dobles de comba", reps = 40),
                m("Sit-up", reps = 40),
                m("Dobles de comba", reps = 30),
                m("Sit-up", reps = 30),
                m("Dobles de comba", reps = 20),
                m("Sit-up", reps = 20),
                m("Dobles de comba", reps = 10),
                m("Sit-up", reps = 10),
            ),
            muscles = listOf("Cardio", "Core"),
            typicalMinutes = 8,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 5 * 60,
                advancedMaxSeconds = 7 * 60,
                intermediateMaxSeconds = 10 * 60,
                beginnerMaxSeconds = 12 * 60
            ),
            notes = "50-40-30-20-10 DU + sit-ups"
        ),
        WodTemplate(
            id = "karen",
            name = "Karen",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 15,
            movements = listOf(
                m("Wall ball", reps = 150, male = 9.0, female = 6.0),
            ),
            muscles = listOf("Piernas", "Hombros", "Core"),
            typicalMinutes = 8,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 5 * 60,
                advancedMaxSeconds = 7 * 60,
                intermediateMaxSeconds = 10 * 60,
                beginnerMaxSeconds = 15 * 60
            ),
            notes = "150 wall balls"
        ),
        WodTemplate(
            id = "diane",
            name = "Diane",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 12,
            movements = listOf(
                m("Peso muerto", reps = 21, male = 102.0, female = 70.0),
                m("HSPU", reps = 21),
                m("Peso muerto", reps = 15, male = 102.0, female = 70.0),
                m("HSPU", reps = 15),
                m("Peso muerto", reps = 9, male = 102.0, female = 70.0),
                m("HSPU", reps = 9),
            ),
            muscles = listOf("Espalda", "Hombros", "Core"),
            typicalMinutes = 6,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 4 * 60,
                advancedMaxSeconds = 6 * 60,
                intermediateMaxSeconds = 9 * 60,
                beginnerMaxSeconds = 12 * 60
            ),
            notes = "21-15-9 deadlift + HSPU"
        ),
        WodTemplate(
            id = "chelsea",
            name = "Chelsea",
            format = WodFormat.EMOM,
            timeCapMinutes = 30,
            emomIntervalSeconds = 60,
            movements = listOf(
                m("Dominadas", reps = 5),
                m("Flexiones", reps = 10),
                m("Air squat", reps = 15),
            ),
            muscles = listOf("Espalda", "Pecho", "Piernas"),
            typicalMinutes = 30,
            notes = "EMOM 30' · 5/10/15"
        ),
        WodTemplate(
            id = "barbara",
            name = "Barbara",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 40,
            rounds = 5,
            movements = listOf(
                m("Dominadas", reps = 20),
                m("Flexiones", reps = 30),
                m("Sit-up", reps = 40),
                m("Air squat", reps = 50),
            ),
            muscles = listOf("Espalda", "Pecho", "Core", "Piernas"),
            typicalMinutes = 30,
            notes = "5 rounds · 3' rest entre rondas"
        ),
        WodTemplate(
            id = "angie",
            name = "Angie",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 30,
            movements = listOf(
                m("Dominadas", reps = 100),
                m("Flexiones", reps = 100),
                m("Sit-up", reps = 100),
                m("Air squat", reps = 100),
            ),
            muscles = listOf("Espalda", "Pecho", "Core", "Piernas"),
            typicalMinutes = 20,
            notes = "100 de cada"
        ),
        WodTemplate(
            id = "nancy",
            name = "Nancy",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 20,
            rounds = 5,
            movements = listOf(
                m("Cinta / carrera", meters = 400),
                m("Overhead squat", reps = 15, male = 43.0, female = 29.0),
            ),
            muscles = listOf("Cardio", "Piernas", "Hombros"),
            typicalMinutes = 14,
            notes = "5 RFT"
        ),
        WodTemplate(
            id = "jackie",
            name = "Jackie",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 15,
            movements = listOf(
                m("Remo", meters = 1000),
                m("Thruster", reps = 50, male = 20.0, female = 15.0),
                m("Dominadas", reps = 30),
            ),
            muscles = listOf("Cardio", "Piernas", "Espalda"),
            typicalMinutes = 10,
            notes = "1000m row + 50 thrusters + 30 pull-ups"
        ),
        WodTemplate(
            id = "linda",
            name = "Linda",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 30,
            movements = listOf(
                m("Peso muerto", reps = 10, male = null, female = null, notes = "1.5× BW"),
                m("Press banca", reps = 10, notes = "BW"),
                m("Cargada", reps = 10, notes = "0.75× BW"),
                m("Peso muerto", reps = 9, notes = "1.5× BW"),
                m("Press banca", reps = 9, notes = "BW"),
                m("Cargada", reps = 9, notes = "0.75× BW"),
            ),
            muscles = listOf("Espalda", "Pecho", "Piernas"),
            typicalMinutes = 20,
            notes = "10-9-…-1 DL / bench / clean"
        ),
        WodTemplate(
            id = "mary",
            name = "Mary",
            format = WodFormat.AMRAP,
            timeCapMinutes = 20,
            movements = listOf(
                m("HSPU", reps = 5),
                m("Pistol squat", reps = 10),
                m("Dominadas", reps = 15),
            ),
            muscles = listOf("Hombros", "Piernas", "Espalda"),
            typicalMinutes = 20
        ),
        WodTemplate(
            id = "amanda",
            name = "Amanda",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 12,
            movements = listOf(
                m("Muscle-up anulllas", reps = 9),
                m("Arrancada", reps = 9, male = 61.0, female = 43.0),
                m("Muscle-up anulllas", reps = 7),
                m("Arrancada", reps = 7, male = 61.0, female = 43.0),
                m("Muscle-up anulllas", reps = 5),
                m("Arrancada", reps = 5, male = 61.0, female = 43.0),
            ),
            muscles = listOf("Espalda", "Hombros", "Piernas"),
            typicalMinutes = 7,
            notes = "9-7-5 muscle-up + snatch"
        ),
        WodTemplate(
            id = "kelly",
            name = "Kelly",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 30,
            rounds = 5,
            movements = listOf(
                m("Cinta / carrera", meters = 400),
                m("Salto al cajón", reps = 30),
                m("Wall ball", reps = 30, male = 9.0, female = 6.0),
            ),
            muscles = listOf("Cardio", "Piernas", "Hombros"),
            typicalMinutes = 22,
            notes = "5 RFT"
        ),
        WodTemplate(
            id = "elizabeth",
            name = "Elizabeth",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 12,
            movements = listOf(
                m("Cargada", reps = 21, male = 61.0, female = 43.0),
                m("Fondos en anulllas", reps = 21),
                m("Cargada", reps = 15, male = 61.0, female = 43.0),
                m("Fondos en anulllas", reps = 15),
                m("Cargada", reps = 9, male = 61.0, female = 43.0),
                m("Fondos en anulllas", reps = 9),
            ),
            muscles = listOf("Piernas", "Pecho", "Tríceps"),
            typicalMinutes = 7,
            notes = "21-15-9 clean + ring dips"
        ),

        // Heroes / classics
        WodTemplate(
            id = "murph",
            name = "Murph",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 60,
            movements = listOf(
                m("Cinta / carrera", meters = 1600),
                m("Dominadas", reps = 100),
                m("Flexiones", reps = 200),
                m("Air squat", reps = 300),
                m("Cinta / carrera", meters = 1600),
            ),
            muscles = listOf("Cardio", "Espalda", "Pecho", "Piernas"),
            typicalMinutes = 45,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 35 * 60,
                advancedMaxSeconds = 45 * 60,
                intermediateMaxSeconds = 55 * 60,
                beginnerMaxSeconds = 60 * 60
            ),
            notes = "Chaleco 9/6 kg opcional · partición 20 rondas 5/10/15"
        ),
        WodTemplate(
            id = "dt",
            name = "DT",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 15,
            rounds = 5,
            movements = listOf(
                m("Peso muerto", reps = 12, male = 70.0, female = 48.0),
                m("Hang power clean", reps = 9, male = 70.0, female = 48.0),
                m("Push jerk", reps = 6, male = 70.0, female = 48.0),
            ),
            muscles = listOf("Espalda", "Piernas", "Hombros"),
            typicalMinutes = 8,
            scoreBands = WodScoreBands(
                eliteMaxSeconds = 5 * 60,
                advancedMaxSeconds = 7 * 60,
                intermediateMaxSeconds = 10 * 60,
                beginnerMaxSeconds = 15 * 60
            ),
            notes = "5 RFT · 155/105 lb"
        ),
        WodTemplate(
            id = "fight-gone-bad",
            name = "Fight Gone Bad",
            format = WodFormat.AMRAP,
            timeCapMinutes = 17,
            rounds = 3,
            movements = listOf(
                m("Wall ball", reps = null, male = 9.0, female = 6.0, notes = "1' max"),
                m("Sumo deadlift high pull", reps = null, male = 34.0, female = 25.0, notes = "1' max"),
                m("Salto al cajón", reps = null, notes = "1' max"),
                m("Push press", reps = null, male = 34.0, female = 25.0, notes = "1' max"),
                m("Remo", calories = null, notes = "1' max cal"),
            ),
            muscles = listOf("Full body", "Cardio"),
            typicalMinutes = 17,
            notes = "3 rondas · 1' por estación + 1' rest · score = total reps"
        ),
        WodTemplate(
            id = "randy",
            name = "Randy",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 10,
            movements = listOf(
                m("Arrancada de potencia", reps = 75, male = 34.0, female = 25.0),
            ),
            muscles = listOf("Piernas", "Hombros", "Espalda"),
            typicalMinutes = 5,
            notes = "75 power snatches"
        ),
        WodTemplate(
            id = "nate",
            name = "Nate",
            format = WodFormat.AMRAP,
            timeCapMinutes = 20,
            movements = listOf(
                m("Muscle-up anulllas", reps = 2),
                m("HSPU", reps = 4),
                m("Swing kettlebell", reps = 8, male = 32.0, female = 24.0),
            ),
            muscles = listOf("Espalda", "Hombros", "Core"),
            typicalMinutes = 20
        ),
        WodTemplate(
            id = "tommy-v",
            name = "Tommy V",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 25,
            movements = listOf(
                m("Thruster", reps = 21, male = 52.0, female = 34.0),
                m("Toes to bar", reps = 12),
                m("Thruster", reps = 15, male = 52.0, female = 34.0),
                m("Toes to bar", reps = 9),
                m("Thruster", reps = 9, male = 52.0, female = 34.0),
                m("Toes to bar", reps = 6),
            ),
            muscles = listOf("Piernas", "Hombros", "Core"),
            typicalMinutes = 12
        ),

        // Popular / Open-style
        WodTemplate(
            id = "open-12-3",
            name = "Open 12.3",
            format = WodFormat.AMRAP,
            timeCapMinutes = 18,
            movements = listOf(
                m("Salto al cajón", reps = 15),
                m("Push press", reps = 12, male = 52.0, female = 34.0),
                m("Toes to bar", reps = 9),
            ),
            muscles = listOf("Piernas", "Hombros", "Core"),
            typicalMinutes = 18
        ),
        WodTemplate(
            id = "open-13-4",
            name = "Open 13.4",
            format = WodFormat.AMRAP,
            timeCapMinutes = 7,
            movements = listOf(
                m("Cargada", reps = 3, male = 102.0, female = 70.0),
                m("Toes to bar", reps = 3),
            ),
            muscles = listOf("Espalda", "Core", "Piernas"),
            typicalMinutes = 7,
            notes = "Escalera +3 cada ronda"
        ),
        WodTemplate(
            id = "open-14-5",
            name = "Open 14.5",
            format = WodFormat.FOR_TIME,
            timeCapMinutes = 20,
            movements = listOf(
                m("Thruster", reps = 21, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 21),
                m("Thruster", reps = 18, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 18),
                m("Thruster", reps = 15, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 15),
                m("Thruster", reps = 12, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 12),
                m("Thruster", reps = 9, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 9),
                m("Thruster", reps = 6, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 6),
                m("Thruster", reps = 3, male = 43.0, female = 29.0),
                m("Bar facing burpee", reps = 3),
            ),
            muscles = listOf("Piernas", "Hombros", "Cardio"),
            typicalMinutes = 12,
            notes = "21-18-15-12-9-6-3"
        ),
        WodTemplate(
            id = "chipper-classic",
            name = "Chipper clásico",
            format = WodFormat.CHIPPER,
            timeCapMinutes = 25,
            movements = listOf(
                m("Cinta / carrera", meters = 800),
                m("Thruster", reps = 40, male = 43.0, female = 29.0),
                m("Dominadas", reps = 30),
                m("Sit-up", reps = 50),
                m("Dobles de comba", reps = 100),
            ),
            muscles = listOf("Full body", "Cardio"),
            typicalMinutes = 18
        ),
        WodTemplate(
            id = "tabata-something",
            name = "Tabata Something Else",
            format = WodFormat.TABATA,
            timeCapMinutes = 16,
            rounds = 8,
            workSeconds = 20,
            restSeconds = 10,
            movements = listOf(
                m("Dominadas", notes = "4' Tabata"),
                m("Flexiones", notes = "4' Tabata"),
                m("Sit-up", notes = "4' Tabata"),
                m("Air squat", notes = "4' Tabata"),
            ),
            muscles = listOf("Espalda", "Pecho", "Core", "Piernas"),
            typicalMinutes = 16,
            notes = "Score = peor ronda de cada movimiento, sumadas"
        ),
        WodTemplate(
            id = "death-by-burpees",
            name = "Death by Burpees",
            format = WodFormat.DEATH_BY,
            timeCapMinutes = 20,
            movements = listOf(
                m("Burpee", reps = 1, notes = "Min 1: 1 · Min 2: 2 · …"),
            ),
            muscles = listOf("Cardio", "Pecho", "Piernas"),
            typicalMinutes = 12,
            notes = "Hasta fallar el minuto"
        ),
        WodTemplate(
            id = "21-15-9-thruster-bjo",
            name = "21-15-9 Thruster + BJO",
            format = WodFormat.LADDER,
            timeCapMinutes = 12,
            movements = listOf(
                m("Thruster", reps = 21, male = 43.0, female = 29.0),
                m("Box jump over", reps = 21),
                m("Thruster", reps = 15, male = 43.0, female = 29.0),
                m("Box jump over", reps = 15),
                m("Thruster", reps = 9, male = 43.0, female = 29.0),
                m("Box jump over", reps = 9),
            ),
            muscles = listOf("Piernas", "Hombros", "Cardio"),
            typicalMinutes = 7
        ),
    )
}
