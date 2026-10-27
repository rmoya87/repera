package dev.repera.domain

import java.time.LocalDate

data class WeeklyWorkoutDay(val date:LocalDate,val completedCount:Int,val planned:Boolean)

object WeeklyWorkoutProgress {
    data class Plan(val scheduledDate:LocalDate?=null,val isoWeekday:Int?=null)
    fun days(selectedDay:LocalDate,mondayFirst:Boolean,counts:Map<LocalDate,Int>,plans:List<Plan>):List<WeeklyWorkoutDay> {
        val start=StatsEngine.startOfWeek(selectedDay,mondayFirst)
        return (0L..6L).map {offset ->
            val date=start.plusDays(offset)
            WeeklyWorkoutDay(date,(counts[date] ?: 0).coerceAtLeast(0),plans.any {
                if(it.scheduledDate!=null) it.scheduledDate==date else it.isoWeekday==date.dayOfWeek.value
            })
        }
    }
}
