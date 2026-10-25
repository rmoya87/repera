package dev.repera.mobile

import android.content.Context
import dev.repera.domain.LiveGPXParser
import dev.repera.domain.LiveGPXTurnDetection
import dev.repera.domain.LiveSport
import dev.repera.domain.WorkoutRoutePoint
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.util.UUID

internal data class LiveSavedRoute(
    val id: String = UUID.randomUUID().toString(), val title: String,
    val points: List<WorkoutRoutePoint>, val sportID: String? = null,
    val isFavorite: Boolean = false, val createdAtMillis: Long = System.currentTimeMillis()
) {
    val distanceKm: Double get() = LiveGPXTurnDetection.cumulative(points).lastOrNull()?.div(1000) ?: 0.0
    val sportTitle: String get() = sportID?.let(LiveSport::byId)?.title ?: "Sin deporte"
}

/** Biblioteca OFFLINE por cuenta. Un solo archivo atómico incluye tombstones:
 * ni fallo de escritura ni recuperación de sesiones resucita una ruta borrada.
 * No se añade a sincronización remota ni se envía ninguna coordenada. */
internal class LiveRoutesStore(private val file: File) {
    constructor(context: Context, accountID: String) : this(File(context.filesDir,
        "users/" + MessageDigest.getInstance("SHA-256").digest(accountID.toByteArray())
            .joinToString("") { "%02x".format(it) } + "/live_routes.json"))

    private var routesValue = emptyList<LiveSavedRoute>()
    private var deleted = emptySet<String>()
    init {
        if (file.exists()) {
            val root = JSONObject(file.readText())
            val list = root.optJSONArray("routes") ?: JSONArray()
            routesValue = (0 until list.length()).map { decode(list.getJSONObject(it)) }
            val tombstones = root.optJSONArray("deletedIDs") ?: JSONArray()
            deleted = (0 until tombstones.length()).map { tombstones.getString(it) }.toSet()
        }
    }
    val routes: List<LiveSavedRoute> @Synchronized get() = routesValue.toList()
    val latestRoutes: List<LiveSavedRoute> get() = routes.sortedByDescending { it.createdAtMillis }
    val favoriteRoutes: List<LiveSavedRoute> get() = latestRoutes.filter { it.isFavorite }

    fun recentRoutes(sessions: List<dev.repera.domain.LiveSportHistory.LiveSession>): List<LiveSavedRoute> {
        val last = sessions.filter { it.finishedEpochMillis != null && it.liveRouteID != null }
            .groupBy { it.liveRouteID }.mapValues { (_, group) ->
                group.maxOf { it.startedEpochMillis ?: it.finishedEpochMillis ?: Long.MIN_VALUE }
            }
        return routes.sortedByDescending { maxOf(it.createdAtMillis, last[it.id] ?: Long.MIN_VALUE) }
    }
    @Synchronized fun addGPX(data: ByteArray, name: String): LiveSavedRoute {
        val route = LiveSavedRoute(title = name, points = LiveGPXParser.parse(data))
        commit(listOf(route) + routesValue, deleted); return route
    }
    @Synchronized fun addRecordedRoute(title: String, points: List<WorkoutRoutePoint>, sportID: String,
        favorite: Boolean = false, startedMillis: Long = System.currentTimeMillis()): LiveSavedRoute {
        require(points.size >= 2) { "Este recorrido no contiene al menos dos puntos." }
        val route = LiveSavedRoute(title = title, points = points, sportID = sportID,
            isFavorite = favorite, createdAtMillis = startedMillis)
        commit(listOf(route) + routesValue, deleted); return route
    }
    @Synchronized fun update(id: String, title: String, sportID: String?) {
        if (routesValue.none { it.id == id }) return
        require(title.trim().isNotEmpty()) { "La ruta necesita un nombre." }
        commit(routesValue.map { if (it.id == id) it.copy(title = title.trim(), sportID = sportID) else it }, deleted)
    }
    @Synchronized fun setFavorite(id: String, favorite: Boolean) {
        if (routesValue.none { it.id == id }) return
        commit(routesValue.map { if (it.id == id) it.copy(isFavorite = favorite) else it }, deleted)
    }
    @Synchronized fun remove(id: String) = commit(routesValue.filterNot { it.id == id }, deleted + id)

    /** Recuperación local de rutas de sesiones sincronizadas, sin inventar favoritos. */
    @Synchronized fun recoverFromSessions(candidates: List<LiveSavedRoute>) {
        val known = (routesValue.map { it.id } + deleted).toMutableSet()
        val recovered = candidates.sortedBy { it.createdAtMillis }.filter { it.points.size >= 2 && known.add(it.id) }
            .map { it.copy(isFavorite = false, createdAtMillis = Long.MIN_VALUE) }
        if (recovered.isNotEmpty()) commit(routesValue + recovered, deleted)
    }
    private fun commit(next: List<LiveSavedRoute>, tombstones: Set<String>) {
        file.parentFile?.mkdirs()
        val temp = File(file.path + ".tmp")
        try {
            temp.outputStream().use { out ->
                out.write(JSONObject().put("routes", JSONArray(next.map(::encode)))
                    .put("deletedIDs", JSONArray(tombstones.toList())).toString().toByteArray())
                out.fd.sync()
            }
            Files.move(temp.toPath(), file.toPath(), StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
        } catch (e: Exception) { temp.delete(); throw e }
        routesValue = next; deleted = tombstones
    }
    private fun encode(route: LiveSavedRoute): JSONObject = JSONObject()
        .put("id", route.id).put("title", route.title).put("sportID", route.sportID ?: JSONObject.NULL)
        .put("isFavorite", route.isFavorite).put("createdAtMillis", route.createdAtMillis)
        .put("points", JSONArray(route.points.map { p -> JSONObject().put("id", p.id)
            .put("latitude", p.latitude).put("longitude", p.longitude).put("recordedAtEpochMs", p.recordedAtEpochMs)
            .put("speedMps", p.speedMps ?: JSONObject.NULL).put("altitudeMeters", p.altitudeMeters ?: JSONObject.NULL) }))
    private fun decode(j: JSONObject): LiveSavedRoute {
        val points = j.getJSONArray("points")
        return LiveSavedRoute(j.getString("id"), j.getString("title"),
            (0 until points.length()).map { i -> val p = points.getJSONObject(i)
                WorkoutRoutePoint(p.optInt("id", i), p.getDouble("latitude"), p.getDouble("longitude"),
                    p.optLong("recordedAtEpochMs"), p.optDouble("speedMps", Double.NaN).takeIf { it.isFinite() },
                    p.optDouble("altitudeMeters", Double.NaN).takeIf { it.isFinite() }) },
            j.optString("sportID").takeIf { it.isNotBlank() && it != "null" },
            j.optBoolean("isFavorite", false), if (j.has("createdAtMillis")) j.getLong("createdAtMillis") else Long.MIN_VALUE)
    }
}
