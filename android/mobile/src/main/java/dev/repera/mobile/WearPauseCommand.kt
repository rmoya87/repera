package dev.repera.mobile
import org.json.JSONObject

/** A delayed control must never operate on a different active session. */
internal data class WearPauseCommand(val sessionId:String,val blockIndex:Int,val paused:Boolean) {
    fun targets(activeId:String?,activeIndex:Int?):Boolean=activeId==sessionId && activeIndex==blockIndex
    companion object {
        fun parse(bytes:ByteArray):WearPauseCommand?=runCatching {
            val body=JSONObject(bytes.toString(Charsets.UTF_8))
            val id=body.optString("sessionId").takeIf {it.isNotBlank()} ?: return null
            val index=body.opt("blockIndex") as? Number ?: return null
            if(index.toDouble()!=index.toInt().toDouble() || index.toInt()<0) return null
            val paused=body.opt("paused") as? Boolean ?: return null
            WearPauseCommand(id,index.toInt(),paused)
        }.getOrNull()
    }
}
