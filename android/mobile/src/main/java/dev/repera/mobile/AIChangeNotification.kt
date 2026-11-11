package dev.repera.mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.util.UUID

/**
 * Native system notifications when an AI connection creates, updates or deletes
 * a workout. Replaces the in-app status toast for plan imports.
 */
internal object AIChangeNotification {
    private const val CHANNEL = "repera.ai.changes"
    private const val PREFS = "repera.ai.change.notifications"
    private const val NOTIFIED = "notified"
    private const val FALLBACK = "Tu asistente"

    fun connectionLabel(raw: String?): String {
        val trimmed = raw?.trim().orEmpty()
        return if (trimmed.isEmpty()) FALLBACK else trimmed
    }

    fun notifyCreate(
        context: Context,
        planId: String,
        title: String,
        day: String,
        connectionName: String?
    ) {
        if (!markNotified(context, planId)) return
        val name = connectionLabel(connectionName)
        show(
            context = context,
            id = planId,
            title = "$name ha añadido un entreno",
            body = title,
            kind = "create",
            workoutId = null,
            routineId = planId,
            day = day
        )
    }

    fun notifyPendingChange(
        context: Context,
        changeId: String,
        operation: String,
        workoutTitle: String?,
        workoutId: String?,
        day: String?,
        connectionName: String?,
        setChangeCount: Int
    ) {
        if (operation != "update_workout" && operation != "delete_workout") return
        if (!markNotified(context, changeId)) return
        val name = connectionLabel(connectionName)
        val label = workoutTitle?.trim().orEmpty().ifEmpty { "entrenamiento" }
        if (operation == "delete_workout") {
            show(
                context = context,
                id = changeId,
                title = "$name pide eliminar un entreno",
                body = "«$label» · confirma para borrarlo",
                kind = "delete",
                workoutId = workoutId,
                routineId = null,
                day = day
            )
        } else {
            val body = when {
                label == "entrenamiento" -> "Revisa y aplica el cambio"
                setChangeCount > 0 -> "$label · $setChangeCount series · revisa y aplica"
                else -> label
            }
            show(
                context = context,
                id = changeId,
                title = "$name quiere corregir un entreno",
                body = body,
                kind = "update",
                workoutId = workoutId,
                routineId = null,
                day = day
            )
        }
    }

    fun clearNotified(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun routeFromUri(uri: Uri, overview: JSONObject?): String {
        if (uri.host != "ai-change") return "inicio"
        val kind = uri.getQueryParameter("kind").orEmpty()
        val workoutId = uri.getQueryParameter("workoutId")
        val day = uri.getQueryParameter("day")
        val routineId = uri.getQueryParameter("routineId")
        fun workoutExists(id: String): Boolean {
            val rows = overview?.optJSONArray("workouts") ?: return false
            return (0 until rows.length()).any { i ->
                rows.optJSONObject(i)?.optString("id") == id
            }
        }
        return when (kind) {
            "create" -> {
                val focus = day ?: ""
                if (routineId != null && focus.isNotBlank()) {
                    "inicio?day=" + Uri.encode(focus) + "&routine=" + Uri.encode(routineId)
                } else if (focus.isNotBlank()) {
                    "inicio?day=" + Uri.encode(focus)
                } else "inicio"
            }
            "update", "delete" -> {
                if (!workoutId.isNullOrBlank() && workoutExists(workoutId)) {
                    "historial-detalle/" + Uri.encode(workoutId)
                } else if (!day.isNullOrBlank()) {
                    "inicio?day=" + Uri.encode(day)
                } else "inicio"
            }
            else -> "inicio"
        }
    }

    private fun markNotified(context: Context, id: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val key = id.lowercase()
        val seen = prefs.getStringSet(NOTIFIED, emptySet())?.toMutableSet() ?: mutableSetOf()
        if (!seen.add(key)) return false
        while (seen.size > 400) {
            val first = seen.firstOrNull() ?: break
            seen.remove(first)
        }
        prefs.edit().putStringSet(NOTIFIED, seen).apply()
        return true
    }

    private fun show(
        context: Context,
        id: String,
        title: String,
        body: String,
        kind: String,
        workoutId: String?,
        routineId: String?,
        day: String?
    ) {
        if (runCatching { UUID.fromString(id) }.isFailure) return
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) return

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Cambios de IA", NotificationManager.IMPORTANCE_DEFAULT)
        )
        val uri = Uri.parse("repera://ai-change").buildUpon()
            .appendQueryParameter("kind", kind)
            .apply {
                if (!workoutId.isNullOrBlank()) appendQueryParameter("workoutId", workoutId)
                if (!routineId.isNullOrBlank()) appendQueryParameter("routineId", routineId)
                if (!day.isNullOrBlank()) appendQueryParameter("day", day)
            }
            .build()
        val open = Intent(context, MainActivity::class.java)
            .setData(uri)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val requestCode = id.hashCode() and Int.MAX_VALUE
        val click = PendingIntent.getActivity(
            context, requestCode, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(click)
            .build()
        manager.notify(requestCode, notification)
    }
}
