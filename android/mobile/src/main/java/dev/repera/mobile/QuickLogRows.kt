package dev.repera.mobile
import dev.repera.domain.ExerciseInputMode
data class QuickLogRow(val quantity:Int,val weightKg:Double?=null,val durationSeconds:Int?=null,val deficitCm:Int?=null,val unit:String="reps")
internal object QuickLogRows {
 fun validate(rows:List<QuickLogRow>,mode:ExerciseInputMode,defaultUnit:String,allowsToggle:Boolean,mobilityHold:Boolean=false,weightedRepsOrMeters:Boolean=false):List<QuickLogRow> {
  require(rows.isNotEmpty() && rows.size<=100) {"Añade entre 1 y 100 series"}
  require(rows.all {it.quantity>=0}) {"Revisa la cantidad de las series"}
  require(rows.all {it.durationSeconds==null || it.durationSeconds>=0}) {"Revisa la duración de las series"}
  val valid=rows.filter {it.quantity>0 && (!mobilityHold || (it.durationSeconds ?: 0)>0)}
  require(valid.isNotEmpty()) {"Añade una serie con cantidad y duración válidas"}
  require(rows.map {it.unit}.distinct().size==1) {"Usa la misma unidad en todas las series"}
  valid.forEach {row ->
   // Apple 1d1edc8b: con lastre y metros el tope es 100_000 (como ergometros).
   val cap=if(weightedRepsOrMeters && row.unit=="meters") 100000
    else when(mode) {ExerciseInputMode.MACHINE_WORK->100000;ExerciseInputMode.REPS_AND_TIME->999;ExerciseInputMode.REPS_ONLY->99;else->50}
   require(row.quantity in 1..cap) {"Cantidad inválida"}
   require(row.weightKg==null || row.weightKg.isFinite() && row.weightKg in 0.0..1500.0) {"Peso inválido"}
   require(mode.showsWeight || row.weightKg==null) {"Este ejercicio no registra peso"}
   require(row.deficitCm==null || mode==ExerciseInputMode.HSPU_DEFICIT && row.deficitCm in 0..60) {"Déficit inválido"}
   require(row.durationSeconds==null || row.durationSeconds in 0..86400) {"Duración inválida"}
   if(mode in setOf(ExerciseInputMode.MACHINE_WORK,ExerciseInputMode.REPS_AND_TIME)) require(row.durationSeconds!=null) {"Indica duración"}
   else require(row.durationSeconds==null) {"Este ejercicio no registra duración"}
   when(mode) {
    // Apple 1d1edc8b/3432a1a9: los transportes con carga alternan reps/metros.
    ExerciseInputMode.LOAD_DISTANCE->require(row.unit=="meters" || weightedRepsOrMeters && row.unit=="reps")
    ExerciseInputMode.MACHINE_WORK->require(row.unit in setOf("calories","meters") && (allowsToggle || row.unit==defaultUnit))
    else->require(row.unit=="reps" || weightedRepsOrMeters && row.unit=="meters")
   }
  }
  return valid
 }
}

/** Entrada tecleada -> valor del modelo, igual que QuickLogSheet de Apple (`parseInt(cap:)`, `roundWeight`): recorta, no rechaza. */
internal object QuickLogInput {
 const val MAX_WEIGHT_KG=1500.0
 const val MAX_DEFICIT_CM=60
 const val MAX_DURATION_SECONDS=86_400
 fun quantityCap(mode:ExerciseInputMode):Int=when(mode) {ExerciseInputMode.MACHINE_WORK->100_000;ExerciseInputMode.REPS_AND_TIME->999;ExerciseInputMode.REPS_ONLY->99;else->50}
 /** Apple 1d1edc8b quantityMetric cap: metros con lastre -> 100_000. */
 fun quantityCap(mode:ExerciseInputMode,unit:String,weightedRepsOrMeters:Boolean):Int=
  if(weightedRepsOrMeters && unit=="meters") 100_000 else quantityCap(mode)
 /** Texto no numerico o vacio = 0; fuera de rango se recorta a 0..cap. Un entero demasiado grande para Int sube al tope. */
 fun int(text:String,cap:Int):Int {
  val t=text.trim()
  val n=t.toIntOrNull() ?: if(t.isNotEmpty() && t.all {it.isDigit()}) Int.MAX_VALUE else 0
  return minOf(cap,maxOf(0,n))
 }
 /** Coma o punto; redondeo a 2 decimales, 0..1500. Vacio o no numerico = 0.0 (Apple guarda sin peso cuando <= 0, aqui null). */
 fun weight(text:String):Double? {
  val v=dev.repera.domain.ReperaNumberFormat.parse(text.trim()) ?: 0.0
  if(v.isNaN()||v<=0.0) return null
  val r=Math.floor(v*100.0+0.5)/100.0
  return minOf(MAX_WEIGHT_KG,r).takeIf {it>0.0}
 }
}
