package dev.repera.mobile
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class PlannedSetFidelityTest {
 @Test fun durationAndUnknownFieldsSurviveDecodeEditEncode() {
  val raw=JSONArray("[{\"id\":\"set\",\"targetReps\":1,\"targetDurationSeconds\":75,\"targetRir\":2,\"future\":{\"flag\":true}}]")
  val decoded=EditorBlockOps.jsonToDraftSets(raw).single()
  assertEquals(75,decoded.targetDurationSeconds)
  val out=EditorBlockOps.draftSetsToJson(listOf(decoded.copy(targetReps=2,targetRir=null))).getJSONObject(0)
  assertEquals(75,out.getInt("targetDurationSeconds"));assertEquals("set",out.getString("id"))
  assertTrue(out.getJSONObject("future").getBoolean("flag"));assertFalse(out.has("targetRir"))
 }
 @Test fun savedInstanceKeepsDurationSourceAndNullIdentity() {
  val b=BlockDraftUi();val planned=PlannedSetDraft(1,null,null,null,75,"{\"future\":9}")
  b.entries.add(EntryUi("e","Nombre",1,1,null,listOf(planned)))
  val restored=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertEquals(planned,restored.entries.single().plannedSets.single())
 }
 @Test fun loadGuideCopyAndScaleRetainObservedDuration() {
  val set=LoadGuideSet(20.0,8,2.0,75,"reps")
  assertEquals(75,ExerciseLoadGuide.copyLastSession(listOf(set)).single().targetDurationSeconds)
  assertEquals(75,ExerciseLoadGuide.scaledPlannedSets(30.0,listOf(set),2.5,2.0)!!.single().targetDurationSeconds)
 }
 @Test fun durationTextEditsAreExplicitValidatedAndRestoredWithoutChangingOtherTargets() {
  val b=BlockDraftUi();val original=PlannedSetDraft(1,null,2.0,"s",75,"{\"future\":true}")
  val e=EntryUi("e","Hold",1,1,null,listOf(original));b.entries.add(e)
  assertEquals("75",e.durationText(0,true))
  e.rawSetInputs[0]=original to Triple("1","-","2")
  e.setDurationText(0,"-");assertEquals(original,e.plannedSets[0]);assertNull(b.toDraft())
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single();assertEquals("-",r.entries.single().durationText(0,true));assertNull(r.toDraft())
  r.entries.single().setDurationText(0,"90");assertEquals(original.copy(targetDurationSeconds=90),r.entries.single().plannedSets[0]);assertNotNull(r.toDraft())
  assertEquals(Triple("1","-","2"),r.entries.single().rawSetInputs[0]?.second)
  assertEquals(90,r.entries.single().rawSetInputs[0]?.first?.targetDurationSeconds)
 }
}
