package dev.repera.wear

import android.content.Context
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
 * complicación rectangular / inline del Apple Watch. El plan de hoy caduca
 * a medianoche mediante la validez de la línea temporal.
 */
class ReperaTodayTileService : TileService() {

    companion object {
        fun requestUpdate(context: Context) {
            runCatching { getUpdater(context).requestUpdate(ReperaTodayTileService::class.java) }
        }
    }

    private fun prefs(): SharedPreferences =
        getSharedPreferences(WearTodayPlanCache.PREFS, MODE_PRIVATE)

    private fun activeSessionTitle(): String? {
        val raw = prefs().getString("snapshot", null) ?: return null
        return runCatching {
            val session = WatchSessionSummary.fromJson(JSONObject(raw))
            session.title.takeIf { it.isNotBlank() } ?: getString(R.string.wear_active_session)
        }.getOrNull()
    }

    private fun layout(title: String, action: String): LayoutElementBuilders.Layout {
        val click = ModifiersBuilders.Clickable.Builder()
            .setId("open")
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setClassName(WearMainActivity::class.java.name)
                            .setPackageName(packageName)
                            .addKeyToExtraMapping(
                                WearMainActivity.EXTRA_OPEN_TODAY,
                                ActionBuilders.booleanExtra(true)
                            )
                            .build()
                    )
                    .build()
            )
            .build()
        val column = LayoutElementBuilders.Column.Builder()
            .setModifiers(ModifiersBuilders.Modifiers.Builder().setClickable(click).build())
            .addContent(
                LayoutElementBuilders.Text.Builder()
                    .setText(getString(R.string.wear_app_name))
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
                    .setText(action)
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setColor(argb(0xFF30D158.toInt()))
                            .build()
                    )
                    .build()
            )
            .build()
        return LayoutElementBuilders.Layout.Builder().setRoot(
            LayoutElementBuilders.Box.Builder()
                .setWidth(DimensionBuilders.expand())
                .setHeight(DimensionBuilders.expand())
                .addContent(column)
                .build()
        ).build()
    }

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest
    ): ListenableFuture<TileBuilders.Tile> {
        val open = getString(R.string.wear_tile_open)
        val noPlan = getString(R.string.wear_no_plan_today)
        val timeline = TimelineBuilders.Timeline.Builder()
        var freshness = 0L
        val activeTitle = activeSessionTitle()
        if (activeTitle != null) {
            timeline.addTimelineEntry(TimelineBuilders.TimelineEntry.Builder()
                .setLayout(layout(activeTitle, getString(R.string.wear_tile_continue))).build())
        } else {
            val day = prefs().getString("todayPlanDay", null)
            val savedAt = prefs().getLong("todayPlanAt", 0L)
            val plan = WearTodayPlanCache.freshPlan(prefs().getString("todayPlan", null), day, savedAt)
            val until = WearTodayPlanCache.validUntilMillis(day, savedAt)
            val now = System.currentTimeMillis()
            if (plan != null && until != null && until > now) {
                val title = plan.optString("title").ifBlank { getString(R.string.wear_today_plan_untitled) }
                timeline.addTimelineEntry(TimelineBuilders.TimelineEntry.Builder()
                    .setValidity(TimelineBuilders.TimeInterval.Builder()
                        .setStartMillis(now).setEndMillis(until).build())
                    .setLayout(layout(title, open)).build())
                timeline.addTimelineEntry(TimelineBuilders.TimelineEntry.Builder()
                    .setValidity(TimelineBuilders.TimeInterval.Builder()
                        .setStartMillis(until).build())
                    .setLayout(layout(noPlan, open)).build())
                freshness = until - now
            } else {
                timeline.addTimelineEntry(TimelineBuilders.TimelineEntry.Builder()
                    .setLayout(layout(noPlan, open)).build())
            }
        }
        return Futures.immediateFuture(
            TileBuilders.Tile.Builder()
                .setResourcesVersion("1")
                .setTileTimeline(timeline.build())
                .apply { if (freshness > 0L) setFreshnessIntervalMillis(freshness) }
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
