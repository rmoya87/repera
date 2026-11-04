package dev.repera.wear

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat

/**
 * One bounded location fix at workout start. Never enables route tracking or
 * keeps the GPS listening for an indoor training session.
 *
 * Permissions are requested by WearMainActivity after the user starts workout.
 */
internal class WearStartLocationCapture(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private var cancellation: CancellationSignal? = null

    fun capture(onResult: (Location?) -> Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            onResult(null)
            return
        }
        val manager = context.getSystemService(LocationManager::class.java)
        if (manager == null) {
            onResult(null)
            return
        }
        val provider = listOf(
            LocationManager.FUSED_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.GPS_PROVIDER
        ).firstOrNull { runCatching { manager.isProviderEnabled(it) }.getOrDefault(false) }
        if (provider == null) {
            onResult(null)
            return
        }
        cancellation?.cancel()
        val signal = CancellationSignal()
        cancellation = signal
        try {
            manager.getCurrentLocation(provider, signal, context.mainExecutor) { fix ->
                if (cancellation === signal) {
                    cancellation = null
                    val now = System.currentTimeMillis()
                    val valid = fix?.takeIf {
                        it.hasAccuracy() && it.accuracy in 0f..100f &&
                            now - it.time in 0L..30_000L &&
                            it.latitude in -90.0..90.0 &&
                            it.longitude in -180.0..180.0
                    }
                    onResult(valid)
                }
            }
            handler.postDelayed({
                if (cancellation === signal) {
                    cancellation = null
                    signal.cancel()
                    onResult(null)
                }
            }, 5_000L)
        } catch (_: SecurityException) {
            if (cancellation === signal) cancellation = null
            onResult(null)
        } catch (_: IllegalArgumentException) {
            if (cancellation === signal) cancellation = null
            onResult(null)
        }
    }

    fun cancel() {
        cancellation?.cancel()
        cancellation = null
    }
}
