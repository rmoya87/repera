package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.Notes
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

@Composable
internal fun ActiveSessionControls(
    active: ActiveWorkout,
    busy: Boolean,
    onSelect: (Int) -> Unit,
    onNotes: (String) -> Unit,
    onFavorite: () -> Unit = {},
    onEdit: () -> Unit = {},
    onReorder: () -> Unit = onEdit,
    onDiscard: () -> Unit = {},
    /** Cuando la toolbar de Play lleva chevrons (paridad WorkoutView). */
    showExerciseNav: Boolean = true,
    onConfigureBlockTimer: () -> Unit = {},
    accountId: String = "",
    /** I-40 Sustituir / Eliminar ejercicio en Play. */
    catalog: List<ExerciseEntry> = emptyList(),
    onSubstituteExercise: (ExerciseEntry) -> Unit = {},
    onRemoveExercise: () -> Unit = {}
) {
    var choosing by remember { mutableStateOf(false) }
    var editingNotes by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var confirmCancel by remember { mutableStateOf(false) }
    var showSubstitute by remember { mutableStateOf(false) }
    var confirmRemove by remember { mutableStateOf(false) }
    val noteScope = remember(accountId, active.id) { org.json.JSONArray(listOf(accountId, active.id)).toString() }
    val noteSaver = remember(noteScope) {
        androidx.compose.runtime.saveable.Saver<String, String>(
            save = { saveScopedEditorValue(noteScope, it) },
            restore = { restoreScopedEditorValue(noteScope, it) })
    }
    var notes by rememberSaveable(accountId, active.id, active.notes, stateSaver = noteSaver) {
        mutableStateOf(active.notes.orEmpty())
    }
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            if (showExerciseNav) {
                IconButton(
                    enabled = !busy && active.index > 0,
                    onClick = { onSelect(active.index - 1) },
                    modifier = Modifier.testTag("active_previous")
                ) {
                    Icon(Icons.AutoMirrored.Outlined.KeyboardArrowLeft, contentDescription = "Anterior")
                }
            }
            IconButton(
                enabled = !busy && active.navigationEntries.isNotEmpty(),
                onClick = { choosing = true }
            ) {
                Icon(Icons.Outlined.List, contentDescription = "Ejercicios")
            }
            if (showExerciseNav) {
                IconButton(
                    enabled = !busy && active.index < active.total - 1,
                    onClick = { onSelect(active.index + 1) },
                    modifier = Modifier.testTag("active_navigate_next")
                ) {
                    Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = "Siguiente")
                }
            }
            IconButton(enabled = !busy, onClick = onConfigureBlockTimer,
                modifier = Modifier.testTag("active_block_timer")) {
                Icon(Icons.Outlined.Timer, contentDescription = "Temporizador del bloque")
            }
            IconButton(enabled = !busy, onClick = { editingNotes = true }) {
                Icon(Icons.Outlined.Notes, contentDescription = if (active.notes.isNullOrBlank()) "Añadir notas" else "Editar notas")
            }
            IconButton(
                enabled = !busy && !active.isFavorite,
                onClick = onFavorite
            ) {
                Icon(
                    if (active.isFavorite) Icons.Outlined.Star else Icons.Outlined.StarBorder,
                    contentDescription = if (active.isFavorite) "En favoritos" else "Favorito"
                )
            }
            Box {
                IconButton(enabled = !busy, onClick = { menuOpen = true }) {
                    Icon(Icons.Outlined.MoreVert, contentDescription = "Más")
                }
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    DropdownMenuItem(
                        text = { Text("Editar entreno") },
                        leadingIcon = { Icon(Icons.Outlined.Edit, contentDescription = null) },
                        onClick = { menuOpen = false; onEdit() }
                    )
                    DropdownMenuItem(
                        text = { Text("Reordenar") },
                        leadingIcon = { Icon(Icons.Outlined.Edit, contentDescription = null) },
                        onClick = { menuOpen = false; onReorder() },
                        modifier = Modifier.testTag("active_reorder")
                    )
                    if (active.wod == null) {
                        DropdownMenuItem(
                            text = { Text("Sustituir ejercicio") },
                            onClick = { menuOpen = false; showSubstitute = true },
                            modifier = Modifier.testTag("active_substitute")
                        )
                        DropdownMenuItem(
                            text = { Text("Eliminar ejercicio") },
                            enabled = active.total > 1,
                            onClick = { menuOpen = false; confirmRemove = true },
                            modifier = Modifier.testTag("active_remove_exercise")
                        )
                    }
                    DropdownMenuItem(
                        text = { Text("Cancelar entreno") },
                        leadingIcon = {
                            Icon(Icons.Outlined.MoreVert, contentDescription = null,
                                tint = MaterialTheme.colorScheme.error)
                        },
                        onClick = { menuOpen = false; confirmCancel = true }
                    )
                }
            }
        }
    }
    if (showSubstitute) {
        SubstituteExerciseSheet(
            active = active,
            catalog = catalog,
            onPick = { entry -> showSubstitute = false; onSubstituteExercise(entry) },
            onDismiss = { showSubstitute = false }
        )
    }
    if (confirmRemove) {
        AlertDialog(
            onDismissRequest = { confirmRemove = false },
            title = { Text("¿Eliminar ejercicio?") },
            text = { Text("Se quita «${active.exerciseName}» de la sesión en curso.") },
            confirmButton = {
                TextButton(onClick = { confirmRemove = false; onRemoveExercise() }) {
                    Text("Eliminar", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmRemove = false }) { Text("Cancelar") }
            }
        )
    }
    if (confirmCancel) {
        AlertDialog(
            onDismissRequest = { confirmCancel = false },
            title = { Text("¿Cancelar entreno?") },
            text = { Text("Se borra la sesión en curso sin guardarla. No aparecerá en el historial.") },
            confirmButton = {
                TextButton(onClick = { confirmCancel = false; onDiscard() }) {
                    Text("Cancelar entreno", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmCancel = false }) { Text("Seguir entrenando") }
            }
        )
    }
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
