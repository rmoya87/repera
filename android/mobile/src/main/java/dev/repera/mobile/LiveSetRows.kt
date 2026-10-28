package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.Effort

/** Fields of one editable Play row, parsed with the same clamping as Apple (QuickLogInput). Pure, JVM tested. */
internal object LiveRowEdit {
 fun reps(row:LiveRowSummary,text:String,cap:Int)=row.copy(reps=QuickLogInput.int(text,cap))
 fun weight(row:LiveRowSummary,text:String)=row.copy(weightKg=QuickLogInput.weight(text))
 fun deficit(row:LiveRowSummary,text:String)=row.copy(deficitCm=QuickLogInput.int(text,QuickLogInput.MAX_DEFICIT_CM).takeIf {it>0})
 fun duration(row:LiveRowSummary,text:String)=row.copy(durationSeconds=QuickLogInput.int(text,QuickLogInput.MAX_DURATION_SECONDS).takeIf {it>0})
 /** Blank = no RIR. The text is in the user's effort unit (RIR or RPE); the row stores RIR. */
 fun effort(row:LiveRowSummary,text:String,effortUnit:String):LiveRowSummary {
  val v=text.trim().replace(',','.').toDoubleOrNull()?.takeIf {it.isFinite()&&it>=0&&(effortUnit!="rpe"||it<=10)}
  return row.copy(rir=v?.let {Effort.toRIR(it,effortUnit)})
 }
 /**
  * Results recorded outside the open rows (Wear, classic form) appear as new completed rows, before the pending ones; ids the
  * rows already know (including ones the user deleted) are never re-added, and local edits are never replaced.
  * Returns the new rows; `known` is updated.
  */
 fun reconcile(rows:List<LiveRowSummary>,known:MutableSet<String>,incoming:List<LiveRowSummary>):List<LiveRowSummary> {
  val out=rows.toMutableList()
  incoming.filter {it.completed&&it.id !in known}.forEach {r ->
   known.add(r.id)
   out.add(out.indexOfFirst {!it.completed}.let {if(it<0) out.size else it},r)
  }
  return out
 }
 fun toDraftRows(rows:List<LiveRowSummary>)=rows.map {ActiveSessionDraft.Row(it.id,it.reps,it.weightKg,it.deficitCm,it.durationSeconds,it.rir,it.completed)}
}

/**
 * Apple Play rows: no per-set check, writing is saving. Rows start as the prescription (and recorded sets); nothing is
 * saved until the user edits one (untouched suggestions stay suggestions). Saves are debounced and flushed on leaving.
 * Compile-only UI: not visually validated.
 */
@Composable
internal fun LiveSetRows(active:ActiveWorkout,initial:List<LiveRowSummary>,effortUnit:String) {
 val key=active.id+"|"+active.index
 val rows=remember(key) {mutableStateListOf<LiveRowSummary>().apply {addAll(initial)}}
 var unit by remember(key) {mutableStateOf(active.quantityUnit)}
 var edited by remember(key) {mutableStateOf(false)}
 // Results recorded outside these rows (Wear, classic form) show up as completed rows; otherwise the next edit would drop them.
 val known=remember(key) {HashSet<String>().apply {initial.forEach {add(it.id)}}}
 LaunchedEffect(key,initial) {
  val merged=LiveRowEdit.reconcile(rows.toList(),known,initial)
  if(merged!=rows.toList()) {rows.clear();rows.addAll(merged)}
 }
 val persist=LocalPersistLiveRows.current
 fun touch() {edited=true}
 // Hand the newest rows over at once; the activity keeps them in memory and saves them (debounced or before any other action).
 LaunchedEffect(key,rows.toList(),unit,edited) {
  if(edited) persist(active.id,active.index,LiveRowEdit.toDraftRows(rows.toList()),unit)
 }
 Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
  if(active.cardioToggle || active.repsMetersToggle) Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
   listOf((if(active.repsMetersToggle) "reps" to "Repeticiones" else "calories" to "Calorías"),"meters" to "Metros").forEach {(v,l) ->ReperaFilterChip(selected=unit==v,onClick={unit=v;touch()},label={Text(l)})}
  }
  rows.forEachIndexed {i,row ->
   key(row.id) {Card {Column(Modifier.padding(12.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
    Text("Serie ${i+1}",style=MaterialTheme.typography.titleSmall)
    QuickNumericField(row.reps.toString(),when(unit) {"calories"->"Calorías";"meters"->"Metros";else->if(active.durationInput&&!active.mobility) "Veces" else "Repeticiones"},true) {v ->rows[i]=LiveRowEdit.reps(rows[i],v,if(active.repsMetersToggle) {if(unit=="meters") 100000 else 50} else active.quantityCap);touch()}
    if(active.allowsDeficit) QuickNumericField((row.deficitCm?:0).toString(),"Déficit HSPU (cm)",true) {v ->rows[i]=LiveRowEdit.deficit(rows[i],v);touch()}
    else if(active.allowsWeight) QuickNumericField(row.weightKg?.let { dev.repera.domain.ReperaNumberFormat.decimal(it) }.orEmpty(),"Peso (kg)",true,decimal=true) {v ->rows[i]=LiveRowEdit.weight(rows[i],v);touch()}
    if(active.durationInput) QuickNumericField((row.durationSeconds?:0).toString(),"Duración (segundos)",true) {v ->rows[i]=LiveRowEdit.duration(rows[i],v);touch()}
    else QuickNumericField(row.rir?.let {Effort.fromRIR(it,effortUnit).toString()}.orEmpty(),if(effortUnit=="rpe") "RPE (0–10)" else "RIR",true,decimal=true) {v ->rows[i]=LiveRowEdit.effort(rows[i],v,effortUnit);touch()}
    TextButton(onClick={rows.removeAt(i);touch()}) {Text("Eliminar serie ${i+1}")}
   }}}
  }
  TextButton(onClick={
   val last=rows.lastOrNull()
   val seed=last?:LiveRowSummary("",active.prescribedQuantity?:0,active.prescribedWeightKg,
    if(active.allowsDeficit) active.prescribedWeightKg?.toInt() else null,null,null,false)
   // Apple addLiveSet: hereda déficit/peso de la fila previa.
   rows.add(seed.copy(id=java.util.UUID.randomUUID().toString(),completed=false));touch()
  },enabled=rows.size<100) {Text("Añadir serie")}
 }
}
