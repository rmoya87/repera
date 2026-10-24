package dev.repera.mobile

import android.content.Context
import dev.repera.domain.RecentPlaces
import dev.repera.domain.WorkoutLocationPin
import org.json.JSONArray
import org.json.JSONObject

/** Persistencia de lugares recientes (RecentPlacesStore iOS, clave homónima
 *  "repera.places.recent.v1"; la política de dedupe/límite vive en dominio). */
class RecentPlacesStore(context: Context, accountId: String) {
    private val prefs = context.getSharedPreferences(
        "repera.places.recent.$accountId", Context.MODE_PRIVATE)

    fun load(): List<WorkoutLocationPin> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return runCatching {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                WorkoutLocationPin(
                    latitude = o.getDouble("latitude"),
                    longitude = o.getDouble("longitude"),
                    recordedAtEpochMs = o.optLong("recordedAtEpochMs"),
                    name = o.optString("name").takeIf { it.isNotBlank() },
                    mapItemIdentifier = o.optString("mapItemIdentifier").takeIf { it.isNotBlank() },
                    pointOfInterestCategory = o.optString("pointOfInterestCategory").takeIf { it.isNotBlank() }
                )
            }
        }.getOrDefault(emptyList())
    }

    fun remember(pin: WorkoutLocationPin) {
        val next = RecentPlaces.remember(load(), pin)
        val arr = JSONArray()
        for (p in next) {
            arr.put(JSONObject().apply {
                put("latitude", p.latitude)
                put("longitude", p.longitude)
                put("recordedAtEpochMs", p.recordedAtEpochMs)
                p.name?.let { put("name", it) }
                p.mapItemIdentifier?.let { put("mapItemIdentifier", it) }
                p.pointOfInterestCategory?.let { put("pointOfInterestCategory", it) }
            })
        }
        prefs.edit().putString(KEY, arr.toString()).apply()
    }

    private companion object {
        /** Mismo nombre de clave que en iOS para trazabilidad del inventario. */
        const val KEY = "repera.places.recent.v1"
    }
}
