package dev.repera.mobile

import dev.repera.domain.ExerciseInputMode

/** QuickLogSheet.defaultReps/defaultWeight/defaultDurationSeconds in Apple fc3ef7e1. */
internal object QuickLogDefaults {
 fun row(mode:ExerciseInputMode,unit:String,mobility:Boolean,hold:Boolean,last:LoadGuideSet?,repsOrMeters:Boolean=false):QuickLogRow = QuickLogRow(
  quantity=when {
   // Apple 1d1edc8b/f7109bd7 defaultReps: metros en recorridos empiezan en 20.
   repsOrMeters && unit=="meters" -> 20
   mode==ExerciseInputMode.MACHINE_WORK -> if(unit=="meters") 500 else 15
   hold -> 1
   mobility -> last?.reps ?: 8
   mode==ExerciseInputMode.REPS_AND_TIME -> last?.reps ?: 50
   else -> last?.reps ?: 8
  },
  weightKg=if(mode.showsWeight) last?.weightKg else null,
  durationSeconds=if(mode in setOf(ExerciseInputMode.MACHINE_WORK,ExerciseInputMode.REPS_AND_TIME))
   last?.durationSeconds ?: if(hold) 30 else 60 else null,
  unit=unit
 )
}
