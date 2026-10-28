package dev.repera.mobile
import org.json.*
import org.junit.Test
import org.junit.Assert.*
import dev.repera.mobile.ActiveSessionDraft.Row
class ActiveSessionDraftRecordedTest {
 private fun logged(id:String,reps:Int,phase:String="work",kind:String="straight",kg:Double?=null)=JSONObject().put("id",id).put("reps",reps)
  .put("phase",phase).put("kind",kind).put("completedAt","T0").apply {kg?.let {put("weightKg",it)}}
 private fun arr(vararg o:JSONObject)=JSONArray().apply {o.forEach {put(it)}}
 private fun rec(existing:JSONArray,rows:List<Row>,field:String="weightKg",dur:Boolean=false,rir:Boolean=true)=
  ActiveSessionDraft.recorded(existing,rows,field,dur,rir,"reps","NOW")
 private fun ids(a:JSONArray)=(0 until a.length()).map {a.getJSONObject(it).getString("id")}
 @Test fun editedRowUpdatesExistingSetAndKeepsIdAndCompletedAt() {
  val out=rec(arr(logged("a",5,kg=40.0)),listOf(Row("a",8,weightKg=45.0,rir=2.0)))
  val s=out.getJSONObject(0);assertEquals(8,s.getInt("reps"));assertEquals(45.0,s.getDouble("weightKg"),0.0);assertEquals("T0",s.getString("completedAt"));assertEquals(2.0,s.getDouble("rir"),0.0)
 }
 @Test fun newRowWithRepsBecomesResultAndZeroRepsRowIsNotRecorded() {
  val out=rec(JSONArray(),listOf(Row("p1",6,weightKg=30.0),Row("p2",0)))
  assertEquals(listOf("p1"),ids(out));val s=out.getJSONObject(0)
  assertEquals("work",s.getString("phase"));assertEquals("straight",s.getString("kind"));assertEquals("NOW",s.getString("completedAt"));assertEquals("reps",s.getString("quantityUnit"))
 }
 @Test fun rowRemovedByUserDropsItsResultButWarmupAndDropsetAreKept() {
  val ex=arr(logged("w",10,phase="warmup"),logged("a",5),logged("d",8,kind="dropset"),logged("b",5))
  val out=rec(ex,listOf(Row("b",5)))
  assertEquals(listOf("w","d","b"),ids(out))
 }
 @Test fun rowsThatDropToZeroRepsRemoveTheExistingResult() {
  assertEquals(emptyList<String>(),ids(rec(arr(logged("a",5)),listOf(Row("a",0)))))
 }
 @Test fun loadFieldDurationAndRirRulesFollowTheExercise() {
  val deficit=rec(JSONArray(),listOf(Row("x",5,weightKg=20.0,deficitCm=15)),field="deficitCm").getJSONObject(0)
  assertFalse(deficit.has("weightKg"));assertEquals(15,deficit.getInt("deficitCm"))
  val none=rec(JSONArray(),listOf(Row("x",5,weightKg=20.0,durationSeconds=40,rir=1.0)),field="none",dur=true,rir=false).getJSONObject(0)
  assertFalse(none.has("weightKg"));assertFalse(none.has("rir"));assertEquals(40,none.getInt("durationSeconds"));assertFalse(none.getBoolean("toFailure"))
  val fail=rec(JSONArray(),listOf(Row("x",5,rir=0.0))).getJSONObject(0);assertTrue(fail.getBoolean("toFailure"))
  val noWeight=rec(arr(logged("a",5,kg=40.0)),listOf(Row("a",5,weightKg=0.0))).getJSONObject(0);assertFalse(noWeight.has("weightKg"))
 }
 @Test fun doesNotMutateTheExistingArrayAndFeedsReplaceRecordedSets() {
  val ex=arr(logged("a",5));val before=ex.toString()
  val out=rec(ex,listOf(Row("a",9),Row("n",3)));assertEquals(before,ex.toString())
  val item=JSONObject().put("id","i").put("loggedSets",ex);val session=JSONObject().put("exercises",JSONArray().put(item))
  assertTrue(ActiveSessionDraft.replaceRecordedSets(session,"i",out));assertEquals(12,item.getInt("completedReps"))
 }
}
