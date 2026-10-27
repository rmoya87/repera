package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
class WodLibraryHistoryTest {
 @Test fun fullArchiveRankAndFreeEndpointsAreLiteralNotChronological() {
  val workouts=JSONArray()
  for(i in 0..24) workouts.put(JSONObject().put("wodResults",JSONArray().put(JSONObject().put("id","$i")
   .put("wodTemplateId","fran").put("elapsedSeconds",100+i))))
  val rows=WodLibraryHistory.read(JSONObject().put("workouts",workouts))["fran"]!!
  assertEquals(25,rows.size);assertEquals(listOf("0","24"),WodLibraryHistory.visible(rows,false).map {it.id})
  assertEquals(25,WodLibraryHistory.visible(rows,true).size)
 }
 @Test fun repetitionsRankDescendingAndSingleBestAppearsOnce() {
  val workouts=JSONArray().put(JSONObject().put("wodResults",JSONArray()
   .put(JSONObject().put("id","low").put("wodTemplateId","cindy").put("totalReps",5))
   .put(JSONObject().put("id","high").put("wodTemplateId","cindy").put("totalReps",10))))
  val rows=WodLibraryHistory.read(JSONObject().put("workouts",workouts))["cindy"]!!
  assertEquals("high",rows.first().id)
  assertEquals(1,WodLibraryHistory.visible(rows.take(1),false).size)
 }
}
