package dev.repera.wear

import android.content.SharedPreferences
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import org.json.JSONObject

/**
 * Tile opcional (W-10): entreno de hoy + atajo a Iniciar, espejo de la
 * complicación rectangular / inline del Apple Watch.
 */
class ReperaTodayTileService : TileService() {

    private fun prefs(): SharedPreferences =
        getSharedPreferences("repera.wear.session", MODE_PRIVATE)

    private fun planTitle(): String {
        val raw = prefs().getString("todayPlan", null) ?: return "Sin plan descargado"
        val at = prefs().getLong("todayPlanAt", 0L)
        if (at > 0L && System.currentTimeMillis() - at > WearMainActivity.TODAY_PLAN_TTL_MS) {
            return "Sin plan descargado"
        }
        return runCatching {
            JSONObject(raw).optString("title").ifBlank { "Entreno de hoy" }
        }.getOrDefault("Entreno de hoy")
    }

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest
    ): ListenableFuture<TileBuilders.Tile> {
        val title = planTitle()
        val click = ModifiersBuilders.Clickable.Builder()
            .setId("open")
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setClassName(WearMainActivity::class.java.name)
                            .setPackageName(packageName)
                            .build()
                    )
                    .build()
            )
            .build()
        val column = LayoutElementBuilders.Column.Builder()
            .setModifiers(ModifiersBuilders.Modifiers.Builder().setClickable(click).build())
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText("Repera")
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setColor(argb(0xFF30D158.toInt()))
                            .build()
                    )
                    .build()
            )
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText(title)
                    .setMaxLines(2)
                    .build()
            )
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText("Iniciar")
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setColor(argb(0xFF30D158.toInt()))
                            .build()
                    )
                    .build()
            )
            .build()
        val layout = LayoutElementBuilders.Layout.Builder().setRoot(
            LayoutElementBuilders.Box.Builder()
                .setWidth(DimensionBuilders.expand())
                .setHeight(DimensionBuilders.expand())
                .addContent(column)
                .build()
        ).build()
        val entry = TimelineBuilders.TimelineEntry.Builder()
            .setLayout(layout)
            .build()
        val timeline = TimelineBuilders.Timeline.Builder().addTimelineEntry(entry).build()
        return Futures.immediateFuture(
            TileBuilders.Tile.Builder()
                .setResourcesVersion("1")
                .setTileTimeline(timeline)
                .build()
        )
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest
    ): ListenableFuture<androidx.wear.protolayout.ResourceBuilders.Resources> =
        Futures.immediateFuture(
            androidx.wear.protolayout.ResourceBuilders.Resources.Builder()
                .setVersion(requestParams.version)
                .build()
        )
}
