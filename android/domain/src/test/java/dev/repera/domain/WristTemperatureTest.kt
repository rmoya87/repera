package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class WristTemperatureTest {
 private val sleep=listOf(SleepStageSample(100,200,"DEEP","watch"))
 @Test fun requiresKnownBaselineWristLocationAndObservedSleep() {
  assertEquals(34.5,WristTemperature.observedCelsius(34.0,0.5,true,150,sleep)!!,0.001)
  assertNull(WristTemperature.observedCelsius(null,0.5,true,150,sleep))
  assertNull(WristTemperature.observedCelsius(34.0,0.5,false,150,sleep))
  assertNull(WristTemperature.observedCelsius(34.0,0.5,true,200,sleep))
  assertNull(WristTemperature.observedCelsius(34.0,Double.NaN,true,150,sleep))
  assertNull(WristTemperature.observedCelsius(90.0,0.5,true,150,sleep))
  assertNull(WristTemperature.observedCelsius(34.0,0.5,true,150,emptyList()))
 }
}
