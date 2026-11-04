package dev.repera.mobile

import android.content.ClipData
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import dev.repera.domain.RouteGPXCodec
import dev.repera.domain.WorkoutRoutePoint
import java.io.File
import java.util.UUID

/** User-triggered only. Shares a short-lived cache file via one-time URI access. */
internal object WorkoutRouteShare {
    fun shareGPX(context: Context, points: List<WorkoutRoutePoint>): Boolean {
        val xml = RouteGPXCodec.encode(points) ?: return false
        val folder = File(context.cacheDir, "route_shares").apply { mkdirs() }
        // Unique file per explicit share; no app state or authentication tokens.
        val file = File(folder, "repera-route-${UUID.randomUUID()}.gpx")
        file.writeText(xml, Charsets.UTF_8)
        val uri = FileProvider.getUriForFile(
            context, "${context.packageName}.boardscan", file
        )
        val intent = Intent(Intent.ACTION_SEND)
            .setType("application/gpx+xml")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .setClipData(ClipData.newUri(context.contentResolver, "Recorrido GPX", uri))
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        context.startActivity(Intent.createChooser(intent, "Compartir recorrido GPX"))
        return true
    }
}
