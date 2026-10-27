package dev.repera.mobile
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
class MovementDetailsTextTest {
 @Test fun invalidWeightPreservesPriorTargetAndBlocksSaveAfterRestoration() {
  val b=BlockDraftUi(RoutineBlockInfo("WOD","forTime"));val e=EntryUi("e","Nombre",8,1,null,sourceJson="{\"id\":\"m\",\"weightMaleKg\":20,\"future\":true}");b.entries.add(e)
  e.setMovementText("weightMaleKg","-",true);e.detailsOpen=true
  assertEquals(20.0,JSONObject(e.sourceJson!!).getDouble("weightMaleKg"),0.0)
  assertNull(b.toDraft())
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single();val restored=r.entries.single()
  assertEquals("-",restored.movementText("weightMaleKg"));assertTrue(restored.detailsOpen);assertNull(r.toDraft())
  restored.setMovementText("weightMaleKg","22,5",true)
  assertNotNull(r.toDraft());assertEquals(22.5,JSONObject(restored.sourceJson!!).getDouble("weightMaleKg"),0.0)
  assertTrue(JSONObject(restored.sourceJson!!).getBoolean("future"))
 }
 @Test fun blankWeightClearsButMalformedAndNonfiniteNeverClear() {
  val e=EntryUi("e","Nombre",8,1,null)
  e.setMovementText("weightFemaleKg","12",true)
  listOf("-1","NaN","Infinity","x").forEach {e.setMovementText("weightFemaleKg",it,true);assertEquals(12.0,JSONObject(e.sourceJson!!).getDouble("weightFemaleKg"),0.0)}
  e.setMovementText("weightFemaleKg","",true)
  assertFalse(JSONObject(e.sourceJson!!).has("weightFemaleKg"));assertFalse(e.invalidMovementInputs["weightFemaleKg"]!!)
 }
 @Test fun textAndGeneratedIdentitySurviveMultipleEditsAndRestoration() {
  val b=BlockDraftUi();val e=EntryUi("e","Nombre",8,1,null);b.entries.add(e)
  e.setMovementText("notes","Nota literal",false);val id=JSONObject(e.sourceJson!!).getString("id")
  e.setMovementText("scaleAlternative","Escala",false)
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single().entries.single()
  assertEquals(id,JSONObject(r.sourceJson!!).getString("id"));assertEquals("Nota literal",r.movementText("notes"));assertEquals("Escala",r.movementText("scaleAlternative"))
 }
 @Test fun invalidRestTextDoesNotRewriteDurationOrSilentlyDefaultAfterRestoration() {
  val b=BlockDraftUi(RoutineBlockInfo("WOD","forTime"));val source=EditorBlockOps.restMovement()
  val e=EntryUi("","REST",1,1,null,itemId=source.getString("id"),sourceJson=source.toString());b.entries.add(e)
  listOf("","0","14","301","-","x").forEach {e.setRestText(it);assertEquals(60,JSONObject(e.sourceJson!!).getInt("restSeconds"));assertNull(b.toDraft())}
  val r=restoreRoutineEditorBlocks(saveRoutineEditorBlocks(listOf(b))).single();val entry=r.entries.single()
  assertEquals("x",entry.restText());assertNull(r.toDraft())
  entry.setRestText("90");assertNotNull(r.toDraft());assertEquals(90,JSONObject(entry.sourceJson!!).getInt("restSeconds"))
 }
}
