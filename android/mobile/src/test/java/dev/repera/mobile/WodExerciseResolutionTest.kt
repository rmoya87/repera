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

 @Test fun realPackagedAssetResolvesOfflineBttT2bWithoutChangingCatalog() {
  val seed=org.json.JSONArray(java.io.File("src/main/assets/catalog_seed.json").readText())
  val packaged=packagedWodExercises(seed)
  assertEquals(setOf("Burpee to target","Toes to bar"),packaged.map {it.name}.toSet())
  val catalog=listOf(ExerciseEntry("legacy","BTt",false,false,isCustom=true))
  for ((raw,official) in listOf("BTt" to "Burpee to target","T2B" to "Toes to bar")) {
   val result=resolveWodExercise(raw,catalog,emptyMap(),packaged)
   assertEquals(official,result.name);assertFalse(result.isCustom)
   assertTrue(packaged.any {it.id==result.id});assertEquals(1,catalog.size)
  }
 }
 @Test fun persistedAliasAndCanonicalPriorityUseActualDisplayResolver() {
  val provisional=ExerciseEntry("legacy","BTt",false,false)
  val wrong=ExerciseEntry("wrong","Different",false,false,searchAliases=listOf("BTt"))
  val official=ExerciseEntry("real","Burpee to target",false,false)
  assertEquals("real",resolveWodExercise("BTt",listOf(provisional,wrong,official),emptyMap()).id)
  val published=ExerciseEntry("row","Official row",false,false,searchAliases=listOf("Old row"))
  assertEquals("row",resolveWodExercise("Old row",listOf(published),emptyMap()).id)
 }
}
