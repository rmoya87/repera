package dev.repera.contracts

fun main() {
 val a=mapAgendaEvent(mapOf("id" to "x","kind" to "training","date" to "2026-10-19","title" to "Fuerza","deep_link" to "repera://diary/x"))
 val b=mapAgendaEvent(mapOf("id" to "y","kind" to "class","date" to "2026-10-19","title" to "Clase","deep_link" to "repera://classes/y"))
 val a2=a.copy(title="Fuerza actualizada")
 val bad=a.copy(id="bad",deepLink="https://evil.example")
 val merged=BusinessAgendaMerger.merge(listOf(a,b),listOf(a2,bad))
 check(merged.size==2)
 check(merged.single{it.id=="x"}.title=="Fuerza actualizada")
 check(merged.all { it.hasSafeDeepLink() })
 println("Android contract tests passed: 3")
}