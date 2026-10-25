package dev.repera.domain
/** WorkoutView.saveSet: warmup45s, drops20s, rest-pause max45/default÷2. */
object StrengthRestPolicy {
    fun seconds(defaultSeconds:Int,warmup:Boolean=false,kind:String="normal"):Int = when {
        warmup -> 45
        kind=="dropset" -> 20
        kind=="restpause" -> maxOf(45,defaultSeconds/2)
        else -> defaultSeconds
    }
}
