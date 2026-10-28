package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class BoardStrengthLinesTest {
 private val squat=CatalogExercise("squat","Sentadilla trasera",listOf("Back squat"))
 private val bench=CatalogExercise("bench","Press banca",listOf("BXT-PRO","Bench press"))
 @Test fun orphanStrengthThenWodKeepsExplicitSetsAndLoad() {
  val result=BoardScanLiteParser.parse("5x5 BACK SQUAT @60\n3×8 BENCH PRESS\nAMRAP 10'\n10 THRUSTERS",listOf(squat,bench))
  assertEquals(2,result.blocks.size)
  val strength=result.blocks.first();assertEquals(RoutineBlockKind.STRENGTH,strength.kind)
  assertEquals(5,strength.exercises[0].plannedSets.size)
  assertEquals(5,strength.exercises[0].plannedSets[0].targetReps)
  assertEquals(60.0,strength.exercises[0].plannedSets[0].targetWeightKg!!,0.001)
  assertEquals(3,strength.exercises[1].plannedSets.size)
  assertEquals(8,strength.exercises[1].plannedSets[0].targetReps)
  assertEquals(WODFormat.AMRAP,result.blocks.last().wodFormat)
 }
 @Test fun editorialAliasBeatsOldCustomAndDoesNotChangeInput() {
  val old=CatalogExercise("old","BXT-PRO",emptyList(),isCustom=true)
  val result=BoardScanLiteParser.parse("3x8 BXT-PRO",listOf(old,bench))
  assertEquals("bench",result.blocks.single().exercises.single().exerciseId)
  assertEquals("BXT-PRO",old.name)
 }
 @Test fun unknownOrUnboundedBoardIsNotSilentlyRewritten() {
  assertNull(BoardStrengthLines.block(listOf("3x8 UNKNOWN XYZ"),listOf(squat)))
  assertNull(BoardStrengthLines.block(listOf("999999999x8 BACK SQUAT"),listOf(squat)))
  assertNull(BoardStrengthLines.block(listOf("5 BACK SQUAT"),listOf(squat)))
 }
 @Test fun officialExactPrecedesEditorialAliasAndCustom() {
  val canonical=CatalogExercise("official","BXT-PRO",emptyList())
  assertEquals("official",BoardStrengthLines.bestMatch("BXT-PRO",listOf(bench,canonical))?.id)
  val archived=bench.copy(isCatalogArchived=true)
  assertNull(BoardStrengthLines.bestMatch("BXT-PRO",listOf(archived)))
 }
 @Test fun everyTwoMinutesHeaderPreservesCadenceAndGlobalCap() {
  val result=BoardScanLiteParser.parse("E2MOM 10'\n5 POWER CLEAN")
  val block=result.blocks.single()
  assertEquals(WODFormat.EMOM,block.wodFormat)
  assertEquals(120,block.emomIntervalSeconds)
  assertEquals(10,block.timeCapMinutes)
  assertEquals(1,block.movements.size)
 }
 @Test fun everyMinutesDefaultAndOverflowRemainBounded() {
  val block=BoardScanLiteParser.parse("E3MOM\n5 POWER CLEAN").blocks.single()
  assertEquals(15,block.timeCapMinutes);assertEquals(180,block.emomIntervalSeconds)
  val extreme=BoardScanLiteParser.parse("E999999999999MOM 10'\n5 POWER CLEAN")
  assertTrue(extreme.blocks.isNotEmpty())
 }
 @Test fun extendedExplicitHeadersSplitWithoutFabricatingMovements() {
  val result=BoardScanLiteParser.parse("STRENGTH\n5x2 BACK SQUAT @7\n21-15-9\nTHRUSTER 40/30\nPULL-UP\nE2MOM 10'\n5 POWER CLEAN\nPARTNER WOD\n100 CAL ROW",listOf(squat))
  assertEquals(4,result.blocks.size)
  assertEquals(RoutineBlockKind.STRENGTH,result.blocks[0].kind)
  assertEquals("STRENGTH",result.blocks[0].title)
  assertEquals(5,result.blocks[0].exercises.single().plannedSets.size)
  assertEquals(WODFormat.LADDER,result.blocks[1].wodFormat)
  assertEquals(2,result.blocks[1].movements.size)
  assertEquals(WODFormat.EMOM,result.blocks[2].wodFormat)
  assertEquals(WODFormat.PARTNER,result.blocks[3].wodFormat)
  assertEquals(1,result.blocks[3].movements.size)
 }
 @Test fun movementWaveIsNotASeparateLadderHeader() {
  val result=BoardScanLiteParser.parse("EMOM 12'\n4-3-3-2 PUSH PRESS\n5 PULL UPS")
  assertEquals(1,result.blocks.size)
  assertEquals(WODFormat.EMOM,result.blocks.single().wodFormat)
  assertEquals(2,result.blocks.single().movements.size)
 }
 @Test fun roundMarkersAndFootnotesStayMetadataNotMovements() {
  val result=BoardScanLiteParser.parse("AMRAP 12'\nROUND 1:\n5 POWER CLEAN\nROUND 2\n10 PULL UPS\n* Solo técnica\n• No tocar el suelo")
  val block=result.blocks.single()
  assertEquals(2,block.movements.size)
  assertTrue(block.movements[0].notes.orEmpty().contains("Ronda 1"))
  assertTrue(block.movements[1].notes.orEmpty().contains("Ronda 2"))
  assertTrue(block.wodNotes.orEmpty().contains("Solo técnica"))
  assertTrue(block.wodNotes.orEmpty().contains("No tocar el suelo"))
 }
 @Test fun ordinaryRoundWordsInsideExerciseRemainMovementText() {
  val block=BoardScanLiteParser.parse("AMRAP 10'\n5 ROUND THE WORLD\n10 PUSH UPS").blocks.single()
  assertEquals(2,block.movements.size)
 }
 @Test fun roundMetadataDoesNotShiftBetweenRoundRestRemoval() {
  val block=BoardScanLiteParser.parse("4 RFT (TC 12')\nROUND 1\n300M RUN\n* Nota\n1' REST BTWN").blocks.single()
  assertEquals(1,block.movements.size)
  assertEquals(60,block.restBetweenRoundsSeconds)
  assertEquals(300,block.movements.single().distanceMeters)
 }
 @Test fun namedSectionWithoutTimedHeaderKeepsExplicitStrength() {
  val blocks=BoardScanLiteParser.parse("Weightlifting \"Squat Work\"\n5x5 BACK SQUAT @60\nMETCON\nAMRAP 10'\n10 PULL UPS",listOf(squat)).blocks
  assertEquals(2,blocks.size)
  assertEquals("Squat Work",blocks[0].title)
  assertEquals(RoutineBlockKind.STRENGTH,blocks[0].kind)
  assertEquals(5,blocks[0].exercises.single().plannedSets.size)
  assertEquals(WODFormat.AMRAP,blocks[1].wodFormat)
 }
 @Test fun cornerClockAndNumericNoiseDoNotCreateMovements() {
  val block=BoardScanLiteParser.parse("AMRAP 12'\n5 POWER CLEAN\n22:02\n123\n10 PULL UPS").blocks.single()
  assertEquals(2,block.movements.size)
 }
 @Test fun quotedMetconSectionRetainsFormatWithoutHeader() {
  val block=BoardScanLiteParser.parse("Metcon \"Fran\"\n21 THRUSTERS\n21 PULL UPS").blocks.single()
  assertEquals("Fran",block.title)
  assertEquals(WODFormat.FOR_TIME,block.wodFormat)
  assertEquals(2,block.movements.size)
 }
 @Test fun simpleExplicitComplexSplitsIntoTypedMovements() {
  val block=BoardScanLiteParser.parse("AMRAP 10'\n1 POWER CLEAN + 2 PUSH PRESS\n5 PULL UPS").blocks.single()
  assertEquals(3,block.movements.size)
  assertEquals(1,block.movements[0].reps)
  assertEquals(2,block.movements[1].reps)
  assertTrue(block.movements[0].notes.orEmpty().contains("Parte 1/2"))
  assertTrue(block.movements[1].notes.orEmpty().contains("Parte 2/2"))
 }
 @Test fun sharedMultiplierUnloadedComplexIsSplitWithParentNote() {
  val block=BoardScanLiteParser.parse("AMRAP 10'\n3X 1 PUSH PRESS + 1 OHSQ").blocks.single()
  assertEquals(2,block.movements.size)
  assertTrue(block.movements.all {it.reps==1 && it.notes.orEmpty().contains("Complejo ×3")})
  assertTrue(block.wodNotes.orEmpty().contains("3X 1 PUSH PRESS + 1 OHSQ"))
 }
 @Test fun parentLoadComplexStaysOnReviewPathWithoutReassigningWeight() {
  val block=BoardScanLiteParser.parse("AMRAP 10'\n1 POWER CLEAN + 2 PUSH PRESS 50/35").blocks.single()
  assertEquals(1,block.movements.size)
  assertTrue(block.wodNotes.orEmpty().contains("50/35"))
 }
 @Test fun percentAndRpeAreNotTurnedIntoKgByStrengthSubset() {
  assertNull(BoardStrengthLines.block(listOf("3x8 BACK SQUAT @70%"),listOf(squat)))
  assertNull(BoardStrengthLines.block(listOf("3x8 BACK SQUAT @6-8"),listOf(squat)))
 }
 @Test fun movementSetRangeAndPercentRemainNotesNotQuantityOrLoad() {
  val block=BoardScanLiteParser.parse("EMOM 12'\nSets 1-2: 3 Squat Clean #70%\nSets 3-4: 2 Squat Clean @>80%").blocks.single()
  assertEquals(2,block.movements.size)
  assertEquals(3,block.movements[0].reps)
  assertEquals(2,block.movements[1].reps)
  assertNull(block.movements[0].weightMaleKg)
  assertNull(block.movements[1].weightMaleKg)
  assertTrue(block.movements[0].notes.orEmpty().contains("Series 1-2"))
  assertTrue(block.movements[0].notes.orEmpty().contains("70%"))
  assertTrue(block.movements[1].notes.orEmpty().contains(">80%"))
 }
 @Test fun explicitStrengthIgnoresExactNoiseLabelsButKeepsReviewNotes() {
  val block=BoardScanLiteParser.parse("SETS\nREPS\n3x8 BACK SQUAT @60\nCIRCUITO",listOf(squat)).blocks.single()
  assertEquals(RoutineBlockKind.STRENGTH,block.kind)
  assertEquals(1,block.exercises.size)
  assertEquals(3,block.exercises.single().plannedSets.size)
  assertEquals(8,block.exercises.single().plannedSets.first().targetReps)
  assertTrue(block.wodNotes.orEmpty().contains("SETS"))
  assertTrue(block.wodNotes.orEmpty().contains("CIRCUITO"))
  assertNull(BoardStrengthLines.block(listOf("SETS","REPS","CIRCUITO"),listOf(squat)))
  assertNull(BoardStrengthLines.block(listOf("SETS","BACK SQUAT"),listOf(squat)))
 }
 @Test fun malformedStrengthLoadCannotBecomePartialOrMissingWeight() {
  for(load in listOf("@-60","@60..5","@1e3","@60 @70","@UNKNOWN","@"+"9".repeat(400))) {
   assertNull(load,BoardStrengthLines.block(listOf("3x8 BACK SQUAT "+load),listOf(squat)))
  }
  val valid=BoardStrengthLines.block(listOf("3x8 BACK SQUAT @60,5kg"),listOf(squat))!!
  assertEquals(60.5,valid.exercises.single().plannedSets.first().targetWeightKg!!,0.001)
 }
 @Test fun malformedStrengthSchemeCannotBecomePartialPrescription() {
  for(scheme in listOf("-3x8","- 3x8","3x-8","3.5x8","3x8.5","1e3x8","3x8x2")) {
   assertNull(scheme,BoardStrengthLines.block(listOf(scheme+" BACK SQUAT"),listOf(squat)))
  }
 }
}
