package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class WodExerciseResolutionTest {
 @Test fun canonicalOrRawMovementReusesCatalogIdentity() {
  val ex=ExerciseEntry("known","Thruster",true,true)
  assertEquals("known",resolveWodExercise("thruster",listOf(ex),emptyMap()).id)
 }
 @Test fun unknownMovementIsOnlyAnEphemeralPreview() {
  val catalog=mutableListOf<ExerciseEntry>()
  val resolved=resolveWodExercise("Movimiento desconocido zzz",catalog,emptyMap())
  assertTrue(resolved.isCustom);assertTrue(catalog.isEmpty())
  assertTrue(resolved.id.startsWith("wod-preview:"))
 }
}
