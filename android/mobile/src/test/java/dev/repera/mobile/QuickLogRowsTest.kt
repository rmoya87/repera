package dev.repera.mobile
import dev.repera.domain.ExerciseInputMode
import org.junit.Assert.*
import org.junit.Test
class QuickLogRowsTest {
 @Test fun preservesPerRowLoadsAndRejectsWrongMetrics() {
  val rows=listOf(QuickLogRow(8,40.0),QuickLogRow(6,45.0))
  assertEquals(rows,QuickLogRows.validate(rows,ExerciseInputMode.LOAD_REPS,"reps",false))
  assertTrue(runCatching {QuickLogRows.validate(rows,ExerciseInputMode.REPS_ONLY,"reps",false)}.isFailure)
  assertTrue(runCatching {QuickLogRows.validate(listOf(QuickLogRow(500,durationSeconds=60,unit="calories")),ExerciseInputMode.MACHINE_WORK,"meters",false)}.isFailure)
 }
 @Test fun machineAndHoldUseObservedDurationWithoutKgOrRir() {
  assertEquals(60,QuickLogRows.validate(listOf(QuickLogRow(500,durationSeconds=60,unit="meters")),ExerciseInputMode.MACHINE_WORK,"meters",false).single().durationSeconds)
  assertTrue(runCatching {QuickLogRows.validate(listOf(QuickLogRow(1)),ExerciseInputMode.REPS_AND_TIME,"reps",false)}.isFailure)
 }
 @Test fun currentAppleCapsAndHoldZeroDurationAreNotSaved() {
  assertEquals(1,QuickLogRows.validate(listOf(QuickLogRow(0),QuickLogRow(8,40.0)),ExerciseInputMode.LOAD_REPS,"reps",false).size)
  assertTrue(runCatching {QuickLogRows.validate(listOf(QuickLogRow(51)),ExerciseInputMode.LOAD_REPS,"reps",false)}.isFailure)
  assertTrue(runCatching {QuickLogRows.validate(listOf(QuickLogRow(1,durationSeconds=0)),ExerciseInputMode.REPS_AND_TIME,"reps",false,true)}.isFailure)
 }
 @Test fun unfinishedTypedQuantityCannotSilentlyDropWhileOtherRowsSave() {
  assertThrows(IllegalArgumentException::class.java) {QuickLogRows.validate(listOf(QuickLogRow(8),QuickLogRow(-1)),ExerciseInputMode.REPS_ONLY,"reps",false)}
  assertThrows(IllegalArgumentException::class.java) {QuickLogRows.validate(listOf(QuickLogRow(1,durationSeconds=30),QuickLogRow(1,durationSeconds=-1)),ExerciseInputMode.REPS_AND_TIME,"reps",false,mobilityHold=true)}
 }
}
