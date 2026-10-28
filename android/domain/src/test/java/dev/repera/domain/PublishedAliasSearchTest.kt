package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class PublishedAliasSearchTest {
 @Test fun publishedAliasMatchesBelowExactNameAndAboveDiscipline() {
  val aliases=listOf("Odd remote label")
  assertEquals(95,ExerciseAliasSearch.score("Odd remote label","Official name",emptyMap(),publishedAliases=aliases))
  assertEquals(100,ExerciseAliasSearch.score("Official name","Official name",emptyMap(),publishedAliases=listOf("Official name")))
  assertEquals(-1,ExerciseAliasSearch.score("Missing","Official name",emptyMap(),publishedAliases=aliases))
 }
 @Test fun newSupabaseAliasIsSearchableAndScannableWithoutCodeChanges() {
  // Espejo de Apple 4dde4f78/67311dbf: alias BXT-PRO publicado por Supabase.
  val aliases=listOf("BXT-PRO")
  assertEquals(95,ExerciseAliasSearch.score("BXT-PRO","Burpee to target",emptyMap(),publishedAliases=aliases))
  val blocks=BoardScanLiteParser.parse("AMRAP 9'\n6 BXT-PRO",listOf(
   CatalogExercise("btt","Burpee to target",aliases))).blocks
  assertEquals(1,blocks.size)
  assertEquals("btt",blocks[0].movements[0].exerciseId)
  assertEquals("Burpee to target",blocks[0].movements[0].name)
 }
 @Test fun archivedCatalogEntriesCannotCaptureScans() {
  val result=BoardScanLiteParser.parse("3 rounds\n10 Odd remote label",listOf(
   CatalogExercise("archived","Odd remote label",isCatalogArchived=true),
   CatalogExercise("active","Official row",listOf("Odd remote label"))))
  assertTrue(result.blocks.flatMap {it.movements}.any {it.exerciseId=="active"})
 }
}
