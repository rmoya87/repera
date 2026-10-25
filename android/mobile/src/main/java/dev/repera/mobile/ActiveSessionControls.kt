package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag

@Composable
internal fun ActiveSessionControls(active:ActiveWorkout,busy:Boolean,onSelect:(Int)->Unit,onNotes:(String)->Unit) {
    var choosing by remember {mutableStateOf(false)}
    var editingNotes by remember {mutableStateOf(false)}
    var notes by rememberSaveable(active.id,active.notes) {mutableStateOf(active.notes.orEmpty())}
    Row {
        TextButton(enabled=!busy && active.index>0,onClick={onSelect(active.index-1)},modifier=Modifier.testTag("active_previous")) {Text("Anterior")}
        TextButton(enabled=!busy && active.navigationEntries.isNotEmpty(),onClick={choosing=true}) {Text("Ejercicios")}
        TextButton(enabled=!busy && active.index<active.total-1,onClick={onSelect(active.index+1)},modifier=Modifier.testTag("active_navigate_next")) {Text("Siguiente")}
    }
    TextButton(enabled=!busy,onClick={editingNotes=true}) {Text(if(active.notes.isNullOrBlank()) "Añadir notas" else "Editar notas")}
    if(choosing) AlertDialog(onDismissRequest={choosing=false},title={Text("Ejercicios y bloques")},
        text={Column(Modifier.verticalScroll(rememberScrollState())) {
            active.navigationEntries.forEach {entry ->
                TextButton(enabled=!busy,onClick={choosing=false;onSelect(entry.index)}) {
                    Text("${if(entry.index==active.index) "● " else ""}${entry.index+1}. ${entry.name}${if(entry.blockKind=="wod") " · WOD" else ""}${if(entry.completed) " · realizado" else ""}")
                }
            }
        }},confirmButton={TextButton(onClick={choosing=false}) {Text("Cerrar")}})
    if(editingNotes) AlertDialog(onDismissRequest={editingNotes=false},title={Text("Notas del entreno")},
        text={OutlinedTextField(notes,{notes=it},modifier=Modifier.testTag("active_notes_input"),label={Text("Notas")})},
        confirmButton={TextButton(enabled=!busy,onClick={editingNotes=false;onNotes(notes)}) {Text("Guardar notas")}},
        dismissButton={TextButton(onClick={notes=active.notes.orEmpty();editingNotes=false}) {Text("Cancelar")}})
}
