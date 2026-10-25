package dev.repera.mobile

/** An A→B→A login still invalidates asynchronous results started by the first A. */
internal class AccountRevisionGate {
    var revision=0L;private set
    private var account:String?=null
    fun update(next:String?):Boolean {
        if(account==next) return false
        account=next;revision++;return true
    }
    fun accepts(owner:String,stamp:Long)=account==owner && revision==stamp
}
