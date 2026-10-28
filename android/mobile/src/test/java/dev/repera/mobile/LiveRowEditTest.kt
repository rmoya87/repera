package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class LiveRowEditTest {
 private val base=LiveRowSummary("r",8,40.0,null,null,2.0,false)
 @Test fun typedValuesAreClampedLikeQuickLog() {
  assertEquals(50,LiveRowEdit.reps(base,"500",50).reps);assertEquals(0,LiveRowEdit.reps(base,"",50).reps)
  assertNull(LiveRowEdit.weight(base,"").weightKg);assertEquals(1500.0,LiveRowEdit.weight(base,"9999").weightKg!!,0.0)
  assertEquals(60,LiveRowEdit.deficit(base,"99").deficitCm);assertNull(LiveRowEdit.deficit(base,"0").deficitCm)
  assertEquals(86_400,LiveRowEdit.duration(base,"99999").durationSeconds);assertNull(LiveRowEdit.duration(base,"").durationSeconds)
 }
 @Test fun effortBlankClearsAndInvalidIsIgnoredAsNone() {
  assertNull(LiveRowEdit.effort(base,"","rir").rir);assertEquals(3.0,LiveRowEdit.effort(base,"3","rir").rir!!,0.0)
  assertNull(LiveRowEdit.effort(base,"11","rpe").rir);assertNull(LiveRowEdit.effort(base,"-1","rir").rir)
 }
 @Test fun draftRowsKeepIdsAndCompletedFlag() {
  val r=LiveRowEdit.toDraftRows(listOf(base,base.copy(id="c",completed=true)))
  assertEquals(listOf("r","c"),r.map {it.id});assertEquals(listOf(false,true),r.map {it.completed});assertEquals(8,r[0].reps);assertEquals(40.0,r[0].weightKg!!,0.0)
 }
}
