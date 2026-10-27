package dev.repera.mobile
/** One outstanding platform result. Never relabel an old callback with a newer owner. */
internal class PendingAccountRequest {
 data class Binding(val owner:String,val revision:Long)
 private var pending:Binding?=null
 fun begin(owner:String,revision:Long):Boolean {
  if(pending!=null) return false
  pending=Binding(owner,revision);return true
 }
 fun consume(owner:String?,revision:Long):Boolean {
  val binding=pending;pending=null
  return binding!=null && binding.owner==owner && binding.revision==revision
 }
 fun clear() {pending=null}
}
