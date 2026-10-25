package dev.repera.mobile

import org.json.JSONObject
import dev.repera.domain.ProgressionPolicy

/** Apple AppSettings wire keys. Unknown fields remain owned by the snapshot. */
data class TrainingSettings(
    val weekStartsOnMonday:Boolean = true,
    val defaultRestSeconds:Int = 90,
    val defaultProgression:String = "linear",
    val weightIncrementKg:Double = 2.5
) {
    companion object {
        fun read(state:JSONObject):TrainingSettings {
            val s=state.optJSONObject("settings") ?: JSONObject()
            return TrainingSettings(s.optString("weekStartsOn","monday")!="sunday",
                s.optInt("defaultRestSeconds",90).coerceIn(30,300),
                ProgressionPolicy.fromWire(s.optString("defaultProgression","linear"))?.wire ?: "linear",
                s.optDouble("weightIncrementKg",2.5).takeIf { it.isFinite() && it in 0.5..10.0 } ?: 2.5)
        }
        fun apply(state:JSONObject,value:TrainingSettings) {
            require(value.defaultRestSeconds in 30..300 && value.defaultRestSeconds%15==0)
            require(value.weightIncrementKg.isFinite() && value.weightIncrementKg in 0.5..10.0 && value.weightIncrementKg*2%1==0.0)
            require(ProgressionPolicy.fromWire(value.defaultProgression)!=null)
            val s=state.optJSONObject("settings") ?: JSONObject().also { state.put("settings",it) }
            s.put("weekStartsOn",if(value.weekStartsOnMonday) "monday" else "sunday")
            s.put("defaultRestSeconds",value.defaultRestSeconds)
            s.put("defaultProgression",value.defaultProgression)
            s.put("weightIncrementKg",value.weightIncrementKg)
        }
    }
}
