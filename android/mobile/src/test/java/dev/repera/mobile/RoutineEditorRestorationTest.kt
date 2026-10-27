package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class RoutineEditorRestorationTest {
 @Test fun invalidRawFieldsUnknownJsonAndOrderedEntriesSurvive() {
  val b=BlockDraftUi(RoutineBlockInfo("Trabajo","ladder",id="block",sourceJson="{\"future\":true}"))
  b.timeCap="";b.rounds="-";b.interval="1x";b.work="02";b.rest="0";b.ladder="1-"
  val e=EntryUi("exercise","Nombre",8,2,12.5,null,"item","{\"futureItem\":9}")
  e.quantity="";e.sets="-";e.weight="12,";e.unit="meters";e.setsExpanded=true
  b.entries.add(e);b.entries.add(EntryUi("second","Segundo",1,1,null))
  val restored=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b)))
  assertEquals(saveRoutineEditorBlocks(listOf(b)),saveRoutineEditorBlocks(restored))
  assertNull(restored.single().toDraft())
  assertEquals(listOf("exercise","second"),restored.single().entries.map {it.exerciseId})
 }
 @Test fun plannedIdsRirAndUniformDirtyBaselineSurvive() {
  val sets=listOf(PlannedSetDraft(8,20.0,1.5,"s1"),PlannedSetDraft(6,22.0,2.0,"s2"))
  val b=BlockDraftUi();val e=EntryUi("exercise","Nombre",8,2,20.0,sets,"item")
  b.entries.add(e)
  assertTrue(e.untouchedUniform)
  e.quantity="9"
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertFalse(r.entries.single().untouchedUniform)
  assertEquals(sets,r.entries.single().plannedSets.toList())
  assertNull(r.toDraft()!!.entries.single().plannedSets)
  r.entries.single().quantity="8"
  assertTrue(r.entries.single().untouchedUniform)
  assertEquals(sets,r.toDraft()!!.entries.single().plannedSets)
 }
 @Test fun emptyNewEditorRetainsNoOriginalIdentityOrPlannedFlag() {
  val b=BlockDraftUi();b.entries.add(EntryUi("new","Nuevo",10,3,null))
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertNull(r.blockId);assertNull(r.entries.single().itemId)
  assertFalse(r.entries.single().hadPlanned);assertFalse(r.entries.single().untouchedUniform)
 }
 @Test fun emptyPlannedListIsNotSilentlyReplacedByDefaultSet() {
  val b=BlockDraftUi();b.entries.add(EntryUi("e","Nombre",8,1,null,emptyList()))
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertTrue(r.entries.single().plannedSets.isEmpty())
  assertTrue(r.entries.single().hadPlanned)
 }
 @Test fun restoredValuesRejectOtherAccountOrRoutineEvenIfUiSlotIsReused() {
  val raw=saveScopedEditorValue("accountA:routine1","unsaved")
  assertEquals("unsaved",restoreScopedEditorValue("accountA:routine1",raw))
  assertNull(restoreScopedEditorValue("accountB:routine1",raw))
  assertNull(restoreScopedEditorValue("accountA:routine2",raw))
  assertNull(restoreScopedEditorValue("accountA:routine1",saveScopedEditorValue("accountA:routine1",null)))
 }
 @Test fun invalidPerSetEditBlocksSaveEvenAfterSavedInstanceRestore() {
  val b=BlockDraftUi();b.entries.add(EntryUi("e","Nombre",8,1,20.0))
  b.entries.single().invalidSetInputs[0]=true
  b.entries.single().rawSetInputs[0]=b.entries.single().plannedSets[0] to Triple("8","-","2")
  assertNull(b.toDraft())
  val restored=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertNull(restored.toDraft())
  assertEquals(Triple("8","-","2"),restored.entries.single().rawSetInputs[0]?.second)
  restored.entries.single().invalidSetInputs[0]=false
  assertNotNull(restored.toDraft())
 }
 @Test fun replacedPlanDoesNotRestoreRawTextFromOldSet() {
  val b=BlockDraftUi();val e=EntryUi("e","Nombre",8,1,20.0);b.entries.add(e)
  e.rawSetInputs[0]=e.plannedSets[0] to Triple("8","20,","2")
  e.plannedSets[0]=PlannedSetDraft(10,30.0)
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single()
  assertTrue(r.entries.single().rawSetInputs.isEmpty())
  assertEquals(10,r.entries.single().plannedSets[0].targetReps)
 }
 @Test fun invalidStrengthTextCannotBeSilentlyConvertedToDefaultWodValues() {
  val a=BlockDraftUi();val e=EntryUi("e","Nombre",8,1,20.0);a.entries.add(e);e.quantity="-"
  val b=BlockDraftUi(RoutineBlockInfo("WOD","forTime"));val blocks=mutableListOf(a,b)
  val before=saveRoutineEditorBlocks(blocks)
  assertNotNull(PlanEntryMoves.move(blocks,0,0,1,mapOf("e" to "Nombre"),listOf(ExerciseEntry("e","Nombre",true,true))))
  assertEquals(before,saveRoutineEditorBlocks(blocks))
 }
 @Test fun invalidMovementDetailsCannotDisappearInCrossFormatConversionButSameFormatMovePreservesThem() {
  val a=BlockDraftUi(RoutineBlockInfo("WOD","forTime"));val e=EntryUi("e","Nombre",8,1,null);a.entries.add(e)
  e.setMovementText("weightMaleKg","-",true)
  val strength=BlockDraftUi();val other=BlockDraftUi(RoutineBlockInfo("Otro","forTime"));val blocks=mutableListOf(a,strength,other)
  val before=saveRoutineEditorBlocks(blocks)
  assertNotNull(PlanEntryMoves.move(blocks,0,0,1,mapOf("e" to "Nombre"),listOf(ExerciseEntry("e","Nombre",true,true))))
  assertEquals(before,saveRoutineEditorBlocks(blocks))
  assertNull(PlanEntryMoves.move(blocks,0,0,2,emptyMap(),emptyList()))
  assertTrue(a.entries.isEmpty());assertSame(e,other.entries.single());assertNull(other.toDraft())
 }
 @Test fun corruptOrForeignSavedDataFailsClosedWithoutThrowing() {
  assertNull(restoreScopedEditorValue("[\"a\",\"r\"]","not json"))
  assertNull(restoreScopedEditorValue("[\"a\",\"r\"]","{\"scope\":5,\"value\":\"x\"}"))
  assertNull(restoreScopedEditorValue("[\"a\",\"r\"]",saveScopedEditorValue("[\"b\",\"r\"]","x")))
  assertNull(restoreScopedEditorValue("[\"a\",\"r\"]","{\"scope\":\"[\\\"a\\\",\\\"r\\\"]\",\"value\":null}"))
  assertEquals("x",restoreScopedEditorValue("[\"a\",\"r\"]",saveScopedEditorValue("[\"a\",\"r\"]","x")))
  assertNull(restoreRoutineEditorBlocksOrNull("not json"));assertNull(restoreRoutineEditorBlocksOrNull("[{\"title\":1}]"))
  val b=BlockDraftUi(RoutineBlockInfo("T","strength",id="b"))
  assertEquals(1,restoreRoutineEditorBlocksOrNull(saveRoutineEditorBlocks(listOf(b)))!!.size)
 }
}
