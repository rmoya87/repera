package dev.repera.mobile
import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject

/** Device-local explicit choice, excluded from snapshots, Drive and Android backup. */
internal class PrivateRecoverySettings(context:Context) {
 private val file=AtomicFile(java.io.File(context.noBackupFilesDir,"repera-private-recovery.json"))
 fun sleepEnabled():Boolean=read().optBoolean("sleepEnabled",false)
 fun sleepDecisionMade():Boolean=read().optBoolean("sleepDecisionMade",false)
 fun cycleEnabled():Boolean=read().optBoolean("cycleEnabled",false)
 fun cycleDecisionMade():Boolean=read().optBoolean("cycleDecisionMade",false)
 private fun read():JSONObject=synchronized(lock) {
  runCatching {file.openRead().bufferedReader().use {JSONObject(it.readText())}}.getOrElse {JSONObject()}
 }
 fun setSleep(enabled:Boolean)=writeChoice("sleep",enabled)
 fun setCycle(enabled:Boolean)=writeChoice("cycle",enabled)
 private fun writeChoice(kind:String,enabled:Boolean)=synchronized(lock) {
  val updated=read().put("${kind}Enabled",enabled).put("${kind}DecisionMade",true)
  val stream=file.startWrite()
  try {
   stream.write(updated.toString().toByteArray())
   file.finishWrite(stream)
  } catch(error:Exception) {file.failWrite(stream);throw error}
 }
 companion object {private val lock=Any()}
}
