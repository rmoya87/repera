package dev.repera.mobile

import android.content.Context
import android.graphics.BitmapFactory
import android.util.LruCache
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
    /** Covers 40–44 dp thumbnails up to xxxhdpi. */
    const val THUMBNAIL_PX = 192

    @Volatile private var stems: Set<String>? = null

    /** Packaged assets never change at runtime: list them once per process. */
    fun availableStems(context: Context): Set<String> = stems ?: (context.assets.list("exercise-art") ?: emptyArray())
        .asSequence()
        .filter { it.endsWith(".jpg") }
        .map { it.removeSuffix(".jpg") }
        .toSet()
        .also { stems = it }

    private val cache = object : LruCache<String, ImageBitmap>(
        (Runtime.getRuntime().maxMemory() / 16).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()) {
        override fun sizeOf(key: String, value: ImageBitmap) = value.width * value.height * 4
    }

    /** Largest power-of-two subsampling that keeps both sides >= [targetPx]. */
    internal fun sampleSize(width: Int, height: Int, targetPx: Int): Int {
        if (targetPx <= 0 || width <= 0 || height <= 0) return 1
        var sample = 1
        while (width / (sample * 2) >= targetPx && height / (sample * 2) >= targetPx) sample *= 2
        return sample
    }

    fun carouselStems(
        context: Context,
        name: String,
        isMobility: Boolean,
        aliases: Map<String, String>,
        captionCount: Int,
        artKeys: List<String> = emptyList(),
    ): List<String> {
        val packaged = availableStems(context)
        fun present(stem: String) =
            stem in packaged || RemoteExerciseArtCache.hasFile(context, stem)
        if (artKeys.isNotEmpty()) {
            val available = artKeys.filter(::present)
            if (available.isNotEmpty()) return available
        }
        val hero = ExerciseArtResolver.heroFor(name, isMobility, aliases) ?: return emptyList()
        return ExerciseArtResolver.framesFor(name, hero, captionCount, isMobility, ::present)
            .filter(::present)
    }

    /** [targetPx] is the largest rendered side; 0 decodes at full resolution (hero). */
    suspend fun load(context: Context, stem: String, targetPx: Int = 0): ImageBitmap? {
        val key = "$stem@$targetPx"
        cache.get(key)?.let { return it }
        return withContext(Dispatchers.IO) {
            runCatching {
                decodeStem(context, stem, targetPx)
            }.getOrNull()?.also { cache.put(key, it) }
        }
    }

    private fun decodeStem(context: Context, stem: String, targetPx: Int): ImageBitmap? {
        val remote = RemoteExerciseArtCache.fileFor(context, stem)
        if (remote.isFile) {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(remote.path, bounds)
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight, targetPx)
            }
            return BitmapFactory.decodeFile(remote.path, options)?.asImageBitmap()
        }
        val path = "exercise-art/$stem.jpg"
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        context.assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight, targetPx)
        }
        return context.assets.open(path).use { input ->
            BitmapFactory.decodeStream(input, null, options)?.asImageBitmap()
        }
    }
}
