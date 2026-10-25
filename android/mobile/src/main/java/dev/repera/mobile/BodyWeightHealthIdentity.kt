package dev.repera.mobile
import java.time.Instant
import java.time.ZoneId
/** Stable per account/calendar day: retries update our record, never another app's sample. */
internal object BodyWeightHealthIdentity {
 fun recordId(owner:String,millis:Long,zone:ZoneId=ZoneId.systemDefault()):String {
  require(owner.isNotBlank())
  val digest=java.security.MessageDigest.getInstance("SHA-256").digest(owner.toByteArray())
   .joinToString("") {"%02x".format(it)}
  val day=Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
  return "repera-weight:$digest:$day"
 }
}
