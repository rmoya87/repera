package dev.repera.mobile
import org.json.JSONObject

/** Exact optional AppSettings fields/ranges from Apple HealthGoalsView. */
data class HealthGoals(val steps:Int?=null,val energyKcal:Int?=null,val minutes:Int?=null,val weeklyWorkouts:Int?=null,val weightKg:Double?=null) {
    companion object {
        fun read(state:JSONObject):HealthGoals {
            val s=state.optJSONObject("settings") ?: JSONObject()
            fun number(key:String,range:IntRange)=s.optInt(key).takeIf {s.has(key) && !s.isNull(key) && it in range}
            return HealthGoals(number("dailyStepsGoal",100..100_000),number("dailyActiveEnergyGoalKcal",10..10_000),
                number("dailyWorkoutMinutesGoal",1..1440),number("weeklyWorkoutGoal",1..21),
                s.optDouble("bodyWeightGoalKg").takeIf {it.isFinite() && it in 20.0..350.0})
        }
        fun apply(state:JSONObject,value:HealthGoals) {
            require(value.steps==null || value.steps in 100..100_000)
            require(value.energyKcal==null || value.energyKcal in 10..10_000)
            require(value.minutes==null || value.minutes in 1..1440)
            require(value.weeklyWorkouts==null || value.weeklyWorkouts in 1..21)
            require(value.weightKg==null || value.weightKg.isFinite() && value.weightKg in 20.0..350.0)
            val s=state.optJSONObject("settings") ?: JSONObject().also {state.put("settings",it)}
            listOf("dailyStepsGoal" to value.steps,"dailyActiveEnergyGoalKcal" to value.energyKcal,
                "dailyWorkoutMinutesGoal" to value.minutes,"weeklyWorkoutGoal" to value.weeklyWorkouts,
                "bodyWeightGoalKg" to value.weightKg).forEach {(key,v) -> if(v==null) s.remove(key) else s.put(key,v)}
        }
    }
}
