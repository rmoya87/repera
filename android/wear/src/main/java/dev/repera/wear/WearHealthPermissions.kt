package dev.repera.wear

/** Wear OS 6 replaces BODY_SENSORS with granular health permission for target36+. */
internal object WearHealthPermissions {
    fun heartRate(sdk:Int):String=if(sdk>=36) "android.permission.health.READ_HEART_RATE" else "android.permission.BODY_SENSORS"
    fun requested(sdk:Int):Array<String> = arrayOf(heartRate(sdk),"android.permission.ACTIVITY_RECOGNITION")
}
