package dev.repera.mobile

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings entries only navigate to an authenticated screen.
 * Never start Health Services, GPS or a paid workout from a background tile.
 * MainActivity + ReperaMobileScreen remain responsible for account/session checks.
 */
abstract class ReperaNavigationTileService(
    private val host: String,
    private val label: String,
) : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            this.label = this@ReperaNavigationTileService.label
            state = Tile.STATE_INACTIVE
            icon = Icon.createWithResource(this@ReperaNavigationTileService, R.drawable.ic_timer)
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val open = Intent(this, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("repera://$host"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (Build.VERSION.SDK_INT >= 34) {
            val pending = PendingIntent.getActivity(
                this, host.hashCode(), open,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(open)
        }
    }
}

class ReperaWorkoutTileService : ReperaNavigationTileService("live", "Comenzar Repera")
class ReperaTimerTileService : ReperaNavigationTileService("timer", "Temporizador Repera")
