package dev.repera.contracts

fun main() {
 val a=mapAgendaEvent(mapOf("id" to "x","kind" to "training","date" to "2026-10-19","title" to "Fuerza","deep_link" to "repera://diary/x"))
 val b=mapAgendaEvent(mapOf("id" to "y","kind" to "class","date" to "2026-10-19","title" to "Clase","deep_link" to "repera://classes/y"))
 val appointment=mapAgendaEvent(mapOf("id" to "pt-1","kind" to "appointment","date" to "2026-10-19","title" to "Sesión personal","booking_id" to "booking-1","deep_link" to "repera://appointments/appointment-1"))
 val a2=a.copy(title="Fuerza actualizada")
 val bad=a.copy(id="bad",deepLink="https://evil.example")
 val merged=BusinessAgendaMerger.merge(listOf(a,b),listOf(a2,bad,appointment))
 check(merged.size==3)
 check(merged.single{it.id=="x"}.title=="Fuerza actualizada")
 check(merged.single{it.id=="pt-1"}.kind==AgendaKind.APPOINTMENT)
 check(merged.single{it.id=="pt-1"}.bookingId=="booking-1")
 check(merged.all { it.hasSafeDeepLink() })
 check(!appointment.copy(deepLink="https://external.example").hasSafeDeepLink())
 println("Android contract checks passed: 6")
}
