package dev.repera.mobile
import org.json.JSONObject

/** Local snapshot profile. Selecting a photo does not silently upload it publicly. */
data class ProfileSettings(val displayName:String?=null,val avatarJPEG:String?=null) {
    companion object {
        fun read(state:JSONObject):ProfileSettings {
            val s=state.optJSONObject("settings") ?: JSONObject()
            return ProfileSettings(s.optString("profileDisplayName").takeIf {it.isNotBlank() && it!="null"},
                s.optString("profileAvatarJPEG").takeIf {it.isNotBlank() && it!="null"})
        }
        fun apply(state:JSONObject,value:ProfileSettings) {
            require(value.displayName==null || value.displayName.trim().length<=100)
            require(value.avatarJPEG==null || value.avatarJPEG.length<=300_000)
            val s=state.optJSONObject("settings") ?: JSONObject().also {state.put("settings",it)}
            value.displayName?.trim()?.takeIf {it.isNotEmpty()}?.let {s.put("profileDisplayName",it)} ?: s.remove("profileDisplayName")
            value.avatarJPEG?.let {s.put("profileAvatarJPEG",it)} ?: s.remove("profileAvatarJPEG")
        }
    }
}
