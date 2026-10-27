package dev.repera.mobile
import org.json.JSONObject

/**
 * Watch asks the phone to jump to another exercise (Apple WatchSessionHub.selectBlock(startingAt:)).
 * Bound to the session and to the index the watch was showing, so a delayed message cannot move a
 * different session or a session that already advanced. Local contract only: the phone applies it
 * with the same repository call as the on-phone selector; not executed against a real watch.
 */
internal data class WearSelectCommand(val sessionId:String,val fromIndex:Int,val toIndex:Int) {
    fun targets(activeId:String?,activeIndex:Int?,total:Int?):Boolean=
        activeId==sessionId && activeIndex==fromIndex && total!=null && toIndex in 0 until total && toIndex!=fromIndex
    companion object {
        private fun intOf(body:JSONObject,key:String):Int? {
            val n=body.opt(key) as? Number ?: return null
            if(n.toDouble()!=n.toInt().toDouble() || n.toInt()<0) return null
            return n.toInt()
        }
        fun parse(bytes:ByteArray):WearSelectCommand?=runCatching {
            val body=JSONObject(bytes.toString(Charsets.UTF_8))
            val id=body.optString("sessionId").takeIf {it.isNotBlank()} ?: return null
            WearSelectCommand(id,intOf(body,"fromIndex") ?: return null,intOf(body,"toIndex") ?: return null)
        }.getOrNull()
    }
}
