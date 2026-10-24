package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Parseo del wire de athlete_training_programs (AITrainingProgramsStore). */
class AITrainingProgramsStoreTest {

    @Test
    fun parsesProgramsWithPhasesAndLabels() {
        val row = JSONObject()
            .put("id", "p1").put("title", "Fuerza base")
            .put("primary_goal", "Ganar fuerza")
            .put("start_date", "2026-10-26")
            .put("start_time_zone", "Europe/Madrid")
            .put("duration_weeks", 8)
            .put("phases", JSONArray().put(JSONObject()
                .put("title", "Acumulación").put("weeks", 4)
                .put("focus", "Volumen")
                .put("target_sessions_per_week", 4)
                .put("progression_rule", "+2,5 kg/semana")))
            .put("status", "proposed").put("revision", 3)
        val programs = AITrainingProgramsStore.parsePrograms(
            JSONArray().put(row))
        assertEquals(1, programs.size)
        val program = programs[0]
        assertEquals("Fuerza base", program.title)
        assertEquals(8, program.durationWeeks)
        assertEquals("Europe/Madrid", program.startTimeZone)
        assertEquals(3, program.revision)
        assertEquals("Propuesto", program.statusLabel)
        assertEquals(1, program.phases.size)
        assertEquals("Acumulación", program.phases[0].title)
        assertEquals(4, program.phases[0].targetSessionsPerWeek)
    }

    @Test
    fun toleratesMissingOptionalsAndUnknownStatus() {
        val row = JSONObject()
            .put("id", "p2").put("title", "t").put("status", "archived")
        val program = AITrainingProgramsStore.parsePrograms(
            JSONArray().put(row))[0]
        assertNull(program.startTimeZone)
        assertEquals(0, program.phases.size)
        assertEquals("archived", program.statusLabel)
    }
}
