package dev.repera.mobile
import dev.repera.domain.ExerciseInputMode.*
import org.junit.Assert.*
import org.junit.Test
class QuickLogInputTest {
 @Test fun intClampsToZeroAndCapLikeAppleParseInt() {
  assertEquals(0,QuickLogInput.int("",99));assertEquals(0,QuickLogInput.int("abc",99));assertEquals(0,QuickLogInput.int("-5",99))
  assertEquals(99,QuickLogInput.int("150",99));assertEquals(60,QuickLogInput.int("61",QuickLogInput.MAX_DEFICIT_CM))
  assertEquals(86_400,QuickLogInput.int("90000",QuickLogInput.MAX_DURATION_SECONDS));assertEquals(12,QuickLogInput.int(" 12 ",99))
  assertEquals(100_000,QuickLogInput.int("99999999999999",100_000))
 }
 @Test fun quantityCapsMatchAppleLoggingStyle() {
  assertEquals(100_000,QuickLogInput.quantityCap(MACHINE_WORK));assertEquals(999,QuickLogInput.quantityCap(REPS_AND_TIME))
  assertEquals(99,QuickLogInput.quantityCap(REPS_ONLY));assertEquals(50,QuickLogInput.quantityCap(LOAD_REPS))
 }
 @Test fun weightRoundsTwoDecimalsClampsAndEmptyMeansNoWeight() {
  assertEquals(42.5,QuickLogInput.weight("42,5")!!,0.0);assertEquals(42.57,QuickLogInput.weight("42.567")!!,1e-9)
  assertEquals(1500.0,QuickLogInput.weight("2000")!!,0.0);assertEquals(1500.0,QuickLogInput.weight("Infinity")!!,0.0)
  assertNull(QuickLogInput.weight(""));assertNull(QuickLogInput.weight("x"));assertNull(QuickLogInput.weight("-3"));assertNull(QuickLogInput.weight("0"));assertNull(QuickLogInput.weight("0.001"))
  assertNull(QuickLogInput.weight("NaN"))
 }
 @Test fun typedValuesThatUsedToBeRejectedAreNowCappedAndStillValidate() {
  val row=QuickLogRow(QuickLogInput.int("500",QuickLogInput.quantityCap(LOAD_REPS)),QuickLogInput.weight("9999"))
  assertEquals(QuickLogRow(50,1500.0),row);assertEquals(listOf(row),QuickLogRows.validate(listOf(row),LOAD_REPS,"reps",false))
 }
}
