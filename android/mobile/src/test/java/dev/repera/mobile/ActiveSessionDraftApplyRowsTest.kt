package dev.repera.mobile
import dev.repera.domain.ExerciseInputMode
import dev.repera.mobile.ActiveSessionDraft.Row
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class ActiveSessionDraftApplyRowsTest {
 private fun ex(id:String,kind:String="strength",logged:JSONArray=JSONArray())=JSONObject().put("id",id).put("blockId","b").put("blockKind",kind)
  .put("exercise",JSONObject().put("id","e$id").put("name","N$id")).put("plannedSets",JSONArray().put(JSONObject().put("id","p1").put("targetReps",5)))
  .put("loggedSets",logged)
 private fun logged(id:String,reps:Int,phase:String="work")=JSONObject().put("id",id).put("reps",reps).put("phase",phase).put("kind","straight").put("completedAt","T0")
 private fun state(vararg e:JSONObject)=JSONObject().put("activeSession",JSONObject().put("id","S").put("currentIndex",0).put("exercises",JSONArray().apply {e.forEach {put(it)}}))
 private val mode={_:JSONObject->ExerciseInputMode.LOAD_REPS}
 private fun apply(st:JSONObject,sid:String,i:Int,rows:List<Row>)=ActiveSessionDraft.applyRows(st,sid,i,rows,null,"NOW",mode)
 private fun loggedIds(st:JSONObject,i:Int):List<String> {val a=st.getJSONObject("activeSession").getJSONArray("exercises").getJSONObject(i).getJSONArray("loggedSets");return (0 until a.length()).map {a.getJSONObject(it).getString("id")}}
 @Test fun rowsGoToTheExerciseTheyWereEditedOnEvenAfterNavigation() {
  val st=state(ex("a"),ex("b"));st.getJSONObject("activeSession").put("currentIndex",1)
  assertEquals(true,apply(st,"S",0,listOf(Row("p1",6,weightKg=50.0))))
  assertEquals(listOf("p1"),loggedIds(st,0));assertEquals(emptyList<String>(),loggedIds(st,1))
 }
 @Test fun finishedOrDifferentSessionIsIgnoredAndStateUntouched() {
  val st=state(ex("a"));val before=st.toString()
  assertNull(apply(st,"OTHER",0,listOf(Row("p1",6))));assertEquals(before,st.toString())
  st.remove("activeSession");assertNull(apply(st,"S",0,listOf(Row("p1",6))))
  val st2=state(ex("a"));assertNull(apply(st2,"S",5,listOf(Row("p1",6))))
 }
 @Test fun wodExerciseIsRejected() {
  val st=state(ex("a","wod"));assertTrue(runCatching {apply(st,"S",0,listOf(Row("p1",6)))}.isFailure)
 }
 @Test fun setLoggedElsewhereIsKeptWhenRowsReconciledAndDroppedWhenTheyAreNot() {
  // Wear logs "w1" after the rows were opened with only "p1".
  val stNaive=state(ex("a",logged=JSONArray().put(logged("w1",8))))
  apply(stNaive,"S",0,listOf(Row("p1",6)));assertEquals(listOf("p1"),loggedIds(stNaive,0)) // stale rows would drop w1
  val known=HashSet<String>().apply {add("p1")}
  val incoming=listOf(LiveRowSummary("w1",8,null,null,null,null,true),LiveRowSummary("p1",5,null,null,null,null,false))
  val rows=LiveRowEdit.reconcile(listOf(LiveRowSummary("p1",6,50.0,null,null,null,false)),known,incoming)
  assertEquals(listOf("w1","p1"),rows.map {it.id});assertEquals(6,rows[1].reps) // local edit not replaced
  val st=state(ex("a",logged=JSONArray().put(logged("w1",8))))
  apply(st,"S",0,LiveRowEdit.toDraftRows(rows));assertEquals(listOf("w1","p1"),loggedIds(st,0))
 }
 @Test fun reconcileDoesNotReAddRowsTheUserDeletedOrAlreadyKnown() {
  val known=HashSet<String>().apply {add("c1")}
  val rows=LiveRowEdit.reconcile(emptyList(),known,listOf(LiveRowSummary("c1",5,null,null,null,null,true)))
  assertTrue(rows.isEmpty())
 }
}
