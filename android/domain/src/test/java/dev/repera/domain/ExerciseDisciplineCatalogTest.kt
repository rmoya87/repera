package dev.repera.domain

import org.json.JSONArray
import org.junit.Assert.*
import org.junit.Test

/** Espejo de CatalogQualityTests + ExerciseDisciplineTagsTests de Apple (bd4d7637)
 *  contra el seed real empaquetado (mismo contenido verificado vs extracción bd4
 *  por android/tools/check_catalog_parity.py). */
class ExerciseDisciplineCatalogTest {

    private val seed: JSONArray by lazy {
        JSONArray(javaClass.classLoader!!.getResource("catalog_seed_288.json")!!.readText())
    }

    private data class Row(val name: String, val sportTag: String?, val muscleGroup: String)

    private val rows: List<Row> by lazy {
        (0 until seed.length()).map { i ->
            val o = seed.getJSONObject(i)
            Row(o.getString("name"), o.optString("sportTag").takeIf { it.isNotBlank() }, o.optString("muscleGroup"))
        }
    }

    private fun tags(r: Row) =
        ExerciseDisciplineTags.forExercise(r.name, r.sportTag, r.muscleGroup, HyroxExercises.isMovement(r.name))

    @Test fun seedSizeMatchesApple() {
        assertEquals(289, rows.size)  // seed actual: 288 + «Burpee to target»
    }

    @Test fun allWeightliftingIsCrossFitCompatible() {
        val w = rows.filter { it.sportTag == "Halterofilia" }
        assertEquals(48, w.size)
        assertTrue(w.all { "CrossFit" in tags(it) })
    }

    @Test fun allGymnasticsIsCrossFitCompatible() {
        val g = rows.filter { it.sportTag == "Gimnasia" }
        assertEquals(58, g.size)
        assertTrue(g.all { "CrossFit" in tags(it) })
    }

    @Test fun hyroxCompetitionStationsPresentAndTagged() {
        assertEquals(9, HyroxExercises.competitionStations.size)
        val byName = rows.associateBy { it.name }
        for (station in HyroxExercises.competitionStations) {
            val r = byName[station]
            assertNotNull("Falta estación de HYROX: $station", r)
            assertTrue(station, "HYROX" in tags(r!!))
        }
        assertEquals(11, rows.count { "HYROX" in tags(it) })
    }

    @Test fun knownTagAssignments() {
        val byName = rows.associateBy { it.name }
        assertEquals(listOf("CrossFit", "HYROX"), tags(byName.getValue("Wall ball")))
        assertEquals(listOf("Movilidad"), tags(byName.getValue("Gato-vaca")))
        assertTrue("Cardio" in tags(byName.getValue("Remo máquina")))
        assertTrue(tags(byName.getValue("Prensa")).isEmpty())
        assertFalse(HyroxExercises.isMovement("Burpee box jump over"))
        assertFalse(HyroxExercises.isMovement("Remo con barra"))
    }

    @Test fun noDuplicateDisciplinesAnywhere() {
        for (r in rows) {
            val t = tags(r)
            assertEquals("${r.name}: $t", t.size, t.toSet().size)
        }
    }
}
