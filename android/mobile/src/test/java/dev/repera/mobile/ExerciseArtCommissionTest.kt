package dev.repera.mobile

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Verificación de la comisión de arte ampliada (14 carruseles) contra assets reales
 * y captions reales del seed. Sonda el directorio de assets del módulo.
 */
class ExerciseArtCommissionTest {

    private val assetNames: Set<String> by lazy {
        File("src/main/assets/exercise-art").listFiles()?.map { it.name }?.toSet() ?: emptySet()
    }

    /** El resolver sondea stems sin extensión; los ficheros reales llevan .jpg/.png. */
    private fun probe(stem: String): Boolean =
        assetNames.contains("$stem.jpg") || assetNames.contains("$stem.png")

    private val seedInstructions: Map<String, List<String>> by lazy {
        val arr = JSONArray(File("src/main/assets/catalog_seed.json").readText())
        buildMap {
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val ins = o.optJSONArray("instructions") ?: JSONArray()
                put(o.getString("name"), List(ins.length()) { ins.getString(it) })
            }
        }
    }

    private data class Expect(val stem: String, val frames: Int, val exercises: List<String>)

    private val commission = listOf(
        Expect("art_gy_air_squat", 3, listOf("Air squat")),
        Expect("art_cf_kb_swing", 3, listOf("Kettlebell Swing")),
        Expect("art_cf_goblet", 3, listOf("Goblet squat")),
        Expect("art_cf_thruster_db", 3, listOf("Dumbbell Thruster")),
        Expect("art_cf_thruster_kb", 3, listOf("Kettlebell Thruster")),
        Expect("art_cf_pistol", 3, listOf("Pistol squat")),
        Expect("art_cf_slam", 3, listOf("Ball slam")),
        Expect("art_cf_broad", 3, listOf("Broad jump")),
        Expect("art_gy_jump_squat", 3, listOf("Jumping squat")),
        Expect("art_cf_db_snatch", 3, listOf("Dumbbell Snatch")),
        Expect("art_cf_kb_clean", 3, listOf("Kettlebell Clean")),
        Expect("art_cf_manmaker", 6, listOf("Man maker")),
        Expect("art_gy_jump_lunge", 3, listOf("Jumping lunge")),
        Expect("art_cf_burpee_box", 3, listOf("Burpee box jump over"))
    )

    @Test
    fun `los 14 carruseles resuelven desde ejercicios semilla con captions suficientes`() {
        for (e in commission) {
            for (ex in e.exercises) {
                val hero = ExerciseArtResolver.heroFor(ex, isMobility = false, aliases = emptyMap())
                assertEquals("hero de '$ex'", e.stem, hero)
                val captions = seedInstructions[ex] ?: emptyList()
                val frames = ExerciseArtResolver.framesFor(
                    ex, hero!!, captionCount = captions.size, exists = ::probe)
                // Compuerta iOS portada: si captions < frames numerados, degrada a héroe.
                val expected = if (captions.size >= e.frames) e.frames else 1
                assertEquals(
                    "frames de '$ex' (captions=${captions.size}, numerados=${e.frames})",
                    expected, frames.size)
                assertEquals(frames, frames.distinct())
            }
        }
    }
}
