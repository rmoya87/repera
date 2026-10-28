package dev.repera.mobile
import dev.repera.domain.ExerciseInputMode.*
import org.junit.Assert.*
import org.junit.Test
class QuickLogDefaultsTest {
 private val last=LoadGuideSet(42.5,123,null,87,"meters")
 @Test fun machineUsesAppleFixedQuantityAndLastDurationNotLastQuantity() {
  assertEquals(QuickLogRow(500,durationSeconds=87,unit="meters"),QuickLogDefaults.row(MACHINE_WORK,"meters",false,false,last))
  assertEquals(QuickLogRow(15,durationSeconds=87,unit="calories"),QuickLogDefaults.row(MACHINE_WORK,"calories",false,false,last))
 }
 @Test fun holdAndMobilityDefaultsStayDistinctFromJumpRope() {
  assertEquals(1,QuickLogDefaults.row(REPS_AND_TIME,"reps",true,true,last).quantity)
  assertEquals(30,QuickLogDefaults.row(REPS_AND_TIME,"reps",true,true,null).durationSeconds)
  assertEquals(8,QuickLogDefaults.row(REPS_AND_TIME,"reps",true,false,null).quantity)
  assertEquals(50,QuickLogDefaults.row(REPS_AND_TIME,"reps",false,false,null).quantity)
  assertEquals(123,QuickLogDefaults.row(REPS_AND_TIME,"reps",true,false,last).quantity)
 }
 @Test fun strengthKeepsLastWeightAndQuantityWithoutInventingDuration() {
  assertEquals(QuickLogRow(123,42.5),QuickLogDefaults.row(LOAD_REPS,"reps",false,false,last))
  assertEquals(QuickLogRow(8),QuickLogDefaults.row(HSPU_DEFICIT,"reps",false,false,null))
 }
}
