package dev.repera.mobile

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream

/**
 * Handles ACTION_SEND / ACTION_VIEW for GPX and board images from the system
 * share sheet / “Open with…”. Only copies into app cache; parsing / OCR happens
 * in authenticated UI (Live routes / BoardScanScreen).
 */
internal object SystemShareImport {
    const val EXTRA_PENDING_GPX = "repera.pending.gpx.uri"
    const val EXTRA_PENDING_BOARD = "repera.pending.board.uri"
    private const val MAX_BYTES = 16L * 1024L * 1024L

    sealed class Result {
        data class Gpx(val cacheFile: File, val displayName: String) : Result()
        data class BoardImage(val cacheFile: File, val displayName: String) : Result()
        data object Ignored : Result()
    }

    fun consume(context: Context, intent: Intent?): Result {
        if (intent == null) return Result.Ignored
        val action = intent.action ?: return Result.Ignored
        val stream: Uri? = when (action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                ?: intent.clipData?.getItemAt(0)?.uri
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }
        if (stream == null) return Result.Ignored
        val mime = intent.type
            ?: context.contentResolver.getType(stream)
            ?: ""
        val name = displayName(context.contentResolver, stream) ?: stream.lastPathSegment.orEmpty()
        val lower = name.lowercase()
        val isGpx = mime.contains("gpx", ignoreCase = true)
            || mime.equals("application/xml", ignoreCase = true)
            || mime.equals("text/xml", ignoreCase = true)
            || lower.endsWith(".gpx")
        val isImage = mime.startsWith("image/")
            || lower.endsWith(".jpg") || lower.endsWith(".jpeg")
            || lower.endsWith(".png") || lower.endsWith(".webp") || lower.endsWith(".heic")
        if (!isGpx && !isImage) return Result.Ignored
        val destDir = File(context.cacheDir, "system_import").also { it.mkdirs() }
        val dest = File(destDir, if (isGpx) "import-${System.currentTimeMillis()}.gpx" else "board-${System.currentTimeMillis()}.img")
        return runCatching {
            context.contentResolver.openInputStream(stream)?.use { input ->
                FileOutputStream(dest).use { output ->
                    val buf = ByteArray(8192)
                    var total = 0L
                    while (true) {
                        val n = input.read(buf)
                        if (n <= 0) break
                        total += n
                        if (total > MAX_BYTES) error("too large")
                        output.write(buf, 0, n)
                    }
                }
            } ?: error("no stream")
            if (isGpx) Result.Gpx(dest, name.ifBlank { dest.name })
            else Result.BoardImage(dest, name.ifBlank { dest.name })
        }.getOrDefault(Result.Ignored)
    }

    private fun displayName(resolver: ContentResolver, uri: Uri): String? {
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) return cursor.getString(idx)
            }
        }
        return null
    }
}
