package dev.repera.mobile
import org.json.JSONArray
import org.json.JSONObject

/** Shared AppSettings key; independent of saved-routine favorite flags. */
internal object WodTemplateFavorites {
    fun read(state:JSONObject):Set<String> {
        val array=state.optJSONObject("settings")?.optJSONArray("favoriteWODTemplateIds") ?: return emptySet()
        return (0 until array.length()).mapNotNull {array.optString(it).takeIf {id ->id.isNotBlank()}}.toSet()
    }
    fun toggle(state:JSONObject,id:String) {
        require(dev.repera.domain.CatalogWods.template(id)!=null) {"WOD no encontrado"}
        val ids=read(state).toMutableSet()
        if(!ids.remove(id)) ids.add(id)
        val settings=state.optJSONObject("settings") ?: JSONObject().also {state.put("settings",it)}
        settings.put("favoriteWODTemplateIds",JSONArray(ids.toList()))
    }
}
