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
  // Apple 79b34354: delta de tiempo en minutos con unidad ′.
  assertEquals("+89′",ProgressTilesModel.deltaLabel(89,"′")); assertEquals("-2′",ProgressTilesModel.deltaLabel(-2,"′"))
  assertNull(ProgressTilesModel.deltaLabel(0,"′"))
 }
 @Test fun mobilityDurationUsesSecondsBelowAMinute() {
  assertEquals("45 s",ProgressTilesModel.mobilityDuration(45))
  assertEquals("1 min 0 s",ProgressTilesModel.mobilityDuration(60))
  assertEquals("12 min 5 s",ProgressTilesModel.mobilityDuration(725))
 }

    @Test fun tilesShowRealTotalMinutesWithDeltaInBothTiers() {
        // 602e9c39: Tiempo total real (nunca media × sesiones), delta en ambos niveles.
        val pro = ProgressTilesModel.tiles(5, 202.5, 3, 114.0, 4, 6, true)
        assertEquals(listOf("Entrenos", "Tiempo", "Racha"), pro.map { it.label })
        assertEquals(listOf("5", "203′", "4"), pro.map { it.value })
        assertEquals(listOf<Int?>(2, 89, -2), pro.map { it.delta })
        val free = ProgressTilesModel.tiles(5, 202.5, 3, 114.0, 4, 6, false)
        assertEquals(listOf("5", "203′", "4"), free.map { it.value })
        assertEquals("Tiempo", free[1].label)
        assertEquals(listOf<Int?>(2, 89, -2), free.map { it.delta })
        assertEquals("0′", ProgressTilesModel.tiles(0, 0.0, null, null, 0, 0, false)[1].value)
        assertEquals(null, ProgressTilesModel.tiles(1, 45.0, null, null, 0, 0, true)[1].delta)
        // Agrupación española desde 1.000 (ReperaNumberFormat.integer).
        assertEquals("1.234′", ProgressTilesModel.tiles(9, 1234.4, null, null, 0, 0, true)[1].value)
        // Apple 79b34354: solo la tile de tiempo lleva unidad de delta.
        assertEquals(listOf("", "′", ""), pro.map { it.deltaUnit })
    }
}
