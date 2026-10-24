package dev.repera.mobile

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Interacción seed ↔ migración de catálogo (feed remoto): las captions
 * sincronizadas desde iOS en catalog_seed.json deben propagarse a las
 * entradas gestionadas por seed y NUNCA pisar una revisión remota
 * (_remoteCatalogKey), y las entradas nuevas del seed deben incorporarse.
 */
class CatalogSeedInteractionTest {

    private val seed: JSONArray by lazy {
        JSONArray(File("src/main/assets/catalog_seed.json").readText())
    }

    private fun entry(name: String): JSONObject {
        for (i in 0 until seed.length()) {
            val e = seed.getJSONObject(i)
            if (e.getString("name") == name) return e
        }
        error("no existe $name en el seed")
    }

    /** Estado con el catálogo completo del seed, con los campos mínimos de
     *  metadatos que la migración espera. */
    private fun stateFromSeed(): JSONObject {
        val state = JSONObject()
        state.put("exercises", JSONArray(seed.toString()))
        state.put("workouts", JSONArray())
        state.put("routines", JSONArray())
        state.put("syncRevision", 3)
        state.put("updatedAt", "2026-10-20T10:00:00Z")
        state.put("lastWriterDeviceId", "android-test")
        return state
    }

    private fun byName(state: JSONObject, name: String): JSONObject {
        val catalog = state.getJSONArray("exercises")
        for (i in 0 until catalog.length()) {
            val e = catalog.getJSONObject(i)
            if (e.getString("name") == name) return e
        }
        error("no existe $name en el estado")
    }

    @Test
    fun `cambio de instructions en el seed propaga a entradas gestionadas por seed`() {
        val state = stateFromSeed()
        val target = byName(state, "Dumbbell Thruster")
        target.put("instructions", JSONArray(listOf("caption antigua")))
        val changed = CatalogRefreshMigration.mergeSeedIntoState(seed, state)
        assertTrue(changed)
        val expected = entry("Dumbbell Thruster").getJSONArray("instructions").toString()
        assertEquals(expected, byName(state, "Dumbbell Thruster")
            .getJSONArray("instructions").toString())
    }

    @Test
    fun `entrada con revision remota conserva sus instructions aunque el seed difiera`() {
        val state = stateFromSeed()
        val target = byName(state, "Kettlebell Clean")
        target.put("instructions", JSONArray(listOf("edición remota del equipo")))
        target.put("_remoteCatalogKey", "kettlebell-clean")
        val changed = CatalogRefreshMigration.mergeSeedIntoState(seed, state)
        // Puede cambiar otra cosa, pero la entrada remota NO se toca:
        val kept = byName(state, "Kettlebell Clean").getJSONArray("instructions").toString()
        assertEquals("""["edición remota del equipo"]""", kept)
        // y la entrada remota mantiene su clave:
        assertEquals("kettlebell-clean", byName(state, "Kettlebell Clean")
            .getString("_remoteCatalogKey"))
    }

    @Test
    fun `entrada nueva del seed se incorpora al catalogo`() {
        val state = stateFromSeed()
        val catalog = state.getJSONArray("exercises")
        val idx = (0 until catalog.length()).first {
            catalog.getJSONObject(it).getString("name") == "Man maker"
        }
        catalog.remove(idx)
        val before = catalog.length()
        val changed = CatalogRefreshMigration.mergeSeedIntoState(seed, state)
        assertTrue(changed)
        assertEquals(before + 1, state.getJSONArray("exercises").length())
        assertEquals(entry("Man maker").getString("id"),
            byName(state, "Man maker").getString("id"))
    }

    @Test
    fun `una segunda pasada no modifica nada (idempotente)`() {
        val state = stateFromSeed()
        assertFalse(CatalogRefreshMigration.mergeSeedIntoState(seed, state))
    }
}
