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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
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
private fun CompactSetField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    testTag: String? = null,
    keyboardType: KeyboardType = KeyboardType.Number
) {
    val shape = RoundedCornerShape(10.dp)
    Box(
        modifier = modifier
            .heightIn(min = 36.dp)
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
            .padding(horizontal = 10.dp, vertical = 8.dp)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        contentAlignment = Alignment.Center
    ) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium.copy(
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center
            ),
            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            modifier = Modifier.fillMaxWidth()
        )
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
 Column(verticalArrangement=Arrangement.spacedBy(6.dp)) {
  if(active.cardioToggle || active.repsMetersToggle) Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
   listOf((if(active.repsMetersToggle) "reps" to "Repeticiones" else "calories" to "Calorías"),"meters" to "Metros").forEach {(v,l) ->ReperaFilterChip(selected=unit==v,onClick={unit=v;touch()},label={Text(l)})}
  }
  // R8 P0: cabecera SERIE · ANTERIOR · REPS · RIR compacta (iOS PlayEditableSetsView).
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
    modifier = Modifier.weight(0.9f),
    textAlign = TextAlign.Center
   )
   if (!active.durationInput) {
    Text(Effort.displayName(effortUnit).uppercase(),
     style = MaterialTheme.typography.labelSmall,
     modifier = Modifier.weight(0.7f),
     textAlign = TextAlign.Center)
   }
  }
  rows.forEachIndexed {i,row ->
   key(row.id) {
    Row(
     Modifier
      .fillMaxWidth()
      .heightIn(min = 48.dp)
      .padding(horizontal = 4.dp, vertical = 2.dp),
     verticalAlignment = Alignment.CenterVertically,
     horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
     Box(
      Modifier
       .size(34.dp)
       .clip(CircleShape)
       .background(if(row.completed) brandGreen else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f))
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
     CompactSetField(
      value = row.reps.toString(),
      onValueChange = { v ->
       rows[i]=LiveRowEdit.reps(rows[i],v.filter(Char::isDigit),if(active.repsMetersToggle) {if(unit=="meters") 100000 else 50} else active.quantityCap)
       touch()
      },
      modifier = Modifier.weight(0.9f),
      testTag = "set_reps_${i+1}"
     )
     if (active.durationInput) {
      CompactSetField(
       value = (row.durationSeconds ?: 0).toString(),
       onValueChange = { v -> rows[i]=LiveRowEdit.duration(rows[i],v.filter(Char::isDigit)); touch() },
       modifier = Modifier.weight(0.7f)
      )
     } else {
      Box(Modifier.weight(0.7f)) {
       EffortMenuField(storedRir = row.rir, effortUnit = effortUnit, compact = true) { next ->
        rows[i] = rows[i].copy(rir = next); touch()
       }
      }
     }
    }
    // Peso / déficit en la misma densidad iOS (sin «Quitar serie» por fila).
    if (active.allowsDeficit || active.allowsWeight) {
     Row(Modifier.fillMaxWidth().padding(start = 48.dp, end = 4.dp),
      horizontalArrangement = Arrangement.spacedBy(8.dp),
      verticalAlignment = Alignment.CenterVertically) {
      if (active.allowsDeficit) {
       CompactSetField(
        value = (row.deficitCm ?: 0).takeIf { it > 0 }?.toString().orEmpty(),
        onValueChange = { v -> rows[i]=LiveRowEdit.deficit(rows[i],v.filter(Char::isDigit)); touch() },
        modifier = Modifier.weight(1f)
       )
      } else if (active.allowsWeight) {
       CompactSetField(
        value = row.weightKg?.let { dev.repera.domain.ReperaNumberFormat.decimal(it) }.orEmpty(),
        onValueChange = { v -> rows[i]=LiveRowEdit.weight(rows[i],v); touch() },
        modifier = Modifier.weight(1f),
        keyboardType = KeyboardType.Decimal
       )
      }
     }
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
