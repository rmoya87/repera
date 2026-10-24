package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId

class WorkoutCSVImporterTest {

    private val zone = ZoneId.of("Europe/Madrid")
    private val catalog = listOf(
        "ex-1" to "Press banca",
        "ex-2" to "Sentadilla"
    )
    private var counter = 0
    private val ids = { "new-${counter++}" }

    @Test
    fun detectsStrongHevyAndUnknown() {
        assertEquals(WorkoutCSVImporter.Source.STRONG,
            WorkoutCSVImporter.detectSource(
                "Date,Workout Name,Exercise Name,Set Order,Weight,Reps"))
        assertEquals(WorkoutCSVImporter.Source.HEVY,
            WorkoutCSVImporter.detectSource(
                "title,start_time,exercise_title,set_index,weight_kg,reps"))
        assertEquals(WorkoutCSVImporter.Source.UNKNOWN,
            WorkoutCSVImporter.detectSource("a,b,c"))
    }

    @Test
    fun strongImportGroupsBySessionAndMatchesAlias() {
        val csv = """
            Date,Workout Name,Exercise Name,Set Order,Weight,Reps,Seconds
            2026-10-20 18:00:00,Empuje,Bench Press (Barbell),1,80,10,0
            2026-10-20 18:00:00,Empuje,Bench Press (Barbell),2,80,8,0
            2026-10-20 18:00:00,Empuje,Shoulder Fly Machine,1,25,12,0
        """.trimIndent()
        val result = WorkoutCSVImporter.parse(csv, catalog, zone, ids)
        assertEquals(WorkoutCSVImporter.Source.STRONG, result.source)
        assertEquals(1, result.workouts.size)
        val workout = result.workouts[0]
        assertEquals("Empuje", workout.title)
        assertEquals(2, workout.exercises.size)
        val bench = workout.exercises.first { it.exercise.id == "ex-1" }
        assertEquals(2, bench.sets.size)
        assertEquals(80.0, bench.sets[0].weightKg!!, 0.0)
        assertEquals(3, result.matchedSets)
        assertEquals(0, result.skippedRows)
        assertEquals(1, result.createdExercises.size)
        assertEquals("Pecho", result.createdExercises[0].muscleGroup)
    }

    @Test
    fun hevyImportParsesDurationRowsAndDecimalComma() {
        val csv = """
            title,start_time,exercise_title,set_index,weight_kg,reps,duration_seconds
            Pierna,2026-10-21 10:00,Squat,0,"92,5",5,0
            Pierna,2026-10-21 10:00,Plank,0,0,0,45
        """.trimIndent()
        val result = WorkoutCSVImporter.parse(csv, catalog, zone, ids)
        assertEquals(WorkoutCSVImporter.Source.HEVY, result.source)
        assertEquals(2, result.matchedSets)
        val squat = result.workouts[0].exercises.first { it.exercise.id == "ex-2" }
        assertEquals(92.5, squat.sets[0].weightKg!!, 0.0)
        val plank = result.workouts[0].exercises.first {
            it.exercise.name == "Plank" }
        assertEquals(45, plank.sets[0].reps)
        assertEquals("Core", plank.exercise.muscleGroup)
    }

    @Test
    fun skipsEmptyRowsAndRowsWithoutWork() {
        val csv = """
            Date,Workout Name,Exercise Name,Set Order,Weight,Reps,Seconds
            2026-10-20 18:00:00,Empuje,,1,80,10,0
            2026-10-20 18:00:00,Empuje,Bench Press,1,80,0,0
            2026-10-20 18:00:00,Empuje,Bench Press,1,80,10,0
        """.trimIndent()
        val result = WorkoutCSVImporter.parse(csv, catalog, zone, ids)
        assertEquals(1, result.matchedSets)
        assertEquals(2, result.skippedRows)
    }

    @Test
    fun quotedFieldsWithCommasSurvive() {
        val csv = "Date,Workout Name,Exercise Name,Set Order,Weight,Reps,Seconds\n" +
            "2026-10-20 18:00:00,\"Empuje, tarde\",Bench Press,1,80,10,0"
        val result = WorkoutCSVImporter.parse(csv, catalog, zone, ids)
        assertEquals("Empuje, tarde", result.workouts[0].title)
    }

    @Test
    fun emptyCsvReturnsEmptyResult() {
        val result = WorkoutCSVImporter.parse("", catalog, zone, ids)
        assertEquals(0, result.workouts.size)
        assertEquals(0, result.matchedSets)
    }
}
