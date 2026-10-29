package dev.repera.wear

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.MonochromaticImageComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import org.json.JSONObject

/**
 * Complicación de esfera equivalente a la del Apple Watch (ReperaWatchWidget):
 * abre el entreno de hoy en Repera desde cualquier esfera.
 */
class ReperaComplicationService : SuspendingComplicationDataSourceService() {

    private fun tapAction(): PendingIntent = PendingIntent.getActivity(
        this, 0, Intent(this, WearMainActivity::class.java),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun icon(): Icon = Icon.createWithResource(this, R.drawable.ic_repera_complication)

    private fun todayTitle(): String {
        val prefs = getSharedPreferences("repera.wear.session", MODE_PRIVATE)
        val raw = prefs.getString("todayPlan", null) ?: return "Entreno de hoy"
        val at = prefs.getLong("todayPlanAt", 0L)
        if (at > 0L && System.currentTimeMillis() - at > WearMainActivity.TODAY_PLAN_TTL_MS) {
            return "Entreno de hoy"
        }
        return runCatching {
            JSONObject(raw).optString("title").ifBlank { "Entreno de hoy" }
        }.getOrDefault("Entreno de hoy")
    }

    private fun build(type: ComplicationType): ComplicationData? = when (type) {
        ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
            PlainComplicationText.Builder("Repera").build(),
            PlainComplicationText.Builder("Abrir el entreno de hoy").build()
        ).setMonochromaticImage(MonochromaticImage.Builder(icon()).build())
            .setTapAction(tapAction()).build()
        ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
            PlainComplicationText.Builder(todayTitle()).build(),
            PlainComplicationText.Builder("Repera · Entreno").build()
        ).setTitle(PlainComplicationText.Builder("Repera").build())
            .setTapAction(tapAction()).build()
        ComplicationType.MONOCHROMATIC_IMAGE -> MonochromaticImageComplicationData.Builder(
            MonochromaticImage.Builder(icon()).build(),
            PlainComplicationText.Builder("Abrir el entreno de hoy").build()
        ).setTapAction(tapAction()).build()
        ComplicationType.SMALL_IMAGE -> SmallImageComplicationData.Builder(
            SmallImage.Builder(icon(), SmallImageType.ICON).build(),
            PlainComplicationText.Builder("Abrir el entreno de hoy").build()
        ).setTapAction(tapAction()).build()
        else -> null
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? = build(type)

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? =
        build(request.complicationType)
}
