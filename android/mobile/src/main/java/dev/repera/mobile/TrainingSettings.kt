package dev.repera.mobile

import org.json.JSONObject
import dev.repera.domain.ProgressionPolicy

/** Apple AppSettings wire keys. Unknown fields remain owned by the snapshot. */
data class TrainingSettings(
    val weekStartsOnMonday:Boolean = true,
    val defaultRestSeconds:Int = 90,
    val defaultProgression:String = "linear",
    val weightIncrementKg:Double = 2.5,
    val scheduleMode:String="fixedWeek",
    val restSoundEnabled:Boolean=true,
    val restHapticEnabled:Boolean=true
) {
    companion object {
        fun read(state:JSONObject):TrainingSettings {
            val s=state.optJSONObject("settings") ?: JSONObject()
            return TrainingSettings(s.optString("weekStartsOn","monday")!="sunday",
                s.optInt("defaultRestSeconds",90).coerceIn(30,300),
                ProgressionPolicy.fromWire(s.optString("defaultProgression","linear"))?.wire ?: "linear",
                s.optDouble("weightIncrementKg",2.5).takeIf { it.isFinite() && it in 0.5..10.0 } ?: 2.5,
                s.optString("scheduleMode","fixedWeek").takeIf { it in listOf("fixedWeek","rotation") } ?: "fixedWeek",s.optBoolean("restSoundEnabled",true),s.optBoolean("restHapticEnabled",true))
        }
        fun apply(state:JSONObject,value:TrainingSettings) {
            require(value.defaultRestSeconds in 30..300)
            require(value.weightIncrementKg.isFinite() && value.weightIncrementKg in 0.5..10.0)
            require(ProgressionPolicy.fromWire(value.defaultProgression)!=null)
            require(value.scheduleMode in listOf("fixedWeek","rotation"))
            val s=state.optJSONObject("settings") ?: JSONObject().also { state.put("settings",it) }
            s.put("weekStartsOn",if(value.weekStartsOnMonday) "monday" else "sunday")
            s.put("defaultRestSeconds",value.defaultRestSeconds)
            s.put("defaultProgression",value.defaultProgression)
            s.put("weightIncrementKg",value.weightIncrementKg)
            s.put("scheduleMode",value.scheduleMode)
            s.put("restSoundEnabled",value.restSoundEnabled);s.put("restHapticEnabled",value.restHapticEnabled)
            if(value.scheduleMode=="rotation" && state.optJSONObject("rotation")==null) {
                val routines=state.optJSONArray("routines") ?: org.json.JSONArray()
                RotationSettings.write(state,dev.repera.domain.RotationPlan(java.util.UUID.randomUUID().toString(),routineIds=
                    (0 until routines.length()).map { routines.getJSONObject(it).getString("id") }))
            }
        }
    }
}

internal fun trainingSettingsForAccount(context:android.content.Context,accountID:String?):TrainingSettings =
    if(accountID.isNullOrBlank()) TrainingSettings() else runCatching {
        LocalSnapshotStore(context,accountID).read()?.let { TrainingSettings.read(JSONObject(String(it))) }
    }.getOrNull() ?: TrainingSettings()
