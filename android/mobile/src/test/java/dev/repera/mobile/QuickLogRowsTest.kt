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

 @Test fun weightedRepsOrMetersToggle() {
  // Apple 1d1edc8b/3432a1a9: transportes con carga alternan reps/metros con kg.
  // LOAD_DISTANCE (Hyrox) ahora acepta reps con el flag de paridad.
  val sled=QuickLogRow(10,24.0,unit="reps")
  assertEquals(listOf(sled),QuickLogRows.validate(listOf(sled),
   ExerciseInputMode.LOAD_DISTANCE,"meters",false,repsOrMeters=true))
  assertTrue(runCatching {QuickLogRows.validate(listOf(sled),
   ExerciseInputMode.LOAD_DISTANCE,"meters",false)}.isFailure)
  // LOAD_REPS (walking lunge) acepta metros con el flag.
  val lunge=QuickLogRow(20,16.0,unit="meters")
  assertEquals(listOf(lunge),QuickLogRows.validate(listOf(lunge),
   ExerciseInputMode.LOAD_REPS,"reps",false,repsOrMeters=true))
  assertTrue(runCatching {QuickLogRows.validate(listOf(lunge),
   ExerciseInputMode.LOAD_REPS,"reps",false)}.isFailure)
  // Tope 100_000 en metros con lastre (Apple quantityMetric cap).
  assertEquals(100000,QuickLogInput.quantityCap(ExerciseInputMode.LOAD_REPS,"meters",true))
  assertEquals(50,QuickLogInput.quantityCap(ExerciseInputMode.LOAD_REPS,"reps",true))
  assertEquals(20,QuickLogDefaults.row(ExerciseInputMode.LOAD_DISTANCE,"meters",
   false,false,null,repsOrMeters=true).quantity)
 }

 @Test fun unweightedRepsOrMetersToggle() {
  // Apple f7109bd7: burpee broad jump / bear crawl (sin lastre) alternan reps/m.
  val bbj=QuickLogRow(30,durationSeconds=60,unit="reps")
  assertEquals(listOf(bbj),QuickLogRows.validate(listOf(bbj),
   ExerciseInputMode.MACHINE_WORK,"meters",false,repsOrMeters=true))
  val bbjM=QuickLogRow(20,durationSeconds=60,unit="meters")
  assertEquals(listOf(bbjM),QuickLogRows.validate(listOf(bbjM),
   ExerciseInputMode.MACHINE_WORK,"meters",false,repsOrMeters=true))
  // Sin el flag, burpee broad jump sigue sin toggle.
  assertTrue(runCatching {QuickLogRows.validate(listOf(bbj),
   ExerciseInputMode.MACHINE_WORK,"meters",false)}.isFailure)
  // Bear crawl (REPS_ONLY) admite metros con el flag, nunca kg.
  val crawl=QuickLogRow(15,unit="meters")
  assertEquals(listOf(crawl),QuickLogRows.validate(listOf(crawl),
   ExerciseInputMode.REPS_ONLY,"reps",false,repsOrMeters=true))
  assertTrue(runCatching {QuickLogRows.validate(listOf(QuickLogRow(15,10.0,unit="meters")),
   ExerciseInputMode.REPS_ONLY,"reps",false,repsOrMeters=true)}.isFailure)
 }

 @Test fun resolveQuantityUnitHonorsPrescribedRepsOrMeters() {
  // Apple f7109bd7 SessionController: la unidad prescrita del recorrido se conserva.
  assertEquals("reps",EditorBlockOps.resolveQuantityUnit("Walking lunge","Peso corporal","reps",null))
  assertEquals("meters",EditorBlockOps.resolveQuantityUnit("Walking lunge","Peso corporal","meters",null))
  assertEquals("meters",EditorBlockOps.resolveQuantityUnit("Farmer carry","Mancuernas",null,null))
  assertEquals("reps",EditorBlockOps.resolveQuantityUnit("Bear crawl","Peso corporal","reps",null))
  // Un ejercicio normal ignora la prescrita (sigue reps por defecto).
  assertEquals("reps",EditorBlockOps.resolveQuantityUnit("Press banca","Barra","meters",null))
 }
}
