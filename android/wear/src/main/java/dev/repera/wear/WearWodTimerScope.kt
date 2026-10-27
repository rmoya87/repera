package dev.repera.wear
import org.json.JSONObject
/** DataItems for active session and timer can arrive in either order. */
internal fun wearTimerMatches(timer:JSONObject?,sessionId:String,oneBasedExerciseIndex:Int):Boolean =
 timer!=null && timer.optString("sessionId")==sessionId && timer.optInt("blockIndex",-1)==oneBasedExerciseIndex-1

/** Session-level transient state must not carry into another workout. */
internal fun wearSessionChanged(previous:String?,next:String):Boolean=previous!=next
