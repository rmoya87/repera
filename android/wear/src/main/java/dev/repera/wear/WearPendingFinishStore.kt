package dev.repera.wear
import android.content.Context
/** A finish tap is durable, but is not a phone save until the exact session is acknowledged. */
internal class WearPendingFinishStore(context:Context) {
 private val prefs=context.getSharedPreferences("repera.wear.finish-outbox",Context.MODE_PRIVATE)
 fun queue(sessionId:String) = synchronized(lock) {
  require(sessionId.isNotBlank())
  val old=sessionId()
  check(old==null || old==sessionId) {"Hay otra sesión pendiente de finalizar"}
  check(prefs.edit().putString("sessionId",sessionId).commit())
 }
 fun sessionId():String?=synchronized(lock) {prefs.getString("sessionId",null)?.takeIf {it.isNotBlank()}}
 fun acknowledge(sessionId:String) = synchronized(lock) {if(sessionId()==sessionId) clear()}
 fun clear() = synchronized(lock) {check(prefs.edit().clear().commit())}
 companion object {private val lock=Any()}
}
