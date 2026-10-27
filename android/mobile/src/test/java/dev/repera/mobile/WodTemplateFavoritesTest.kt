package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class WodTemplateFavoritesTest {
 @Test fun togglePreservesOtherSettingsAndNeverCreatesRoutine() {
  val state=JSONObject().put("settings",JSONObject().put("unknown",123)).put("routines",JSONArray())
  WodTemplateFavorites.toggle(state,"fran")
  assertEquals(setOf("fran"),WodTemplateFavorites.read(state))
  assertEquals(123,state.getJSONObject("settings").getInt("unknown"))
  assertEquals(0,state.getJSONArray("routines").length())
  WodTemplateFavorites.toggle(state,"fran");assertTrue(WodTemplateFavorites.read(state).isEmpty())
 }
 @Test fun unknownImportedIdsArePreservedWhenTogglingKnownTemplate() {
  val state=JSONObject().put("settings",JSONObject().put("favoriteWODTemplateIds",JSONArray().put("future")))
  WodTemplateFavorites.toggle(state,"fran");assertEquals(setOf("future","fran"),WodTemplateFavorites.read(state))
  val before=state.toString()
  assertThrows(IllegalArgumentException::class.java) {WodTemplateFavorites.toggle(state,"invalid")}
  assertEquals(before,state.toString())
 }
}
