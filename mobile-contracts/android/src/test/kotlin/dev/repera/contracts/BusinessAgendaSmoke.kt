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

 // Mirror of BusinessAgendaTests.testSourceDefaultAndOrderingMatchKotlin (Swift).
 val events=listOf(
  mapAgendaEvent(mapOf("id" to "t","kind" to "training","date" to "2026-10-19","title" to "Fuerza","deep_link" to "repera://diary/t")),
  mapAgendaEvent(mapOf("id" to "c","kind" to "class","date" to "2026-10-19","title" to "Clase","source" to "center","deep_link" to "repera://classes/c")),
  mapAgendaEvent(mapOf("id" to "a","kind" to "appointment","date" to "2026-10-19","title" to "PT","source" to "","deep_link" to "repera://appointments/a")))
 check(events.map { it.source }==listOf("professional","center","professional"))
 check(BusinessAgendaMerger.merge(emptyList(),events).map { it.id }==listOf("a","c","t"))

 val response=mapAgendaResponse(mapOf("schema_version" to 1,"org_id" to "org","client_id" to "c1","cursor" to null,
  "events" to listOf(mapOf("id" to "a1","kind" to "training","date" to "2026-10-19","title" to "Fuerza","source" to "professional",
   "assignment_id" to "a1","booking_id" to null,"exercise_text" to "3x8","deep_link" to "repera://diary/a1"))))
 check(response.schemaVersion==1 && response.events.single().assignmentId=="a1" && response.cursor==null)
 check(runCatching { mapAgendaEvent(mapOf("id" to "z","kind" to "unknown","date" to "d","title" to "t","deep_link" to "repera://diary/z")) }.isFailure)
 println("Android contract checks passed: 10")
}
