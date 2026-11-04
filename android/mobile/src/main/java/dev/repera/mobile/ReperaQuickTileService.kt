package dev.repera.mobile

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Acceso del sistema: abre Comenzar. No arranca sensores ni GPS desde segundo
 * plano; permisos, sesión y posible entrenamiento activo se validan en MainActivity.
 */
class ReperaQuickTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.let { tile ->
            tile.label = "Comenzar en Repera"
            tile.state = Tile.STATE_ACTIVE
            tile.updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val open = {
            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("repera://live")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val pending = PendingIntent.getActivity(
                    this, 4401, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                startActivityAndCollapse(pending)
            } else {
                @Suppress("DEPRECATION")
                startActivityAndCollapse(intent)
            }
        }
        if (isLocked) unlockAndRun(open) else open()
    }
}
