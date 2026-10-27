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
 @Test fun archivedCatalogEntriesCannotCaptureScans() {
  val result=BoardScanLiteParser.parse("3 rounds\n10 Odd remote label",listOf(
   CatalogExercise("archived","Odd remote label",isCatalogArchived=true),
   CatalogExercise("active","Official row",listOf("Odd remote label"))))
  assertTrue(result.blocks.flatMap {it.movements}.any {it.exerciseId=="active"})
 }
}
