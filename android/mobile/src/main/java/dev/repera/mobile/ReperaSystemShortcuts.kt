package dev.repera.mobile

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri

/** App shortcuts del lanzador y superficies compatibles con el asistente. */
internal object ReperaSystemShortcuts {
    fun register(context: Context) {
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return
        fun shortcut(id: String, title: String, url: String, icon: Int): ShortcutInfo =
            ShortcutInfo.Builder(context, id)
                .setShortLabel(title)
                .setLongLabel(title)
                .setIcon(Icon.createWithResource(context, icon))
                .setIntent(Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse(url)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                })
                .build()
        // Los accesos sólo abren la sección; no se registra una sesión sin permiso ni confirmación.
        runCatching {
            manager.dynamicShortcuts = listOf(
                shortcut("repera-start", "Comenzar", "repera://live", R.drawable.ic_timer),
                shortcut("repera-workout", "Entreno activo", "repera://workout", R.drawable.ic_timer)
            )
        }
    }
}
