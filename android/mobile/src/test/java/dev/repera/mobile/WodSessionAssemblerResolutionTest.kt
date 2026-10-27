package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.File

/** cf25922e: al iniciar un WOD programado, los movimientos se re-resuelven con
 *  catalogExercise (oficial > alias publicado > BTT/T2B con respaldo empaquetado). */
class WodSessionAssemblerResolutionTest {
    private fun seed() = JSONArray(File("src/main/assets/catalog_seed.json").readText())
    private fun block(move: JSONObject) = JSONObject().put("id", "b1").put("kind", "wod")
        .put("wodFormat", "forTime").put("movements", JSONArray().put(move))
    private fun catalog(vararg e: JSONObject) = JSONArray(e.toList())
    private fun ex(id: String, name: String, custom: Boolean = false) =
        JSONObject().put("id", id).put("name", name).put("isCustom", custom)
    private fun append(b: JSONObject, c: JSONArray): JSONArray {
        val out = JSONArray()
        WodSessionAssembler.append(b, c, out, seed())
        return out
    }

    @Test fun legacyBttIdResolvesToPackagedOfficialAtSessionStart() {
        val move = JSONObject().put("id", "m1").put("name", "BTt").put("exerciseId", "provisional-uuid").put("reps", 10)
        val out = append(block(move), catalog(ex("provisional-uuid", "BTt", custom = true)))
        val exercise = out.getJSONObject(0).getJSONObject("exercise")
        assertEquals("Burpee to target", exercise.getString("name"))
        assertFalse(exercise.optBoolean("isCustom"))
        assertEquals("m1", out.getJSONObject(0).getString("id")) // id de sesión = id del movimiento, intacto
    }

    @Test fun publishedAliasRepairsStaleMovementIdWithoutTouchingSavedRoutine() {
        val official = ex("off", "Toes to bar").put("searchAliases", JSONArray().put("T2B"))
        val move = JSONObject().put("id", "m2").put("name", "T2B").put("exerciseId", "stale-id").put("reps", 12)
        val out = append(block(move), catalog(official))
        val exercise = out.getJSONObject(0).getJSONObject("exercise")
        assertEquals("off", exercise.getString("id"))
        assertEquals("Toes to bar", exercise.getString("name"))
    }

    @Test fun manualChoiceSurvivesAndUnknownKeepsCanonicalEphemeral() {
        val chosen = ex("chosen", "Sentadilla trasera")
        val move = JSONObject().put("id", "m3").put("name", "Sentadilla trasera").put("exerciseId", "chosen").put("reps", 5)
        val out = append(block(move), catalog(chosen))
        assertEquals("chosen", out.getJSONObject(0).getJSONObject("exercise").getString("id"))
        val unknown = JSONObject().put("id", "m4").put("name", "db hang c&j").put("reps", 8)
        val out2 = append(block(unknown), JSONArray())
        val ephemeral = out2.getJSONObject(0).getJSONObject("exercise")
        // Canónico intermedio (idéntico en ambas plataformas, tree173), no el OCR crudo;
        // sin catálogo, el alias publicado «Dumbbell Clean and Jerk» no puede aplicarse.
        assertEquals("Cargada y envión", ephemeral.getString("name"))
        assertTrue(ephemeral.getBoolean("isCustom"))
    }

    @Test fun sameNameLegacyCustomsRelinkToOfficialIds() {
        // Apple 6efd1cec: fichas provisionales que comparten nombre con la oficial
        // y fueron guardadas antes del seed; ambas re-enlazan a los ids oficiales.
        val provisional = ex("provisional-btt", "Burpee to target", custom = true)
        val oldToes = ex("old-toes", "Toes to bar", custom = true)
        assertEquals("Burpee to target",
            dev.repera.domain.CrossFitGlossary.resolveCatalogName("BTt"))
        assertEquals("Toes to bar",
            dev.repera.domain.CrossFitGlossary.resolveCatalogName("T2B"))
        val m1 = JSONObject().put("id", "m1").put("name", "BTt")
            .put("exerciseId", "provisional-btt").put("reps", 8)
        val m2 = JSONObject().put("id", "m2").put("name", "T2B")
            .put("exerciseId", "old-toes").put("reps", 10)
        val b = JSONObject().put("id", "b1").put("kind", "wod").put("wodFormat", "emom")
            .put("movements", JSONArray().put(m1).put(m2))
        val out = append(b, catalog(provisional, oldToes))
        assertEquals(2, out.length())
        val first = out.getJSONObject(0).getJSONObject("exercise")
        val second = out.getJSONObject(1).getJSONObject("exercise")
        assertEquals("Burpee to target", first.getString("name"))
        assertEquals("Toes to bar", second.getString("name"))
        assertFalse(first.optBoolean("isCustom"))
        assertFalse(second.optBoolean("isCustom"))
        assertNotEquals("provisional-btt", first.getString("id"))
        assertNotEquals("old-toes", second.getString("id"))
    }

    @Test fun restMovementsStillSkipped() {
        val rest = JSONObject().put("id", "r1").put("name", "Rest").put("isRest", true).put("restSeconds", 60)
        val work = JSONObject().put("id", "m5").put("name", "Thruster").put("reps", 15)
        val b = JSONObject().put("id", "b1").put("kind", "wod").put("wodFormat", "forTime")
            .put("movements", JSONArray().put(rest).put(work))
        assertEquals(1, append(b, JSONArray()).length())
    }
}
