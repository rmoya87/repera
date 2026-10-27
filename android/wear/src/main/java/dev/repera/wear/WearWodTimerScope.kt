package dev.repera.wear
import org.json.JSONObject
/** DataItems for active session and timer can arrive in either order. */
internal fun wearTimerMatches(timer:JSONObject?,sessionId:String,oneBasedExerciseIndex:Int):Boolean =
 timer!=null && timer.optString("sessionId")==sessionId && timer.optInt("blockIndex",-1)==oneBasedExerciseIndex-1

/** Session-level transient state must not carry into another workout. */
internal fun wearSessionChanged(previous:String?,next:String):Boolean=previous!=next

/** Apple 44713457: intervalo (0-based) que corresponde a una serie confirmada
 *  en el reloj, derivado del reloj del bloque publicado por el telefono.
 *  null si el reloj no corresponde a este bloque o el formato no registra
 *  series por movimiento (resultado global): ahi el reloj no registra. */
internal fun wearWodIntervalIndex(timer:JSONObject?,sessionId:String,
    oneBasedExerciseIndex:Int,elapsedSeconds:Int):Int? {
    if(!wearTimerMatches(timer,sessionId,oneBasedExerciseIndex)) return null
    val format=dev.repera.domain.WodFormat.fromWire(timer!!.optString("format")) ?: return null
    if(format.capture!=dev.repera.domain.ResultCapture.PER_MOVEMENT_SETS) return null
    val spec=dev.repera.domain.WodClockSpec(format,
        blockTimeCapMinutes=timer.optInt("timeCapMinutes").takeIf{timer.has("timeCapMinutes")&&!timer.isNull("timeCapMinutes")},
        intervalSeconds=timer.optInt("intervalSeconds").takeIf{timer.has("intervalSeconds")&&!timer.isNull("intervalSeconds")},
        rounds=timer.optInt("rounds").takeIf{timer.has("rounds")&&!timer.isNull("rounds")},
        workSeconds=timer.optInt("workSeconds").takeIf{timer.has("workSeconds")&&!timer.isNull("workSeconds")},
        restSeconds=timer.optInt("restSeconds").takeIf{timer.has("restSeconds")&&!timer.isNull("restSeconds")})
    return dev.repera.domain.WodClock.activeIntervalIndex(spec,elapsedSeconds)
}

/** Apple 44713457 (confirmIntervalSet): descanso tras confirmar una serie WOD
 *  en el reloj. Tabata: blockRestSeconds (10 por defecto, como Apple). Resto:
 *  lo que queda del intervalo en curso (0 si justo termina). null si el reloj
 *  no corresponde al bloque: el llamador decide (nunca inventar un descanso). */
internal fun wearWodRestAfterConfirmedSet(timer:JSONObject?,sessionId:String,
    oneBasedExerciseIndex:Int,elapsedSeconds:Int):Int? {
    if(!wearTimerMatches(timer,sessionId,oneBasedExerciseIndex)) return null
    val format=dev.repera.domain.WodFormat.fromWire(timer!!.optString("format")) ?: return null
    if(format==dev.repera.domain.WodFormat.TABATA)
        return (if(timer.has("restSeconds")&&!timer.isNull("restSeconds"))
            timer.optInt("restSeconds") else 10).coerceAtLeast(0)
    val length=(if(timer.has("intervalSeconds")&&!timer.isNull("intervalSeconds"))
        timer.optInt("intervalSeconds") else 60).coerceAtLeast(1)
    val remainder=elapsedSeconds.coerceAtLeast(0)%length
    return if(remainder==0) 0 else length-remainder
}
