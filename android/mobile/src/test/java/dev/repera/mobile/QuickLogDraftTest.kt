package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test

class QuickLogDraftTest {
 private val draft=QuickLogDraft("meters",
  listOf(QuickLogRow(500,null,300,null,"meters"),QuickLogRow(-1,Double.NaN,null,12,"meters"),QuickLogRow(8,22.5,null,null,"meters")),
  listOf("a","b","c"),"nota, con coma; y \"comillas\"\nlinea",true,"req-1","a|press")
 @Test fun roundTripKeepsEverythingIncludingInvalidTypedRows() {
  val back=QuickLogDraft.decode(draft.encode(),"a|press")!!;assertEquals(listOf("a","b","c"),back.rowKeys)
  assertEquals(draft.requestId,back.requestId);assertEquals(draft.notes,back.notes);assertTrue(back.includeNotes)
  assertEquals(500,back.rows[0].quantity);assertEquals(300,back.rows[0].durationSeconds)
  assertEquals(-1,back.rows[1].quantity);assertTrue(back.rows[1].weightKg!!.isNaN());assertEquals(12,back.rows[1].deficitCm)
  assertEquals(22.5,back.rows[2].weightKg!!,0.0)
 }
 @Test fun requestIdSurvivesSoRetryAfterRotationIsIdempotent() {assertEquals("req-1",QuickLogDraft.decode(draft.encode(),"a|press")!!.requestId)}
 @Test fun emptyRowListRoundTrips() {
  val e=QuickLogDraft("reps",emptyList(),emptyList(),"",false,"r","a|press")
  assertEquals(e,QuickLogDraft.decode(e.encode(),"a|press"))
 }
 @Test fun malformedDataIsRejectedNotGuessed() {
  assertNull(QuickLogDraft.decode(null,"a|press"));assertNull(QuickLogDraft.decode(emptyList(),"a|press"))
  assertNull(QuickLogDraft.decode(draft.encode().dropLast(1),"a|press"))
  assertNull(QuickLogDraft.decode(draft.encode().toMutableList().also {it[0]="3"},"a|press"))
  assertNull(QuickLogDraft.decode(draft.encode().toMutableList().also {it[4]="maybe"},"a|press"))
  assertNull(QuickLogDraft.decode(draft.encode().toMutableList().also {it[7]="x"},"a|press"))
  assertNull(QuickLogDraft.decode(draft.encode().toMutableList().also {it[6]="101"},"a|press"))
 }
 @Test fun draftFromAnotherAccountOrExerciseIsDroppedNotAdopted() {
  assertNull(QuickLogDraft.decode(draft.encode(),"b|press"));assertNull(QuickLogDraft.decode(draft.encode(),"a|squat"))
 }
}
