package dev.repera.wear

import android.app.PendingIntent
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
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import org.json.JSONObject

/**
 * Complicación de esfera: **icono de la app Repera** (misma mascota/verde que iOS).
 * - SMALL_IMAGE / PHOTO_IMAGE → bitmap a color (no vector tintado)
 * - MONOCHROMATIC_* → silueta blanca del mismo icono
 */
class ReperaComplicationService : SuspendingComplicationDataSourceService() {

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

    private fun colorLogoBitmap(): Bitmap {
        val opts = BitmapFactory.Options().apply {
            inScaled = false
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeResource(resources, R.drawable.ic_repera_logo, opts)
            ?: Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888).also { bmp ->
                bmp.eraseColor(0xFF30D158.toInt())
            }
    }

    private fun colorLogo(): Icon = Icon.createWithBitmap(colorLogoBitmap())

    private fun monoLogo(): Icon = Icon.createWithResource(this, R.drawable.ic_repera_logo_mono)

    private fun contentDescription(): ComplicationText =
        PlainComplicationText.Builder("Abrir Repera").build()

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
            contentDescription()
        ).setMonochromaticImage(MonochromaticImage.Builder(monoLogo()).build())
            .setTapAction(tapAction())
            .build()

        ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
            PlainComplicationText.Builder(todayTitle()).build(),
            contentDescription()
        ).setTitle(PlainComplicationText.Builder("Repera").build())
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

    override fun getPreviewData(type: ComplicationType): ComplicationData? = build(type)

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? =
        build(request.complicationType)
}
