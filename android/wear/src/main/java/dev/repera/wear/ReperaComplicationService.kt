package dev.repera.wear

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationText
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.MonochromaticImageComplicationData
import androidx.wear.watchface.complications.data.PhotoImageComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import androidx.wear.watchface.complications.datasource.ComplicationDataTimeline
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingTimelineComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.TimeInterval
import androidx.wear.watchface.complications.datasource.TimelineEntry
import java.time.Instant

/**
 * Complicación de esfera: **icono de la app Repera** (misma mascota/verde que iOS).
 * - SMALL_IMAGE / PHOTO_IMAGE → bitmap a color (no vector tintado)
 * - MONOCHROMATIC_* → silueta blanca del mismo icono
 * - LONG_TEXT → título del plan de hoy; la línea temporal pasa a «Sin plan» a medianoche.
 */
class ReperaComplicationService : SuspendingTimelineComplicationDataSourceService() {

    companion object {
        @Volatile private var logoBitmap: Bitmap? = null

        /** Refresh after the cached plan changes (the timeline covers midnight). */
        fun requestUpdate(context: Context) {
            runCatching {
                ComplicationDataSourceUpdateRequester.create(
                    context, ComponentName(context, ReperaComplicationService::class.java)
                ).requestUpdateAll()
            }
        }
    }

    private fun tapAction(): PendingIntent = PendingIntent.getActivity(
        this,
        0,
        Intent(this, WearMainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(WearMainActivity.EXTRA_OPEN_TODAY, true)
        },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun colorLogoBitmap(): Bitmap = logoBitmap ?: run {
        val opts = BitmapFactory.Options().apply {
            inScaled = false
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        (BitmapFactory.decodeResource(resources, R.drawable.ic_repera_logo, opts)
            ?: Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888).also { bmp ->
                bmp.eraseColor(0xFF30D158.toInt())
            }).also { logoBitmap = it }
    }

    private fun colorLogo(): Icon = Icon.createWithBitmap(colorLogoBitmap())

    private fun monoLogo(): Icon = Icon.createWithResource(this, R.drawable.ic_repera_logo_mono)

    private fun contentDescription(): ComplicationText =
        PlainComplicationText.Builder(getString(R.string.wear_complication_open)).build()

    private fun build(type: ComplicationType, longText: String): ComplicationData? = when (type) {
        ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
            PlainComplicationText.Builder(getString(R.string.wear_app_name)).build(),
            contentDescription()
        ).setMonochromaticImage(MonochromaticImage.Builder(monoLogo()).build())
            .setTapAction(tapAction())
            .build()

        ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
            PlainComplicationText.Builder(longText).build(),
            contentDescription()
        ).setTitle(PlainComplicationText.Builder(getString(R.string.wear_app_name)).build())
            .setMonochromaticImage(MonochromaticImage.Builder(monoLogo()).build())
            .setTapAction(tapAction())
            .build()

        ComplicationType.MONOCHROMATIC_IMAGE -> MonochromaticImageComplicationData.Builder(
            MonochromaticImage.Builder(monoLogo()).build(),
            contentDescription()
        ).setTapAction(tapAction()).build()

        ComplicationType.SMALL_IMAGE -> SmallImageComplicationData.Builder(
            SmallImage.Builder(colorLogo(), SmallImageType.PHOTO).build(),
            contentDescription()
        ).setTapAction(tapAction()).build()

        ComplicationType.PHOTO_IMAGE -> PhotoImageComplicationData.Builder(
            colorLogo(),
            contentDescription()
        ).setTapAction(tapAction()).build()

        else -> null
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        build(type, getString(R.string.wear_today_plan_untitled))

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationDataTimeline? {
        val type = request.complicationType
        val noPlan = build(type, getString(R.string.wear_no_plan_today)) ?: return null
        if (type != ComplicationType.LONG_TEXT) return ComplicationDataTimeline(noPlan, emptyList())
        val prefs = getSharedPreferences(WearTodayPlanCache.PREFS, MODE_PRIVATE)
        val day = prefs.getString("todayPlanDay", null)
        val savedAt = prefs.getLong("todayPlanAt", 0L)
        val plan = WearTodayPlanCache.freshPlan(prefs.getString("todayPlan", null), day, savedAt)
        val until = WearTodayPlanCache.validUntilMillis(day, savedAt)
        if (plan == null || until == null || until <= System.currentTimeMillis()) {
            return ComplicationDataTimeline(noPlan, emptyList())
        }
        val title = plan.optString("title").ifBlank { getString(R.string.wear_today_plan_untitled) }
        val withPlan = build(type, title) ?: return ComplicationDataTimeline(noPlan, emptyList())
        return ComplicationDataTimeline(
            noPlan,
            listOf(TimelineEntry(
                TimeInterval(Instant.now(), Instant.ofEpochMilli(until)), withPlan
            ))
        )
    }
}
