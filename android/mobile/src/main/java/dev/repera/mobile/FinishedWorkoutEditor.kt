package dev.repera.mobile

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/** Editor de un entreno terminado (WorkoutDetailView.isEditing iOS): título,
 *  inicio/fin, lugar (sólo sin ruta) y notas. Trabaja sobre un BORRADOR local:
 *  nada se escribe hasta «Guardar»; «Cancelar» descarta (historial intacto). */
@Composable
internal fun FinishedWorkoutEditorSection(
    workout: WorkoutHistoryEntry,
    accountId: String,
    busy: Boolean,
    onSave: (WorkoutRepository.FinishedWorkoutEdit) -> Unit
) {
    var editing by remember(workout.id) { mutableStateOf(false) }
    val hasRoute = workout.routePoints.size >= 2
    if (!editing) {
        if (!hasRoute && workout.locationPin != null) {
            Text("Lugar", style = MaterialTheme.typography.titleMedium)
            Text(workout.locationPin.name?.takeIf { it.isNotBlank() } ?: "Lugar en el mapa")
            PlacePinMap(workout.locationPin.latitude, workout.locationPin.longitude,
                isInteractive = false,
                modifier = Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(12.dp)))
        }
        workout.notes?.let {
            Text("Notas", style = MaterialTheme.typography.titleMedium)
            Text(it, style = MaterialTheme.typography.bodyMedium)
        }
        TextButton(onClick = { editing = true }, enabled = !busy,
            modifier = Modifier.testTag("edit_finished_workout")) { Text("Editar entreno") }
        return
    }
    // Borrador: se reinicia cada vez que se entra en edición.
    var title by remember(workout.id) { mutableStateOf(workout.title) }
    var startIso by remember(workout.id) { mutableStateOf(workout.startedAtIso) }
    var endIso by remember(workout.id) { mutableStateOf(workout.finishedAtIso) }
    var notes by remember(workout.id) { mutableStateOf(workout.notes.orEmpty()) }
    var pin by remember(workout.id) { mutableStateOf(workout.locationPin) }
    var pinEdited by remember(workout.id) { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Editar", style = MaterialTheme.typography.titleMedium)
        OutlinedTextField(value = title, onValueChange = { title = it },
            label = { Text("Nombre del entreno") }, singleLine = true,
            modifier = Modifier.fillMaxWidth().testTag("edit_title"))
        DateTimeRow("Inicio", startIso, "edit_start") { startIso = it }
        DateTimeRow("Fin", endIso, "edit_end") { endIso = it }
        if (!hasRoute) {
            Text("Lugar", style = MaterialTheme.typography.titleMedium)
            WorkoutPlacePickerRow(pin = pin, accountId = accountId,
                onPinChange = { pin = it; pinEdited = true })
        }
        OutlinedTextField(value = notes, onValueChange = { notes = it },
            label = { Text("Notas: cómo te sentiste, molestias…") }, minLines = 2, maxLines = 5,
            modifier = Modifier.fillMaxWidth().testTag("edit_notes"))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(enabled = !busy, modifier = Modifier.testTag("edit_save"), onClick = {
                onSave(WorkoutRepository.FinishedWorkoutEdit(
                    title = title, startedAtIso = startIso, finishedAtIso = endIso,
                    notes = notes, pinEdited = pinEdited, pin = pin))
                editing = false
            }) { Text("Guardar") }
            TextButton(modifier = Modifier.testTag("edit_cancel"),
                onClick = { editing = false }) { Text("Cancelar") }
        }
    }
}

private val shownFormat = DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm")

@Composable
private fun DateTimeRow(label: String, iso: String?, tag: String, onChange: (String) -> Unit) {
    val context = LocalContext.current
    val zone = ZoneId.systemDefault()
    val current = remember(iso) {
        iso?.let { runCatching { Instant.parse(it).atZone(zone) }.getOrNull() } ?: ZonedDateTime.now(zone)
    }
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyLarge)
        TextButton(modifier = Modifier.testTag(tag), onClick = {
            DatePickerDialog(context, { _, y, m, d ->
                TimePickerDialog(context, { _, h, min ->
                    onChange(current.withYear(y).withMonth(m + 1).withDayOfMonth(d)
                        .withHour(h).withMinute(min).withSecond(0).withNano(0).toInstant().toString())
                }, current.hour, current.minute, true).show()
            }, current.year, current.monthValue - 1, current.dayOfMonth).show()
        }) { Text(current.format(shownFormat)) }
    }
}
