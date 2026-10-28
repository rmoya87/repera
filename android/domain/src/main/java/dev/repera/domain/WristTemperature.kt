package dev.repera.domain

/** Only wrist, known absolute baseline and an observed asleep interval qualify.
 * A relative delta without baseline must never be shown as an absolute °C value. */
object WristTemperature {
 fun observedCelsius(baseline:Double?,delta:Double,isWrist:Boolean,epochMillis:Long,
                     sleep:List<SleepStageSample>):Double? {
  if(!isWrist || baseline==null || !baseline.isFinite() || !delta.isFinite()) return null
  if(sleep.none {it.stage in setOf("LIGHT","DEEP","REM","OTRO") && epochMillis>=it.startMillis && epochMillis<it.endMillis}) return null
  return (baseline+delta).takeIf {it.isFinite() && it in 25.0..42.0}
 }
}
