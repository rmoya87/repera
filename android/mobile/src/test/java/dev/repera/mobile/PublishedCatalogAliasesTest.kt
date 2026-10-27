package dev.repera.mobile

import dev.repera.domain.BoardScanLiteParser
import dev.repera.domain.CatalogExercise
import dev.repera.domain.ExerciseAliasSearch
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class PublishedCatalogAliasesTest {
    @Test fun payloadToPersistedAliasesToParserAndSearchWithoutChangingIdentity() {
        val ex=JSONObject().put("id","official").put("name","Official row").put("isFavorite",true)
        val remote=JSONObject().put("aliases",JSONArray().put("Odd historical label"))
        PublishedCatalogAliases.merge(ex,remote)
        val restored=JSONObject(ex.toString())
        val aliases=PublishedCatalogAliases.read(restored)
        assertEquals("official",restored.getString("id"));assertTrue(restored.getBoolean("isFavorite"))
        assertEquals(listOf("Odd historical label"),aliases)
        val scan=BoardScanLiteParser.parse("3 rounds\n10 Odd historical label",listOf(
            CatalogExercise("official","Official row",aliases)))
        assertTrue(scan.blocks.flatMap {it.movements}.any {it.exerciseId=="official"})
        assertEquals(95,ExerciseAliasSearch.score("Odd historical label","Official row",emptyMap(),publishedAliases=aliases))
    }
    @Test fun absentOrNullRemoteAliasesClearOldPublishedAliasesLikeApple() {
        for (remote in listOf(JSONObject(),JSONObject().put("aliases",JSONObject.NULL))) {
            val ex=JSONObject().put("searchAliases",JSONArray().put("stale"))
            PublishedCatalogAliases.merge(ex,remote)
            assertTrue(PublishedCatalogAliases.read(ex).isEmpty())
        }
    }
    @Test fun nonStringsCannotBecomeSearchInstructionsOrAliases() {
        val ex=JSONObject()
        PublishedCatalogAliases.merge(ex,JSONObject().put("aliases",JSONArray().put(5).put(JSONObject()).put("valid")))
        assertEquals(listOf("valid"),PublishedCatalogAliases.read(ex))
    }
}
