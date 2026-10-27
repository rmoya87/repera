package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
import java.io.File

/**
 * Guardia ESTATICA (lee fuentes, JVM): Apple saveRoutine no limita bloques; solo la ruta IA tiene 1...12
 * (AITrainingInboxStore:321). No ejecuta el repositorio; la prueba de comportamiento es instrumentada y NO ejecutada.
 */
class RoutineBlockCapContractTest {
 private val repo=File("src/main/java/dev/repera/mobile/WorkoutRepository.kt").readText()
 @Test fun onlyTheAiPathPassesABlockCap() {
  val calls=Regex("""appendScannedRoutine\(state,title,blocks,schedule,(\w+),(\w+)\)""").findAll(repo).map {it.groupValues[2]}.toList()
  assertEquals(listOf("12","null"),calls.sorted())
  assertEquals(2,calls.size)
 }
 @Test fun draftValidationNoLongerHasAnUpperBlockBound() {
  assertFalse(repo.contains("blocks.size in 1..10"))
  assertFalse(repo.contains("entre 1 y 10 bloques"))
  assertTrue(repo.contains("La rutina necesita al menos un bloque"))
 }
}
