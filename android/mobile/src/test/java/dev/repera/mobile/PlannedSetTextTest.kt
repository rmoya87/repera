package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class PlannedSetTextTest {
 @Test fun validCommaAndBlankOptionalTargetsPreserveIdentity() {
  assertEquals(PlannedSetDraft(8,12.5,1.5,"id"),parsePlannedSetText("8","12,5","1,5","id"))
  assertEquals(PlannedSetDraft(8,null,null,"id"),parsePlannedSetText("8","","","id"))
 }
 @Test fun malformedOptionalTargetIsNotInterpretedAsClear() {
  listOf("-","abc","NaN","Infinity","-1").forEach {assertNull(parsePlannedSetText("8",it,"2","id"))}
  listOf("-","abc","NaN","Infinity","-1").forEach {assertNull(parsePlannedSetText("8","20",it,"id"))}
 }
 @Test fun invalidRepsCannotReplaceExistingPlannedSet() {
  listOf("","-","0","-1","10001","8.5").forEach {assertNull(parsePlannedSetText(it,"20","2","id"))}
 }
}
