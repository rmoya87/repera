package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Cobertura real de la ficha de ejercicio contra los assets empaquetados:
 * cada entrada del catálogo semilla (fuerza, movilidad, HYROX) debe traer
 * textos localizados y, salvo excepción documentada, arte resoluble.
 */
@RunWith(AndroidJUnit4::class)
class ExerciseDetailInstrumentedTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    private fun seed(file: String): JSONArray =
        JSONArray(context.assets.open(file).bufferedReader(Charsets.UTF_8).use { it.readText() })

    @Test
    fun everySeedEntryCarriesLocalizedText() {
        for (file in listOf("catalog_seed.json", "mobility_seed.json", "hyrox_seed.json")) {
            val entries = seed(file)
            for (i in 0 until entries.length()) {
                val entry = entries.getJSONObject(i)
                val name = entry.getString("name")
                val instructions = entry.optJSONArray("instructions")
                assertTrue("$name sin instrucciones en $file",
                    instructions != null && instructions.length() > 0)
            }
        }
    }

    @Test
    fun seedNamesResolveToBundledArt() {
        val stems = ExerciseArtImages.availableStems(context)
        val aliases = ExerciseSearchAssets.load(context)
        val missing = mutableListOf<String>()
        var total = 0
        for (file in listOf("catalog_seed.json", "mobility_seed.json")) {
            val entries = seed(file)
            for (i in 0 until entries.length()) {
                val entry = entries.getJSONObject(i)
                total++
                val name = entry.getString("name")
                val isMobility = entry.optString("sportTag") == "Movilidad"
                val hero = ExerciseArtResolver.heroFor(name, isMobility, aliases)
                if (hero == null || hero !in stems) missing += name
            }
        }
        // Paridad con iOS: "Remo pliométrico en anillas pies elevados" tampoco
        // resuelve arte en el nameMap de ExerciseArt.swift. Las entradas con nombre
        // canónico inglés deben resolver vía SportExerciseNames.spanishAlias como
        // hace ExerciseArt.swift (cadena exacto→legacy→canónico→contenida).
        assertEquals(
            // Huecos compartidos con iOS: ninguno resuelve en el nameMap actual de
            // ExerciseArt.swift (Jerk Dip and Drive es alta reciente sin arte aún).
            listOf("Jerk Dip and Drive", "Remo pliométrico en anillas pies elevados"), missing)
        assertEquals(370, total)  // 288 del seed unificado + 82 de mobility_seed (cobertura de arte)
        for (critical in listOf("Snatch", "Hang Snatch", "Clean and Jerk", "Squat Jerk",
                "Snatch High Pull", "Clean High Pull", "Clean Deadlift",
                "Block Power Snatch", "Block Power Clean", "Snatch-Grip Push Press")) {
            assertNotNull(critical + " debe resolver arte vía alias legacy",
                ExerciseArtResolver.heroFor(critical, false, aliases))
        }
    }

    @Test
    fun carouselUsesNumberedStepsWhenBundled() {
        val stems = ExerciseArtImages.availableStems(context)
        // captionCount real del seed (puerta de captions iOS: captions >= fases).
        val entries = seed("catalog_seed.json")
        var captionCount = 0
        for (i in 0 until entries.length()) {
            val e = entries.getJSONObject(i)
            if (e.getString("name") == "Press banca") {
                val ins = e.optJSONArray("instructions")
                captionCount = (0 until (ins?.length() ?: 0)).count {
                    ins!!.getString(it).isNotBlank()
                }
            }
        }
        val frames = ExerciseArtImages.carouselStems(
            context, "Press banca", false, ExerciseSearchAssets.load(context), captionCount)
        assertEquals(
            stems.filter { it.startsWith("art_press_banca_") }.sorted().take(8),
            frames.filter { it != "art_press_banca" })
        assertTrue(frames.isNotEmpty())
    }
}
