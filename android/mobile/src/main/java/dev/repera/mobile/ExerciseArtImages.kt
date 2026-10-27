package dev.repera.mobile

import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Decodificación bajo demanda del arte empaquetado en assets/exercise-art.
 * El set de nombres disponibles se lee una vez y sirve de sonda de existencia
 * para el carrusel numerado (hero_1..hero_8), igual que iOS comprueba el bundle.
 */
internal object ExerciseArtImages {

    fun availableStems(context: Context): Set<String> =
        (context.assets.list("exercise-art") ?: emptyArray())
            .asSequence()
            .filter { it.endsWith(".jpg") }
            .map { it.removeSuffix(".jpg") }
            .toSet()

    fun carouselStems(context: Context, name: String, isMobility: Boolean,
                      aliases: Map<String, String>, captionCount: Int): List<String> {
        val stems = availableStems(context)
        val hero = ExerciseArtResolver.heroFor(name, isMobility, aliases) ?: return emptyList()
        return ExerciseArtResolver.framesFor(name, hero, captionCount, isMobility) { it in stems }
            .filter { it in stems }
    }

    suspend fun load(context: Context, stem: String): ImageBitmap? =
        withContext(Dispatchers.IO) {
            runCatching {
                context.assets.open("exercise-art/$stem.jpg").use { input ->
                    BitmapFactory.decodeStream(input)?.asImageBitmap()
                }
            }.getOrNull()
        }
}
