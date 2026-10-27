package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class ProgressTilesModelTest {
 @Test fun roundsHalfAwayFromZeroLikeSwift() {
  assertEquals(3,ProgressTilesModel.roundHalfAway(2.5)); assertEquals(-3,ProgressTilesModel.roundHalfAway(-2.5))
  assertEquals(45,ProgressTilesModel.roundHalfAway(45.4)); assertEquals(46,ProgressTilesModel.roundHalfAway(45.5))
  assertEquals("46′",ProgressTilesModel.minutesLabel(45.9)); assertEquals("—",ProgressTilesModel.minutesLabel(null))
 }
 @Test fun deltasMatchAppleRules() {
  assertNull(ProgressTilesModel.minutesDelta(40.0,null)); assertNull(ProgressTilesModel.minutesDelta(null,40.0))
  assertEquals(-3,ProgressTilesModel.minutesDelta(40.0,43.4))
  assertNull(ProgressTilesModel.deltaLabel(0)); assertNull(ProgressTilesModel.deltaLabel(null))
  assertEquals("+2",ProgressTilesModel.deltaLabel(2)); assertEquals("-1",ProgressTilesModel.deltaLabel(-1))
 }
 @Test fun mobilityDurationUsesSecondsBelowAMinute() {
  assertEquals("45 s",ProgressTilesModel.mobilityDuration(45))
  assertEquals("1 min 0 s",ProgressTilesModel.mobilityDuration(60))
  assertEquals("12 min 5 s",ProgressTilesModel.mobilityDuration(725))
 }

    @Test fun tilesProAndFree() {
        val pro = ProgressTilesModel.tiles(5, 40.5, 3, 38.0, 4, 6, true)
        assertEquals(listOf("Entrenos", "Tiempo medio", "Racha"), pro.map { it.label })
        assertEquals(listOf("5", "41′", "4"), pro.map { it.value })
        assertEquals(listOf<Int?>(2, 3, -2), pro.map { it.delta })
        val free = ProgressTilesModel.tiles(5, 40.5, 3, 38.0, 4, 6, false)
        assertEquals(listOf("5", "203′", "4"), free.map { it.value })
        assertEquals("Tiempo", free[1].label)
        assertEquals(listOf<Int?>(null, null, -2), free.map { it.delta })
        assertEquals("—", ProgressTilesModel.tiles(0, null, null, null, 0, 0, false)[1].value)
        assertEquals(null, ProgressTilesModel.tiles(1, null, null, null, 0, 0, true)[1].delta)
    }
}
