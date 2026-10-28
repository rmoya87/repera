package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class BoardClassicReviewTest {
 private val squat=CatalogExercise("squat","Sentadilla trasera",listOf("BSQ","Back squat"))
 @Test fun classicalDefaultIsAnEditableProposalNotLiteRewrite() {
  val draft=BoardClassicReview.drafts("Back squat",listOf(squat)).single()
  assertEquals("3",draft.sets);assertEquals("8",draft.reps)
  assertEquals(RoutineBlockKind.WOD,BoardScanLiteParser.parse("Back squat",listOf(squat)).blocks.single().kind)
  val block=BoardClassicReview.blocks(listOf(draft.copy(sets="4",reps="6",load="60,5")),listOf(squat))!!.single()
  assertEquals(4,block.exercises.single().plannedSets.size)
  assertEquals(6,block.exercises.single().plannedSets.first().targetReps)
  assertEquals(60.5,block.exercises.single().plannedSets.first().targetWeightKg!!,0.001)
 }
 @Test fun explicitSchemeLoadAndNumberedNamesMatchSource() {
  val drafts=BoardClassicReview.drafts("1. BSQ 5x5 @60kg\nBack squat @40,5 lb",listOf(squat))
  assertEquals("5",drafts[0].sets);assertEquals("5",drafts[0].reps);assertEquals("60",drafts[0].load)
  assertEquals("40,5",drafts[1].load) // Source retains numeric lb, does not convert here.
  assertTrue(drafts.all {it.resolved(listOf(squat))?.matchedExerciseId=="squat"})
 }
 @Test fun excludesNoiseQualityAndHeadersWithoutLosingRaw() {
  val drafts=BoardClassicReview.drafts("WARMUP\nSETS\n22:02\n123\nAMRAP 10'\nFOR QUALITY\nSTRENGTH\nBack squat",listOf(squat))
  assertEquals(listOf("Back squat"),drafts.map {it.line.raw})
 }
 @Test fun fullSourceHeaderExclusionsAreSeparateFromLitePrecedence() {
  val headers=listOf("Session AMRAP 12", "Work EVERY 90S FOR 12MIN", "Today E2MOM 10'", "Mixed LADDER 5", "BUY IN 400m", "Team PARTNER workout", "6 STATIONS rotation", "MAX CAL ROW", "Today's FOR COMPLETION", "3 ROUNDS OF", "FOR QUALITY 10", "TECHNIQUE: squat", "21-15-9", "21 15 9", "OTM 10", "SKILL test")
  for(header in headers) assertTrue(header,BoardClassicReview.drafts(header,listOf(squat)).isEmpty())
  assertEquals("Back squat",BoardClassicReview.drafts("Back squat",listOf(squat)).single().line.raw)
 }
 @Test fun catalogPriorityAndEditsNeverReuseOldIdentity() {
  val old=CatalogExercise("old","BSQ",emptyList(),isCustom=true)
  val draft=BoardClassicReview.drafts("BSQ",listOf(old,squat)).single()
  assertEquals("squat",draft.resolved(listOf(old,squat))?.matchedExerciseId)
  assertNull(draft.copy(name="Unknown").resolved(listOf(squat)))
  assertEquals(draft.line.id,draft.copy(name="Unknown").line.id)
 }
 @Test fun boundsAndMalformedPrescriptionsCannotConfirm() {
  for(raw in listOf("Back squat @-60","Back squat @60..5","Back squat 3x-8","- 3x8 Back squat","Back squat 3.5x8","Back squat 3x8 + 2x4","Back squat @70%","Back squat 999999999999x8")) {
   assertNull(raw,BoardClassicReview.blocks(BoardClassicReview.drafts(raw,listOf(squat)),listOf(squat)))
  }
  val draft=BoardClassicReview.drafts("BSQ",listOf(squat)).single()
  for(value in listOf("0","201","999999999999")) assertNull(draft.copy(sets=value).resolved(listOf(squat)))
  assertNull(draft.copy(reps="100001").resolved(listOf(squat)))
  for(value in listOf("NaN","Infinity","-1","1e999")) assertNull(draft.copy(load=value).resolved(listOf(squat)))
 }
 @Test fun exclusionsAndUnresolvedNeedReviewNotCustomCreation() {
  val drafts=BoardClassicReview.drafts("BSQ\nUnknown",listOf(squat))
  assertNull(BoardClassicReview.blocks(drafts,listOf(squat)))
  assertEquals(1,BoardClassicReview.blocks(drafts.map {if(it.name=="Unknown") it.copy(included=false) else it},listOf(squat))!!.single().exercises.size)
  assertNull(BoardClassicReview.blocks(drafts.map {it.copy(included=false)},listOf(squat)))
 }
 @Test fun editedAndExcludedDraftsPreserveSourceIdentityAndNoCatalogMutation() {
  val catalog=listOf(squat)
  val drafts=BoardClassicReview.drafts("BSQ\nUnknown",catalog)
  val block=BoardClassicReview.blocks(drafts.mapIndexed {i,d ->if(i==1) d.copy(included=false) else d.copy(load="0")},catalog)!!.single()
  assertEquals("BSQ",block.wodNotes)
  assertEquals(0.0,block.exercises.single().plannedSets.first().targetWeightKg!!,0.001)
  assertEquals(1,catalog.size)
  assertEquals(drafts[0].line.id,drafts[0].copy(sets="4").resolved(catalog)?.id)
 }
}
