package dev.repera.mobile

/** Biblioteca owns recurring plans and reusable templates. Dated workouts belong to Inicio. */
internal object DiaryCatalog {
    fun weekly(routines:List<RoutineEntry>)=routines.filter {it.scheduledDate==null && it.weekday in 1..7}
        .sortedBy {it.weekday}
    /** Apple scheduledRoutines(on:): every dated session of the date, ordered by time (no time last), title, id. */
    fun datedOn(routines:List<RoutineEntry>,date:java.time.LocalDate)=routines.filter {
        it.scheduledDate?.let {s ->runCatching {java.time.LocalDate.parse(s.take(10))}.getOrNull()}==date
    }.sortedWith(compareBy<RoutineEntry>({it.timeMinutes ?: Int.MAX_VALUE},{it.title.lowercase()},{it.id}))
    // A weekly assignment is still a reusable template, as in Apple's isLibraryRoutine.
    fun library(routines:List<RoutineEntry>)=routines.filter {it.scheduledDate==null}
        .sortedWith {a,b -> LibraryCollator.compare(a.title,b.title)}
}
