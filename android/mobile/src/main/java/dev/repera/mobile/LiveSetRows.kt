package dev.repera.mobile

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
 * Filas Play: escribir guarda; tocar el badge numérico marca la serie hecha
 * (extra Ramón / I-40). Saves debounced; flush al salir.
 */
/** Háptico success al marcar serie hecha (paridad RestFeedback iOS). */
internal fun playSetCompleteHaptic(context: android.content.Context) {
 runCatching {
  val vibrator = if (Build.VERSION.SDK_INT >= 31) {
   context.getSystemService(VibratorManager::class.java)?.defaultVibrator
  } else {
   @Suppress("DEPRECATION")
   context.getSystemService(Vibrator::class.java)
  } ?: return
  if (Build.VERSION.SDK_INT >= 29) {
   vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
  } else {
   @Suppress("DEPRECATION")
   vibrator.vibrate(VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE))
  }
 }
}

@Composable
internal fun LiveSetRows(active:ActiveWorkout,initial:List<LiveRowSummary>,effortUnit:String) {
 val key=active.id+"|"+active.index
 val context = LocalContext.current
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
 fun toggleCompleted(i: Int) {
  val wasDone = rows[i].completed
  rows[i] = rows[i].copy(completed = !wasDone)
  if (!wasDone) playSetCompleteHaptic(context)
  touch()
 }
 // Hand the newest rows over at once; the activity keeps them in memory and saves them (debounced or before any other action).
 LaunchedEffect(key,rows.toList(),unit,edited) {
  if(edited) persist(active.id,active.index,LiveRowEdit.toDraftRows(rows.toList()),unit)
 }
 Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
  if(active.cardioToggle || active.repsMetersToggle) Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
   listOf((if(active.repsMetersToggle) "reps" to "Repeticiones" else "calories" to "Calorías"),"meters" to "Metros").forEach {(v,l) ->ReperaFilterChip(selected=unit==v,onClick={unit=v;touch()},label={Text(l)})}
  }
  // R7 P1: cabecera SERIE · ANTERIOR · REPS · RIR (PlayEditableSetsView iOS).
  Row(
   Modifier.fillMaxWidth().padding(horizontal = 4.dp),
   verticalAlignment = Alignment.CenterVertically,
   horizontalArrangement = Arrangement.spacedBy(8.dp)
  ) {
   Text("SERIE", style = MaterialTheme.typography.labelSmall,
    modifier = Modifier.width(40.dp), textAlign = TextAlign.Center)
   Text("ANTERIOR", style = MaterialTheme.typography.labelSmall,
    modifier = Modifier.weight(1f))
   Text(
    when (unit) { "calories" -> "CAL"; "meters" -> "M"; else -> "REPS" },
    style = MaterialTheme.typography.labelSmall,
    modifier = Modifier.weight(0.9f)
   )
   if (!active.durationInput) {
    Text(Effort.displayName(effortUnit).uppercase(),
     style = MaterialTheme.typography.labelSmall,
     modifier = Modifier.weight(0.7f))
   }
  }
  rows.forEachIndexed {i,row ->
   key(row.id) {
    Row(
     Modifier
      .fillMaxWidth()
      .clip(RoundedCornerShape(10.dp))
      .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f))
      .padding(horizontal = 8.dp, vertical = 8.dp),
     verticalAlignment = Alignment.CenterVertically,
     horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
     Box(
      Modifier
       .size(34.dp)
       .clip(CircleShape)
       .background(if(row.completed) brandGreen else MaterialTheme.colorScheme.surface)
       .clickable { toggleCompleted(i) }
       .testTag("set_badge_${i+1}"),
      contentAlignment=Alignment.Center
     ) {
      Text(
       "${i+1}",
       color=if(row.completed) Color.Black else MaterialTheme.colorScheme.onSurfaceVariant,
       fontWeight=FontWeight.Bold,
       style=MaterialTheme.typography.labelLarge
      )
     }
     Text(
      if (row.completed) "Hecha" else "—",
      style = MaterialTheme.typography.bodySmall,
      color = MaterialTheme.colorScheme.onSurfaceVariant,
      modifier = Modifier.weight(1f)
     )
     OutlinedTextField(
      value = row.reps.toString(),
      onValueChange = { v ->
       rows[i]=LiveRowEdit.reps(rows[i],v,if(active.repsMetersToggle) {if(unit=="meters") 100000 else 50} else active.quantityCap)
       touch()
      },
      singleLine = true,
      modifier = Modifier.weight(0.9f).heightIn(min = 48.dp).testTag("set_reps_${i+1}"),
      textStyle = MaterialTheme.typography.bodyMedium
     )
     if (active.durationInput) {
      OutlinedTextField(
       value = (row.durationSeconds ?: 0).toString(),
       onValueChange = { v -> rows[i]=LiveRowEdit.duration(rows[i],v); touch() },
       singleLine = true,
       modifier = Modifier.weight(0.7f),
       textStyle = MaterialTheme.typography.bodyMedium
      )
     } else {
      Box(Modifier.weight(0.7f)) {
       EffortMenuField(storedRir = row.rir, effortUnit = effortUnit) { next ->
        rows[i] = rows[i].copy(rir = next); touch()
       }
      }
     }
    }
    if (active.allowsDeficit || active.allowsWeight) {
     Row(Modifier.fillMaxWidth().padding(start = 48.dp, top = 4.dp),
      horizontalArrangement = Arrangement.spacedBy(8.dp)) {
      if (active.allowsDeficit) {
       OutlinedTextField(
        value = (row.deficitCm ?: 0).toString(),
        onValueChange = { v -> rows[i]=LiveRowEdit.deficit(rows[i],v); touch() },
        label = { Text("Déficit HSPU (cm)") },
        singleLine = true,
        modifier = Modifier.weight(1f)
       )
      } else if (active.allowsWeight) {
       OutlinedTextField(
        value = row.weightKg?.let { dev.repera.domain.ReperaNumberFormat.decimal(it) }.orEmpty(),
        onValueChange = { v -> rows[i]=LiveRowEdit.weight(rows[i],v); touch() },
        label = { Text("Peso (kg)") },
        singleLine = true,
        modifier = Modifier.weight(1f)
       )
      }
      TextButton(onClick={rows.removeAt(i);touch()}) {Text("Quitar")}
     }
    } else {
     TextButton(
      onClick={rows.removeAt(i);touch()},
      modifier = Modifier.padding(start = 48.dp)
     ) {Text("Quitar serie")}
    }
   }
  }
  TextButton(onClick={
   val last=rows.lastOrNull()
   val seed=last?:LiveRowSummary("",active.prescribedQuantity?:0,active.prescribedWeightKg,
    if(active.allowsDeficit) active.prescribedWeightKg?.toInt() else null,null,null,false)
   // Apple addLiveSet: hereda déficit/peso de la fila previa.
   rows.add(seed.copy(id=java.util.UUID.randomUUID().toString(),completed=false));touch()
  },enabled=rows.size<100) {Text("+ Serie")}
 }
}
