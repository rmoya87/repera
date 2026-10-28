package dev.repera.mobile

import android.content.Context
import android.location.Address
import android.location.Geocoder
import dev.repera.domain.LiveSport
import dev.repera.domain.WorkoutRoutePoint
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import kotlin.coroutines.resume

/** Sugerencias únicamente por localidad, jamás calle, número ni domicilio.
 * La actividad guarda el título editable; no se almacena una geocodificación.
 */
internal object LiveActivityLocationName {
    fun format(sport: LiveSport, from: String, to: String? = null): String {
        val start=from.trim()
        if(start.isEmpty()) return sport.title
        val activity=when(sport.id) {
            "walking" -> "Caminata"
            "running","trail" -> "Carrera"
            else -> sport.title
        }
        val end=to?.trim().orEmpty()
        if(end.isNotEmpty() && !end.equals(start,true)) return "$activity de $start a $end"
        val prep=if(sport.id in setOf("walking","running","trail","hiking","cycling")) "por" else "en"
        return "$activity $prep $start"
    }

    suspend fun suggest(context: Context, sport: LiveSport,
                        points: List<WorkoutRoutePoint>): String? {
        val origin=points.firstOrNull { it.isEstimated != true }
        val last=points.lastOrNull { it.isEstimated != true }
        val pin=if(origin==null) {
            // No solicitar un permiso nuevo para crear un título.
            val tracker=WorkoutLocationTracker(context)
            if(!tracker.hasPermission()) return null
            tracker.capturePin()
        } else null
        val lat=origin?.latitude ?: pin?.latitude ?: return null
        val lon=origin?.longitude ?: pin?.longitude ?: return null
        val city=city(context, lat, lon) ?: return null
        val end=if(last!=null && origin!=null &&
            dev.repera.domain.LiveGPXTurnDetection.distance(origin,last)>2_000) {
            city(context,last.latitude,last.longitude)
        } else null
        return format(sport,city,end)
    }

    private suspend fun city(context: Context,lat:Double,lon:Double): String? {
        if(!lat.isFinite() || !lon.isFinite() || !Geocoder.isPresent()) return null
        return suspendCancellableCoroutine { continuation ->
            val coder=Geocoder(context,Locale.forLanguageTag("es-ES"))
            coder.getFromLocation(lat,lon,1,object:Geocoder.GeocodeListener {
                override fun onGeocode(addresses: MutableList<Address>) {
                    if(continuation.isActive)
                        continuation.resume(addresses.firstOrNull()?.locality
                            ?.trim()?.takeIf { it.isNotBlank() })
                }
                override fun onError(errorMessage: String?) {
                    if(continuation.isActive) continuation.resume(null)
                }
            })
        }
    }
}
