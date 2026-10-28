package dev.repera.mobile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.InputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * OCR de pizarra con ML Kit (latin). Equivalente Android de
 * BoardTextRecognizer (Vision) en iOS: foto -> texto plano.
 *
 * Preprocess: aplica orientación EXIF, reduce, y si el lienzo es oscuro
 * (TV / pizarra negra) pinta sobre fondo negro. Timeout 20 s.
 */
object BoardScanOcr {
    private const val TIMEOUT_MS = 20_000L
    private const val MAX_EDGE_PX = 2_400
    /** Mediana de luminancia por debajo → lienzo oscuro. */
    internal const val DARK_LUMINANCE_THRESHOLD = 90

    suspend fun recognize(context: Context, uri: Uri): String =
        withContext(Dispatchers.IO) {
            withTimeout(TIMEOUT_MS) {
                val bitmap = decodePreparedBitmap(context, uri)
                val image = if (bitmap != null) InputImage.fromBitmap(bitmap, 0)
                else InputImage.fromFilePath(context, uri)
                try {
                    suspendCancellableCoroutine { cont ->
                        val recognizer =
                            TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        cont.invokeOnCancellation { recognizer.close() }
                        recognizer.process(image)
                            .addOnSuccessListener { result ->
                                if (cont.isActive) cont.resume(result.text)
                            }
                            .addOnFailureListener { error ->
                                if (cont.isActive) cont.resumeWithException(error)
                            }
                            .addOnCompleteListener { recognizer.close() }
                    }
                } finally {
                    bitmap?.recycle()
                }
            }
        }

    /**
     * Decodifica con orientación EXIF aplicada (BitmapFactory no la respeta),
     * reduce y, si es oscuro, pinta sobre canvas negro.
     */
    internal fun decodePreparedBitmap(context: Context, uri: Uri): Bitmap? {
        val orientation = readExifOrientation(context, uri)
        val stream: InputStream = context.contentResolver.openInputStream(uri) ?: return null
        return stream.use { input ->
            val original = BitmapFactory.decodeStream(input) ?: return null
            val oriented = applyExifOrientation(original, orientation)
            if (oriented !== original) original.recycle()
            val scaled = downscale(oriented)
            if (scaled !== oriented) oriented.recycle()
            prepareForOcr(scaled)
        }
    }

    internal fun readExifOrientation(context: Context, uri: Uri): Int {
        return runCatching {
            context.contentResolver.openInputStream(uri)?.use { stream ->
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL
                )
            } ?: ExifInterface.ORIENTATION_NORMAL
        }.getOrDefault(ExifInterface.ORIENTATION_NORMAL)
    }

    /** Aplica la etiqueta EXIF a un bitmap ya decodificado (tests JVM / Robolectric). */
    internal fun applyExifOrientation(source: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
                matrix.setRotate(180f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return source
        }
        return runCatching {
            Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
        }.getOrDefault(source)
    }

    internal fun prepareForOcr(source: Bitmap): Bitmap {
        val luminance = sampleMedianLuminance(source)
        if (luminance >= DARK_LUMINANCE_THRESHOLD) return source
        val prepared = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(prepared)
        canvas.drawColor(Color.BLACK)
        canvas.drawBitmap(source, 0f, 0f, null)
        if (prepared !== source) source.recycle()
        return prepared
    }

    internal fun sampleMedianLuminance(bitmap: Bitmap): Int {
        val w = bitmap.width
        val h = bitmap.height
        if (w <= 0 || h <= 0) return 255
        val stepX = maxOf(1, w / 32)
        val stepY = maxOf(1, h / 32)
        val samples = ArrayList<Int>(32 * 32)
        var y = 0
        while (y < h) {
            var x = 0
            while (x < w) {
                val c = bitmap.getPixel(x, y)
                val r = (c shr 16) and 0xFF
                val g = (c shr 8) and 0xFF
                val b = c and 0xFF
                // Rec. 601 luma.
                samples.add((0.299 * r + 0.587 * g + 0.114 * b).toInt())
                x += stepX
            }
            y += stepY
        }
        if (samples.isEmpty()) return 255
        samples.sort()
        return samples[samples.size / 2]
    }

    private fun downscale(source: Bitmap): Bitmap {
        val maxEdge = maxOf(source.width, source.height)
        if (maxEdge <= MAX_EDGE_PX) return source
        val scale = MAX_EDGE_PX.toFloat() / maxEdge
        val w = maxOf(1, (source.width * scale).toInt())
        val h = maxOf(1, (source.height * scale).toInt())
        return Bitmap.createScaledBitmap(source, w, h, true)
    }
}
