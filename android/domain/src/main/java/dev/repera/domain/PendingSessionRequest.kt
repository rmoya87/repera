package dev.repera.domain

/** A system permission result belongs to the session that launched it, not the visible one now. */
class PendingSessionRequest {
    private data class Binding(val id:String,val revision:Long)
    private var pending:Binding?=null
    fun begin(id:String,revision:Long):Boolean {
        if(pending!=null) return false
        pending=Binding(id,revision);return true
    }
    fun consume(id:String?,revision:Long):Boolean {
        val old=pending;pending=null
        return old!=null && old.id==id && old.revision==revision
    }
}
