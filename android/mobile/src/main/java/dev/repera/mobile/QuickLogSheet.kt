package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import dev.repera.domain.*
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable

@OptIn(ExperimentalMaterial3Api::class)
@Composable internal fun QuickLogSheet(entry:ExerciseEntry,accountId:String,busy:Boolean,last:LoadGuideSet?,onDismiss:()->Unit,
 onSave:(List<QuickLogRow>,String?,String)->Unit) {
 val mode=ExerciseInput.mode(entry.name,entry.equipment,entry.targetMuscle,entry.muscleGroup,entry.sportTag)
 // Apple 1d1edc8b: walking lunge y transportes con carga alternan reps/metros con kg.
 val weightedRepsOrMeters=ExerciseInput.supportsWeightedRepsOrMeters(entry.name)
 val owner="$accountId|${entry.id}"
 val draft=rememberSaveable(owner,saver=QuickLogDraftState.saver(owner)) {QuickLogDraftState(ExerciseInput.defaultQuantityUnit(entry.name,entry.equipment),owner,null)}
 var unit by draft::unit
 val defaultRow=QuickLogDefaults.row(mode,unit,entry.sportTag=="Movilidad",entry.mobilityHold,last,weightedRepsOrMeters)
 if(!draft.initialized) {repeat(3) {draft.rows.add(defaultRow);draft.rowKeys.add(java.util.UUID.randomUUID().toString())};draft.initialized=true}
 val rows=draft.rows;val rowKeys=draft.rowKeys
 var notes by draft::notes;var includeNotes by draft::includeNotes
 val requestId=draft.requestId
 var error by remember {mutableStateOf<String?>(null)}
 ModalBottomSheet(onDismissRequest={if(!busy) onDismiss()}) {
  Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(20.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
   Text("Apuntar ejercicio",style=MaterialTheme.typography.titleLarge)
   Text(entry.displayName,style=MaterialTheme.typography.titleMedium)
   if(weightedRepsOrMeters) Row {
    // Apple: Picker "Repeticiones"/"Metros" para supportsWeightedRepsOrMeters.
    listOf("reps","meters").forEach {value ->FilterChip(selected=unit==value,onClick={unit=value;rows.indices.forEach {i ->rows[i]=rows[i].copy(unit=value)}},label={Text(if(value=="meters") "Metros" else "Repeticiones")},enabled=!busy)}
   } else if(mode==ExerciseInputMode.MACHINE_WORK && ExerciseInput.supportsCaloriesAndMeters(entry.name,entry.equipment)) Row {
    listOf("calories","meters").forEach {value ->FilterChip(selected=unit==value,onClick={unit=value;rows.indices.forEach {i ->rows[i]=rows[i].copy(unit=value)}},label={Text(if(value=="meters") "Metros" else "Cal")},enabled=!busy)}
   }
   rows.indices.forEach {i ->key(rowKeys[i]) {Card {Column(Modifier.padding(12.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
    Text("Serie ${i+1}")
    if(!entry.mobilityHold) QuickNumericField(rows[i].quantity.toString(),if(unit=="meters") "Metros" else if(unit=="calories") "Cal" else "Repeticiones",!busy) {v ->rows[i]=rows[i].copy(quantity=QuickLogInput.int(v,QuickLogInput.quantityCap(mode,unit,weightedRepsOrMeters)))}
    if(mode.showsWeight) QuickNumericField(rows[i].weightKg?.toString().orEmpty(),"Peso / lastre (kg)",!busy,decimal=true) {v ->rows[i]=rows[i].copy(weightKg=QuickLogInput.weight(v))}
    if(mode==ExerciseInputMode.HSPU_DEFICIT) QuickNumericField((rows[i].deficitCm ?: 0).toString(),"Déficit (cm)",!busy) {v ->rows[i]=rows[i].copy(deficitCm=QuickLogInput.int(v,QuickLogInput.MAX_DEFICIT_CM))}
    if(mode in setOf(ExerciseInputMode.MACHINE_WORK,ExerciseInputMode.REPS_AND_TIME)) QuickNumericField((rows[i].durationSeconds ?: 0).toString(),"Duración (segundos)",!busy) {v ->rows[i]=rows[i].copy(durationSeconds=QuickLogInput.int(v,QuickLogInput.MAX_DURATION_SECONDS))}
    TextButton(onClick={rows.removeAt(i);rowKeys.removeAt(i)},enabled=!busy) {Text("Eliminar serie ${i+1}")}
   }}}}
   TextButton(onClick={rows.add(rows.lastOrNull() ?: defaultRow);rowKeys.add(java.util.UUID.randomUUID().toString())},enabled=!busy && rows.size<100) {Text("Añadir serie")}
   Row {Switch(includeNotes,{includeNotes=it},enabled=!busy);Text("Añadir nota",Modifier.padding(12.dp))}
   if(includeNotes) OutlinedTextField(notes,{notes=it},label={Text("Cómo te sentiste, carga…")},enabled=!busy)
   error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
   Row(horizontalArrangement=Arrangement.spacedBy(12.dp)) {
    OutlinedButton(onClick=onDismiss,enabled=!busy) {Text("Cancelar")}
    Button(onClick={runCatching {QuickLogRows.validate(rows.toList(),mode,ExerciseInput.defaultQuantityUnit(entry.name,entry.equipment),ExerciseInput.supportsCaloriesAndMeters(entry.name,entry.equipment),entry.mobilityHold,weightedRepsOrMeters)}.onSuccess {error=null;onSave(it,notes.takeIf {includeNotes},requestId)}.onFailure {error=it.localizedMessage ?: "Revisa las series"}},enabled=!busy && rows.isNotEmpty()) {Text("Guardar")}
   }
   Text("Guarda directamente en el historial sin abrir ni modificar una sesión activa.",style=MaterialTheme.typography.bodySmall)
   Spacer(Modifier.height(20.dp))
  }
 }
}

/** Keep the typed draft (including empty and trailing decimal) until review/save. */
@Composable
internal fun QuickNumericField(initial:String,label:String,enabled:Boolean,decimal:Boolean=false,onChange:(String)->Unit) {
 var text by rememberSaveable {mutableStateOf(initial)}
 // Apple 643fa111 (OG.inputSurface): fondo negro suave en modo noche y gris
 // claro en modo dia, sin alterar el resto del tema.
 val inputSurface = if (androidx.compose.foundation.isSystemInDarkTheme())
     androidx.compose.ui.graphics.Color(0xFF0A0A0C) else androidx.compose.ui.graphics.Color(0xFFF2F5F3)
 OutlinedTextField(text,{value ->
  // Apple b2bb19eb: coma visible, maximo 2 decimales y pegado normalizado en
  // campos decimales; solo digitos en enteros. Edicion rechazada = sin cambio.
  val accepted=if(decimal) dev.repera.domain.ReperaNumberFormat.keypadDecimal(text,value)
      else dev.repera.domain.ReperaNumberFormat.keypadInteger(text,value)
  if(accepted!=text){text=accepted;onChange(accepted)}},label={Text(label)},enabled=enabled,singleLine=true,
  colors=androidx.compose.material3.OutlinedTextFieldDefaults.colors(
      focusedContainerColor=inputSurface,unfocusedContainerColor=inputSurface,
      disabledContainerColor=inputSurface),
  keyboardOptions=KeyboardOptions(keyboardType=if(decimal) KeyboardType.Decimal else KeyboardType.Number))
}

/** Mutable holder rebuilt from [QuickLogDraft] after recreation. */
internal class QuickLogDraftState(unit:String,val owner:String,restored:QuickLogDraft?) {
 var unit by mutableStateOf(restored?.unit ?: unit)
 val rows=mutableStateListOf<QuickLogRow>().apply {restored?.let {addAll(it.rows)}}
 val rowKeys=mutableStateListOf<String>().apply {restored?.let {addAll(it.rowKeys)}}
 var notes by mutableStateOf(restored?.notes.orEmpty())
 var includeNotes by mutableStateOf(restored?.includeNotes ?: false)
 val requestId:String=restored?.requestId ?: java.util.UUID.randomUUID().toString()
 var initialized:Boolean=restored!=null
 fun snapshot()=QuickLogDraft(unit,rows.toList(),rowKeys.toList(),notes,includeNotes,requestId,owner)
 companion object {
  fun saver(owner:String):Saver<QuickLogDraftState,Any> = Saver(
   save={ArrayList(it.snapshot().encode())},
   restore={saved->@Suppress("UNCHECKED_CAST") QuickLogDraft.decode(saved as? List<String>,owner)?.let {QuickLogDraftState(it.unit,owner,it)}})
 }
}
