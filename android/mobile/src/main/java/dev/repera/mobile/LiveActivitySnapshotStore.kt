package dev.repera.mobile

import dev.repera.domain.LiveActivityState
import dev.repera.domain.WorkoutRoutePoint
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

/** Checkpoint privado, independiente del espejo y de Salud. El dueño del
 * servicio elige archivo por cuenta; no inicia sensores al leer ni restaurar. */
internal class LiveActivitySnapshotStore(private val file: File) {
    @Synchronized fun write(snapshot: LiveActivityState.Snapshot) {
        file.parentFile?.mkdirs()
        val temp = File(file.path + ".tmp")
        try {
            temp.outputStream().use { out -> out.write(encode(snapshot).toString().toByteArray());out.fd.sync() }
            Files.move(temp.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)
        } catch (e: Exception) { temp.delete();throw e }
    }
    @Synchronized fun read(): LiveActivityState.Snapshot? {
        if (!file.exists()) return null
        // No borrar un archivo corrupto silenciosamente: se conserva para
        // recuperación y la UI puede informar del problema sin arrancar GPS.
        return decode(JSONObject(file.readText())).also { s ->
            require(dev.repera.domain.LiveSport.byId(s.sportID) != null && s.phase != LiveActivityState.Phase.IDLE)
            require(s.gpsSessionID.isNotBlank() && s.pausedSeconds.isFinite() && s.pausedSeconds >= 0)
            require(s.distanceMeters.isFinite() && s.distanceMeters >= 0 && s.savedMillis >= s.startedMillis)
            require(s.lastBoundarySeconds.isFinite() && s.lastBoundarySeconds >= 0)
            require(s.splitsSeconds.all { it.isFinite() && it > 0 })
            require(s.points.all { it.latitude in -90.0..90.0 && it.longitude in -180.0..180.0 })
        }
    }
    @Synchronized fun clear() {
        if (file.exists()) check(file.delete()) { "No se pudo descartar la actividad guardada." }
    }
    private fun encode(s: LiveActivityState.Snapshot): JSONObject = JSONObject()
        .put("sport",s.sportID).put("phase",s.phase.name).put("startedMillis",s.startedMillis)
        .put("pausedMillis",s.pausedMillis ?: JSONObject.NULL).put("pausedSeconds",s.pausedSeconds)
        .put("distanceMeters",s.distanceMeters).put("savedMillis",s.savedMillis)
        .put("selectedRouteID",s.selectedRouteID ?: JSONObject.NULL).put("gpsSessionID",s.gpsSessionID)
        .put("splitsSeconds",JSONArray(s.splitsSeconds)).put("lastBoundarySeconds",s.lastBoundarySeconds)
        .put("points",JSONArray(s.points.map { p -> JSONObject().put("id",p.id)
            .put("latitude",p.latitude).put("longitude",p.longitude).put("recordedAtEpochMs",p.recordedAtEpochMs)
            .put("speedMps",p.speedMps ?: JSONObject.NULL).put("altitudeMeters",p.altitudeMeters ?: JSONObject.NULL)
            .put("horizontalAccuracyMeters",p.horizontalAccuracyMeters ?: JSONObject.NULL)
            .put("verticalAccuracyMeters",p.verticalAccuracyMeters ?: JSONObject.NULL) }))
    private fun decode(j: JSONObject): LiveActivityState.Snapshot {
        val points=j.getJSONArray("points")
        val splits=j.optJSONArray("splitsSeconds") ?: JSONArray()
        return LiveActivityState.Snapshot(j.getString("sport"),LiveActivityState.Phase.valueOf(j.getString("phase")),
            j.getLong("startedMillis"),if (j.isNull("pausedMillis")) null else j.getLong("pausedMillis"),
            j.getDouble("pausedSeconds"),j.getDouble("distanceMeters"),
            (0 until points.length()).map { i -> val p=points.getJSONObject(i)
                fun measured(k: String)=p.optDouble(k,Double.NaN).takeIf { it.isFinite() }
                WorkoutRoutePoint(p.getInt("id"),p.getDouble("latitude"),p.getDouble("longitude"),
                    p.getLong("recordedAtEpochMs"),measured("speedMps"),measured("altitudeMeters"),
                    measured("horizontalAccuracyMeters"),measured("verticalAccuracyMeters")) },
            j.getLong("savedMillis"),j.optString("selectedRouteID").takeIf { it.isNotBlank() && it!="null" },
            (0 until splits.length()).map { splits.getDouble(it) },j.optDouble("lastBoundarySeconds",0.0),j.getString("gpsSessionID"))
    }
}
