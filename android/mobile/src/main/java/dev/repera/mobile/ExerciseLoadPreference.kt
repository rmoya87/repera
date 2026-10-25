package dev.repera.mobile
import org.json.JSONObject
import kotlin.math.floor

internal object ExerciseLoadPreference {
    fun tested(state:JSONObject,id:String):Double? = state.optJSONObject("exerciseLoadPrefs")?.optJSONObject(id)
        ?.optDouble("testedOneRMKg")?.takeIf {it.isFinite() && it>0}
    fun setTested(state:JSONObject,id:String,value:Double?) {
        require(value==null || value.isFinite() && value>0)
        val preferences=state.optJSONObject("exerciseLoadPrefs") ?: JSONObject().also {state.put("exerciseLoadPrefs",it)}
        val preference=preferences.optJSONObject(id) ?: JSONObject().also {preferences.put(id,it)}
        if(value==null) preference.remove("testedOneRMKg") else preference.put("testedOneRMKg",floor(value*10+0.5)/10)
    }
    fun all(state:JSONObject):Map<String,Double> {
        val prefs=state.optJSONObject("exerciseLoadPrefs") ?: return emptyMap()
        return prefs.keys().asSequence().mapNotNull {id -> tested(state,id)?.let {id to it}}.toMap()
    }
}
