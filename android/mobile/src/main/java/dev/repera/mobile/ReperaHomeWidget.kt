package dev.repera.mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.glance.ExperimentalGlanceApi
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.Button
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

/**
 * Launcher snapshot is account-scoped, derived from an existing local checkpoint.
 * A widget is never a sensor owner; navigation always goes through MainActivity.
 * No Health Connect values, GPS, tokens or private training notes are published.
 */
@OptIn(ExperimentalGlanceApi::class)
class ReperaHomeWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val summary = withContext(Dispatchers.IO) {
            val owner = SessionStore(context).load()?.uniqueId ?: return@withContext "Inicia sesión para entrenar"
            runCatching {
                val bytes = LocalSnapshotStore(context, owner).read()
                    ?: return@runCatching "Consulta tu entrenamiento de hoy"
                val snapshot = JSONObject(String(bytes, Charsets.UTF_8))
                if (snapshot.optJSONObject("activeSession") != null)
                    "Tienes un entrenamiento en curso"
                else "Consulta tu entrenamiento de hoy"
            }.getOrDefault("Consulta tu entrenamiento de hoy")
        }
        provideContent {
            Column(modifier = GlanceModifier.fillMaxWidth().padding(12.dp)) {
                Text("Repera · Entrenamiento")
                Spacer(modifier = GlanceModifier.height(8.dp))
                Text(summary)
                Spacer(modifier = GlanceModifier.height(8.dp))
                Button(
                    text = "Entreno de hoy",
                    onClick = actionStartActivity(
                        Intent(context, MainActivity::class.java)
                            .setAction(Intent.ACTION_VIEW)
                            .setData(Uri.parse("repera://today"))
                    )
                )
                Button(
                    text = "Comenzar",
                    onClick = actionStartActivity(
                        Intent(context, MainActivity::class.java)
                            .setAction(Intent.ACTION_VIEW)
                            .setData(Uri.parse("repera://live"))
                    )
                )
            }
        }
    }
}

class ReperaHomeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ReperaHomeWidget()
}
