package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.foundation.Canvas
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.material.icons.filled.Close
import androidx.compose.ui.window.Dialog
import androidx.compose.material.icons.filled.Close
import androidx.compose.ui.window.DialogProperties
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.draw.clip
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Switch
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import java.time.LocalDate
import java.time.LocalTime
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.ui.unit.IntOffset
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.HorizontalDivider
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay

internal val brandGreen = Color(0xFF30D158)
/** Verde legible como texto/primary sobre fondos claros (AA ~4.9:1); brandGreen da ~2:1. */
internal val brandGreenReadable = Color(0xFF0E7A38)

@Composable
internal fun ActiveWorkoutCard(
    active: ActiveWorkout,
    busy: Boolean,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?, Boolean) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onDiscard: () -> Unit = {},
    onLogDropSet: (Int, Double?, List<Pair<Int, Double?>>, Double?, Boolean) -> Unit = { _, _, _, _, _ -> },
    onLogRestPauseSet: (List<Pair<Int, Int>>, Double?, Double?, Boolean) -> Unit = { _, _, _, _ -> },
    effortUnit:String="rir"
) {
    var technique by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("normal")
    }
    var dropsText by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("")
    }
    var clustersText by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("")
    }
    var clusterRest by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("15")
    }
    var quantity by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedQuantity?.toString() ?: "")
    }
    var weight by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedWeightKg?.toString() ?: "")
    }
    var deficit by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("")
    }
    var unit by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.quantityUnit)
    }
    var durationMin by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedDurationSeconds
            ?.let { (it / 60).toString() } ?: "")
    }
    var durationSec by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedDurationSeconds
            ?.let { (it % 60).toString().padStart(2, '0') } ?: "")
    }
    val parsedDuration = if (!active.durationInput ||
        (durationMin.isBlank() && durationSec.isBlank())) null else {
        val mm = durationMin.toIntOrNull() ?: 0
        val ss = durationSec.toIntOrNull() ?: 0
        if (mm in 0..1440 && ss in 0..59 && mm * 60 + ss in 1..86400)
            mm * 60 + ss else null
    }
    val validDuration = !active.durationInput ||
        (!active.mobilityHold && durationMin.isBlank() && durationSec.isBlank()) ||
        parsedDuration != null
    var warmup by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(false)
    }
    var toFailure by remember(active.id, active.index, active.completedSets) { mutableStateOf(false) }
    var rirText by remember(active.id, active.index, active.completedSets,effortUnit) {
        mutableStateOf("")
    }
    var editingId by remember(active.id, active.index) { mutableStateOf<String?>(null) }
    var editingQuantity by remember(active.id, active.index) { mutableStateOf("") }
    var editingWeight by remember(active.id, active.index) { mutableStateOf("") }
    var editingDeficit by remember(active.id, active.index) { mutableStateOf("") }
    var editingUnit by remember(active.id, active.index) { mutableStateOf(active.quantityUnit) }
    var editingDuration by remember(active.id, active.index) { mutableStateOf("") }
    val parsedRir = rirText.trim().takeIf { it.isNotBlank() }?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
    val parsedQuantity = quantity.toIntOrNull()
    val parsedWeight = weight.trim().takeIf { it.isNotBlank() }?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
    val valid = parsedQuantity != null && parsedQuantity >= 0 &&
        (!active.allowsWeight || weight.isBlank() ||
            (parsedWeight != null && parsedWeight.isFinite() && parsedWeight >= 0)) &&
        (!active.allowsDeficit || deficit.isBlank() ||
            (deficit.toIntOrNull()?.let { it in 0..100 } == true)) &&
        (toFailure || warmup || rirText.isBlank() || (parsedRir != null && parsedRir.isFinite() && parsedRir >= 0 && (effortUnit!="rpe" || parsedRir<=10))) &&
        validDuration && (unit in if (active.cardioToggle) setOf("calories", "meters")
            else setOf(active.quantityUnit))
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text("Ejercicio ${active.index + 1}/${active.total}: ${active.exerciseName}",
                style = MaterialTheme.typography.titleMedium)
            Text("${active.completedSets} series registradas")
            active.sets.forEachIndexed { index, set ->
                if (active.liveRows != null && set.phase == "work") return@forEachIndexed
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    Text((if (set.phase == "warmup") "Calentamiento" else "Serie") +
                        " ${index + 1}: ${set.reps} " + when (set.unit) {
                            "calories" -> "cal"
                            "meters" -> "m"
                            else -> "reps"
                        } +
                        (set.weightKg?.let { " · ${dev.repera.domain.ReperaNumberFormat.decimal(it)} kg" } ?: "") +
                        (set.deficitCm?.let { " · ${dev.repera.domain.ReperaNumberFormat.decimal(it.toDouble())} cm déficit" } ?: "") +
                        (if(set.toFailure) " · F" else "") +
                        (set.rir?.let { dev.repera.domain.Effort.label(it,effortUnit)?.let { l -> " · $l" } } ?: "") +
                        (set.durationSeconds?.let { " · ${it / 60}:${(it % 60).toString().padStart(2,'0')}" } ?: ""))
                    Row {
                        TextButton(onClick = {
                            editingId = set.id
                            editingQuantity = set.reps.toString()
                            editingWeight = set.weightKg?.toString() ?: ""
                            editingDeficit = set.deficitCm?.toString() ?: ""
                            editingUnit = set.unit
                            editingDuration = set.durationSeconds?.toString() ?: ""
                        }, enabled = !busy) { Text("Editar") }
                        TextButton(onClick = {
                            if (editingId == set.id) editingId = null
                            onDeleteSet(set.id)
                        }, enabled = !busy) { Text("Eliminar") }
                    }
                }
            }
            val removePending = LocalRemovePendingSet.current
            val editPendingSet = LocalEditPendingSet.current
            var editingPendingId by remember(active.id, active.index) { mutableStateOf<String?>(null) }
            var pendingReps by remember(active.id, active.index) { mutableStateOf("") }
            var pendingWeight by remember(active.id, active.index) { mutableStateOf("") }
            (if (active.liveRows == null) active.pendingSets else emptyList()).forEachIndexed { index, pending ->
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Pendiente ${active.sets.count { it.phase == "work" } + index + 1}: ${pending.reps} " +
                        when (active.quantityUnit) { "calories" -> "cal"; "meters" -> "m"; else -> "reps" } +
                        (pending.weightKg?.let { " · $it kg" } ?: ""),
                        style = MaterialTheme.typography.bodyMedium)
                    Row {
                        TextButton(onClick = { editingPendingId = if (editingPendingId == pending.id) null else pending.id
                            pendingReps = pending.reps.toString(); pendingWeight = pending.weightKg?.toString() ?: "" }, enabled = !busy) { Text("Editar") }
                        TextButton(onClick = { removePending(pending.id) }, enabled = !busy) { Text("Quitar serie") }
                    }
                }
                if (editingPendingId == pending.id) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(pendingReps, { pendingReps = it.filter(Char::isDigit) }, label = { Text("Reps") }, singleLine = true, modifier = Modifier.weight(1f))
                        if (active.allowsWeight) OutlinedTextField(pendingWeight, { pendingWeight = it }, label = { Text("kg") }, singleLine = true, modifier = Modifier.weight(1f))
                    }
                    val kg = pendingWeight.trim().takeIf { it.isNotBlank() }?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
                    val okKg = pendingWeight.isBlank() || (kg != null && kg.isFinite() && kg >= 0)
                    TextButton(enabled = !busy && okKg && pendingReps.toIntOrNull() != null, onClick = {
                        editPendingSet(pending.id, pendingReps.toInt(), kg); editingPendingId = null }) { Text("Guardar serie pendiente") }
                }
            }
            if (editingId != null) {
                OutlinedTextField(
                    value = editingQuantity,
                    onValueChange = { editingQuantity = it.filter(Char::isDigit) },
                    label = { Text(if (active.mobilityHold) "Postura (1)"
                        else if (active.mobility) "Repeticiones"
                        else "Corregir repeticiones") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                if (active.allowsWeight) {
                    OutlinedTextField(
                        value = editingWeight,
                        onValueChange = { editingWeight = it },
                        label = { Text("Corregir peso (kg)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                if (active.allowsDeficit) {
                    OutlinedTextField(value = editingDeficit,
                        onValueChange = { editingDeficit = it.filter(Char::isDigit) },
                        label = { Text("Corregir déficit HSPU (cm)") }, singleLine = true,
                        modifier = Modifier.fillMaxWidth())
                }
                if (active.cardioToggle) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(selected = editingUnit == "calories",
                            onClick = { editingUnit = "calories" }, label = { Text("Cal") })
                        FilterChip(selected = editingUnit == "meters",
                            onClick = { editingUnit = "meters" }, label = { Text("m") })
                    }
                }
                if (active.durationInput) {
                    OutlinedTextField(value = editingDuration,
                        onValueChange = { editingDuration = it.filter(Char::isDigit) },
                        label = { Text("Duración en segundos (opcional)") }, singleLine = true,
                        modifier = Modifier.fillMaxWidth())
                }
                val parsedEdit = editingQuantity.toIntOrNull()
                val editWeight = editingWeight.trim()
                    .takeIf { it.isNotBlank() }?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
                val editValid = parsedEdit != null &&
                    (!active.allowsDeficit || editingDeficit.isBlank() ||
                        editingDeficit.toIntOrNull()?.let { it in 0..100 } == true) &&
                    (!active.durationInput || editingDuration.isBlank() ||
                        editingDuration.toIntOrNull()?.let { it in 1..86400 } == true) &&
                    (!active.allowsWeight || editingWeight.isBlank() ||
                        (editWeight != null && editWeight.isFinite() && editWeight >= 0))
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    TextButton(onClick = { editingId = null }, enabled = !busy) {
                        Text("Cancelar")
                    }
                    Button(onClick = {
                        val id = editingId
                        if (id != null && parsedEdit != null) {
                            onReviseSet(id, parsedEdit, if (active.allowsWeight) editWeight else null,
                                editingUnit, editingDuration.toIntOrNull(),
                                if (active.allowsDeficit) editingDeficit.toIntOrNull() else null)
                            editingId = null
                        }
                    }, enabled = !busy && editValid) { Text("Guardar corrección") }
                }
            }
            var showClassic by remember(active.id, active.index) { mutableStateOf(false) }
            active.liveRows?.let { rows ->
                LiveSetRows(active, rows, effortUnit)
                FilterChip(selected = showClassic, onClick = { showClassic = !showClassic },
                    label = { Text("Calentamiento o técnica (dropset, rest-pause)") })
            }
            if (active.liveRows == null || showClassic) {
            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it.filter { char -> char.isDigit() } },
                label = { Text(when (unit) {
                    "calories" -> "Calorías"
                    "meters" -> "Metros"
                    else -> when {
                        active.mobilityHold -> "Postura (1)"
                        active.mobility -> "Repeticiones"
                        active.durationInput -> "Veces"
                        else -> "Repeticiones"
                    }
                }) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (active.allowsDeficit) {
                OutlinedTextField(
                    value = deficit,
                    onValueChange = { deficit = it.filter(Char::isDigit) },
                    label = { Text("Déficit HSPU (cm, opcional)") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth())
            }
            if (active.cardioToggle) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = unit == "calories",
                        onClick = { unit = "calories" }, label = { Text("Calorías") })
                    FilterChip(selected = unit == "meters",
                        onClick = { unit = "meters" }, label = { Text("Metros") })
                }
            }
            if (active.durationInput) {
                if (active.mobilityHold) {
                    Text("Tiempo mantenido · obligatorio",
                        style = MaterialTheme.typography.labelMedium)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = durationMin,
                        onValueChange = { durationMin = it.filter(Char::isDigit) },
                        label = { Text("Minutos") }, singleLine = true,
                        modifier = Modifier.weight(1f))
                    OutlinedTextField(
                        value = durationSec,
                        onValueChange = { durationSec = it.filter(Char::isDigit) },
                        label = { Text("Segundos") }, singleLine = true,
                        modifier = Modifier.weight(1f))
                }
            }
            if (active.allowsWeight) {
                OutlinedTextField(
                    value = weight,
                    onValueChange = { weight = it },
                    label = { Text("Peso (kg)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (!active.durationInput && !warmup && !toFailure) OutlinedTextField(
                value = rirText,
                onValueChange = { rirText = it },
                label = { Text(if(effortUnit=="rpe") "RPE opcional (0–10)" else "RIR opcional (repeticiones en reserva)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (!active.durationInput) Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start
            ) {
                Checkbox(checked = warmup, onCheckedChange = { warmup = it }, enabled = !busy, modifier=Modifier.testTag("set_warmup"))
                Text("Serie de calentamiento", modifier = Modifier.padding(top = 12.dp))
            }
            if (!active.durationInput && !warmup) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically, horizontalArrangement=Arrangement.spacedBy(12.dp)) {
                    Switch(checked=toFailure,onCheckedChange={toFailure=it},enabled=!busy, modifier=Modifier.testTag("set_to_failure"))
                    Text("Al fallo")
                }
                Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf("normal" to "Normal", "dropset" to "Dropset",
                        "restpause" to "Rest-pause").forEach { option ->
                        FilterChip(selected = technique == option.first,
                            onClick = { technique = option.first },
                            label = { Text(option.second) })
                    }
                }
                if (technique == "dropset") {
                    OutlinedTextField(
                        value = dropsText,
                        onValueChange = { dropsText = it.take(80) },
                        label = { Text("Caídas: reps x kg (p. ej. 8x45, 6x40)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                }
                if (technique == "restpause") {
                    OutlinedTextField(
                        value = clustersText,
                        onValueChange = { clustersText = it.take(40) },
                        label = { Text("Mini-series en reps (p. ej. 8+5+3)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(
                        value = clusterRest,
                        onValueChange = { clusterRest = it.filter(Char::isDigit) },
                        label = { Text("Descanso entre mini-series (s)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                }
            }
            val parsedDrops = if (technique != "dropset") emptyList() else
                dropsText.split(',', ';', '·').mapNotNull { raw ->
                    val piece = raw.trim().lowercase()
                    if (piece.isEmpty()) return@mapNotNull null
                    val parts = piece.split('x', '×')
                    val reps = parts.getOrNull(0)?.trim()?.toIntOrNull()
                        ?: return@mapNotNull null
                    val weight = parts.getOrNull(1)?.trim()
                        ?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
                    reps to weight
                }
            val restSecondsValue = clusterRest.toIntOrNull()
            val parsedClusters = if (technique != "restpause") emptyList() else
                clustersText.split('+', ',', ' ').mapNotNull { it.trim().toIntOrNull() }
                    .map { it to (restSecondsValue ?: 15) }
            val effectiveTechnique = if(warmup || active.durationInput) "normal" else technique
            val validTechnique = when (effectiveTechnique) {
                "dropset" -> parsedDrops.isNotEmpty() && parsedDrops.size <= 5 &&
                    parsedDrops.all { it.first in 1..10000 &&
                        (it.second == null || it.second!! >= 0) }
                "restpause" -> parsedClusters.size in 2..8 &&
                    parsedClusters.all { it.first in 1..10000 } &&
                    restSecondsValue != null && restSecondsValue in 1..600
                else -> true
            }
            Button(
                onClick = {
                    if (parsedQuantity != null) when (effectiveTechnique) {
                        "dropset" -> onLogDropSet(
                            parsedQuantity,
                            if (active.allowsWeight) parsedWeight else null,
                            parsedDrops,
                            if(toFailure) 0.0 else parsedRir?.let {dev.repera.domain.Effort.toRIR(it,effortUnit)}, toFailure)
                        "restpause" -> onLogRestPauseSet(
                            parsedClusters,
                            if (active.allowsWeight) parsedWeight else null,
                            if(toFailure) 0.0 else parsedRir?.let {dev.repera.domain.Effort.toRIR(it,effortUnit)}, toFailure)
                        else -> onLogSet(
                            parsedQuantity,
                            if (active.allowsWeight) parsedWeight else null,
                            if (active.durationInput || warmup) null else if(toFailure) 0.0 else parsedRir?.let {dev.repera.domain.Effort.toRIR(it,effortUnit)},
                            if (active.durationInput) false else warmup,
                            unit,
                            parsedDuration,
                            if (active.allowsDeficit) deficit.toIntOrNull() else null,
                            toFailure && !warmup && !active.durationInput
                        )
                    }
                },
                enabled = !busy && valid && validTechnique,
                modifier = Modifier.fillMaxWidth()
            ) { Text("Registrar serie") }
            }
            OutlinedButton(onClick = onNext, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                Text(if (active.index + 1 == active.total) "Terminar último ejercicio" else "Siguiente ejercicio")
            }
            TextButton(onClick = onFinish, enabled = !busy) { Text("Finalizar entrenamiento") }
            // Descartar sin guardar (endActiveSession(save: false) iOS, con confirmación).
            var confirmDiscard by remember(active.id) { mutableStateOf(false) }
            TextButton(onClick = { confirmDiscard = true }, enabled = !busy) {
                Text("Descartar entreno", color = MaterialTheme.colorScheme.error)
            }
            if (confirmDiscard) {
                AlertDialog(
                    onDismissRequest = { confirmDiscard = false },
                    confirmButton = {
                        TextButton(onClick = { confirmDiscard = false; onDiscard() }) {
                            Text("Descartar", color = MaterialTheme.colorScheme.error)
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { confirmDiscard = false }) { Text("Cancelar") }
                    },
                    title = { Text("Descartar entreno en curso") },
                    text = { Text("Se borra la sesión en curso sin guardarla. No aparecerá en el historial.") }
                )
            }
        }
    }
}

/** Inline score editor like the iPhone Play review, no modal or imaginary movement sets. */
@Composable
internal fun WodScoreCard(
    active: ActiveWorkout,
    busy: Boolean,
    timer: WodTimerState?,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    onSave: (Int?, Int?, Int?) -> Unit,
    onMovement: (Int, Int, Int, Double?) -> Unit,
    onCompleteBlock: () -> Unit,
    onReviseMovement: (String, Int, Double?) -> Unit,
    onDeleteMovement: (String) -> Unit,
    onFinish: () -> Unit,
    onOpenClock: () -> Unit,
    onDiscard: () -> Unit = {}
) {
    val wod = active.wod ?: return
    val spec = WodClockSpec(
        format = WodFormat.fromWire(wod.format),
        blockTimeCapMinutes = wod.timeCapMinutes,
        intervalSeconds = wod.intervalSeconds,
        rounds = wod.rounds,
        workSeconds = wod.workSeconds,
        restSeconds = wod.restSeconds,
        restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
        stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
    )
    val elapsedClock = timer?.elapsedSeconds ?: 0
    val face = WodClock.face(spec, elapsedClock)
    // The clock is anchored to elapsedRealtime in WodTimerStore, not to UI ticks.
    LaunchedEffect(active.id, active.index, timer?.running) {
        if (timer?.running == true) {
            while (true) {
                delay(250)
                onTimerTick()
            }
        }
    }
    var rounds by remember(active.id, active.index) { mutableStateOf("") }
    var extraReps by remember(active.id, active.index) { mutableStateOf("") }
    var minutes by remember(active.id, active.index) { mutableStateOf("") }
    var seconds by remember(active.id, active.index) { mutableStateOf("") }
    val m = minutes.toIntOrNull()
    val sec = seconds.toIntOrNull()
    val elapsed = if (m != null && sec != null && sec in 0..59) {
        if (m <= (Int.MAX_VALUE - sec) / 60) m * 60 + sec else null
    } else null
    val perMovement = wod.capture == "PER_MOVEMENT_SETS"
    var selectedMovement by remember(active.id, active.index) { mutableStateOf(0) }
    var intervalInput by remember(active.id, active.index) { mutableStateOf("1") }
    var intervalEdited by remember(active.id, active.index) { mutableStateOf(false) }
    // Follow the actual monotonic WOD clock until the athlete explicitly edits the interval.
    // A clock transition never confirms reps or saves a movement.
    val suggestedInterval = when (WodFormat.fromWire(wod.format)) {
        WodFormat.EMOM, WodFormat.DEATH_BY ->
            elapsedClock / (wod.intervalSeconds ?: 60).coerceAtLeast(1) + 1
        WodFormat.CIRCUIT ->
            WodClock.activeIntervalIndex(spec, elapsedClock) + 1
        WodFormat.TABATA ->
            elapsedClock / ((wod.workSeconds ?: 20).coerceAtLeast(1) +
                (wod.restSeconds ?: 10).coerceAtLeast(0)).coerceAtLeast(1) + 1
        else -> 1
    }
    LaunchedEffect(active.id, active.index, suggestedInterval) {
        if (!intervalEdited) intervalInput = suggestedInterval.toString()
    }
    var quantityInput by remember(active.id, active.index, selectedMovement) {
        val first = wod.movements.filter { !it.isRest }.getOrNull(selectedMovement)
        mutableStateOf((first?.calories ?: first?.meters ?: first?.reps)?.toString() ?: "")
    }
    var weightInput by remember(active.id, active.index, selectedMovement) { mutableStateOf("") }
    val scoreIsTime = wod.capture == "ELAPSED_TIME"
    // Apple 39a3f7f2 pendingEnd userFinished (For Time): al pulsar "Terminar"
    // el reloj congela el elapsed REAL y lo persiste (WodTimerStore); aqui el
    // editor se siembra automaticamente con ese valor una unica vez, aunque
    // el proceso muera antes de guardar. No es un valor inventado: es el
    // tiempo registrado por el cronometro en el instante de terminar. Si el
    // atleta ya escribio algo, no se pisa su edicion; "Usar tiempo del
    // cronometro" (abajo) sigue como copia manual explicita. countdownFinished
    // (caps) queda n/a estructural: el editor de formatos con cap captura
    // rondas/reps, sin campo de tiempo que sembrar.
    LaunchedEffect(active.id, active.index, timer?.pendingEndReason, timer?.pendingElapsedSeconds) {
        val pending = timer
        if (scoreIsTime && pending?.pendingEndReason == "userFinished" &&
            pending.pendingElapsedSeconds > 0
        ) {
            if (minutes.isEmpty() && seconds.isEmpty()) {
                minutes = (pending.pendingElapsedSeconds / 60).toString()
                seconds = (pending.pendingElapsedSeconds % 60).toString().padStart(2, '0')
            }
            // Keep durable pending completion until the score is actually saved.
            // Navigating away after prefill must not lose the measured elapsed.
        }
    }
    val valid = if (scoreIsTime) elapsed != null else
        extraReps.toIntOrNull() != null && (rounds.toIntOrNull() != null || !wod.expectsRounds)

    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text("%d:%02d".format(face.primarySeconds / 60, face.primarySeconds % 60),
                style = MaterialTheme.typography.displayMedium)
            face.label?.let { label ->
                Text(label, style = MaterialTheme.typography.titleMedium)
            }
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = { onTimerAction(if (timer?.running == true) "pause" else "start") },
                    enabled = !busy && !face.finishedIntervals) {
                    Text(if (timer?.running == true) "Pausar" else if (elapsedClock > 0) "Reanudar" else "Iniciar")
                }
                OutlinedButton(onClick = { onTimerAction("reset") }, enabled = !busy) {
                    Text("Reiniciar")
                }
                TextButton(onClick = onOpenClock) {
                    Text("Pantalla completa")
                }
            }
            Text(wod.title + " · " +
                (WodFormat.fromWire(wod.format)?.displayName ?: wod.format),
                style = MaterialTheme.typography.titleMedium)
            wod.movements.forEach { movement ->
                val prefix = when {
                    movement.isRest -> movement.restSeconds?.let { "${it}s descanso" } ?: "Descanso"
                    movement.repScheme.isNotEmpty() ->
                        movement.repScheme.joinToString("-") + " reps"
                    movement.calories != null -> "${movement.calories} cal"
                    movement.meters != null -> "${movement.meters} m"
                    movement.reps != null -> "${movement.reps} reps"
                    else -> ""
                }
                Text((prefix + "  " + movement.name).trim(),
                    style = MaterialTheme.typography.bodyMedium)
            }
            if (perMovement) {
                val candidates = wod.movements.filter { !it.isRest }
                Text("Registrar movimientos realizados", style = MaterialTheme.typography.titleMedium)
                candidates.forEachIndexed { i, movement ->
                    OutlinedButton(onClick = {
                        selectedMovement = i
                        quantityInput = (movement.calories ?: movement.meters ?: movement.reps)?.toString() ?: ""
                    }, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                        Text((if (selectedMovement == i) "✓ " else "") + movement.name)
                    }
                }
                OutlinedTextField(value = intervalInput,
                    onValueChange = { intervalEdited = true; intervalInput = it.filter(Char::isDigit) },
                    label = { Text("Intervalo o ronda (desde 1)") },
                    singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = quantityInput,
                    onValueChange = { quantityInput = it.filter(Char::isDigit) },
                    label = { Text(when { candidates.getOrNull(selectedMovement)?.calories != null -> "Calorías realizadas"; candidates.getOrNull(selectedMovement)?.meters != null -> "Metros realizados"; else -> "Repeticiones realizadas" }) },
                    singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = weightInput,
                    onValueChange = { weightInput = it.filter { char -> char.isDigit() || char == '.' } },
                    label = { Text("Peso en kg (opcional)") },
                    singleLine = true, modifier = Modifier.fillMaxWidth())
                val validMovement = candidates.isNotEmpty() &&
                    intervalInput.toIntOrNull()?.let { it in 1..100000 } == true &&
                    quantityInput.toIntOrNull()?.let { it >= 0 } == true &&
                    (weightInput.isBlank() || weightInput.toDoubleOrNull()?.let {
                        it.isFinite() && it >= 0
                    } == true)
                Button(
                    onClick = {
                        onMovement(selectedMovement, intervalInput.toInt() - 1,
                            quantityInput.toInt(), weightInput.toDoubleOrNull())
                    }, enabled = !busy && validMovement,
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Confirmar movimiento") }
                wod.recorded.forEach { record ->
                    var editQuantity by remember(record.id) { mutableStateOf(record.quantity.toString()) }
                    var editWeight by remember(record.id) {
                        mutableStateOf(record.weightKg?.toString() ?: "")
                    }
                    Text("Intervalo ${record.intervalIndex + 1} · ${record.name} · ${record.quantity} ${when (record.quantityUnit) { "calories" -> "cal"; "meters" -> "m"; else -> "reps" }}",
                        style = MaterialTheme.typography.bodySmall)
                    OutlinedTextField(value = editQuantity,
                        onValueChange = { editQuantity = it.filter(Char::isDigit) },
                        label = { Text("Cantidad registrada") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = editWeight,
                        onValueChange = { editWeight = it.filter { ch -> ch.isDigit() || ch == '.' } },
                        label = { Text("Peso registrado (opcional)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(onClick = {
                            onReviseMovement(record.id, editQuantity.toInt(), editWeight.toDoubleOrNull())
                        }, enabled = !busy && editQuantity.toIntOrNull() != null &&
                            (editWeight.isBlank() || editWeight.toDoubleOrNull()?.let {
                                it.isFinite() && it >= 0
                            } == true)) { Text("Corregir") }
                        TextButton(onClick = { onDeleteMovement(record.id) }, enabled = !busy) {
                            Text("Eliminar")
                        }
                    }
                }
                Button(onClick = onCompleteBlock, enabled = !busy && wod.recorded.isNotEmpty(),
                    modifier = Modifier.fillMaxWidth()) { Text("Terminar bloque y continuar") }
            } else if (scoreIsTime) {
                Text("Tiempo total realizado", style = MaterialTheme.typography.titleSmall)
                if (elapsedClock > 0) {
                    TextButton(onClick = {
                        minutes = (elapsedClock / 60).toString()
                        seconds = (elapsedClock % 60).toString().padStart(2, '0')
                        onTimerAction("pause")
                    }, enabled = !busy) { Text("Usar tiempo del cronómetro") }
                }
                OutlinedTextField(
                    value = minutes,
                    onValueChange = { minutes = it.filter(Char::isDigit) },
                    label = { Text("Minutos") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = seconds,
                    onValueChange = { seconds = it.filter(Char::isDigit) },
                    label = { Text("Segundos (0–59)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                if (wod.expectsRounds) {
                    OutlinedTextField(
                        value = rounds,
                        onValueChange = { rounds = it.filter(Char::isDigit) },
                        label = { Text("Rondas completadas") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                OutlinedTextField(
                    value = extraReps,
                    onValueChange = { extraReps = it.filter(Char::isDigit) },
                    label = { Text(if (wod.expectsRounds) "Repeticiones adicionales" else "Repeticiones totales") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (!perMovement) Button(
                enabled = !busy && valid,
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    if (scoreIsTime) onSave(null, null, elapsed)
                    else onSave(rounds.toIntOrNull(), extraReps.toIntOrNull(), null)
                }
            ) { Text("Guardar resultado y continuar") }
            TextButton(onClick = onFinish, enabled = !busy) {
                Text("Finalizar sin añadir otro resultado")
            }
            // Descartar sin guardar (endActiveSession(save: false) iOS).
            var confirmDiscard by remember(active.id) { mutableStateOf(false) }
            TextButton(onClick = { confirmDiscard = true }, enabled = !busy) {
                Text("Descartar entreno", color = MaterialTheme.colorScheme.error)
            }
            if (confirmDiscard) {
                AlertDialog(
                    onDismissRequest = { confirmDiscard = false },
                    confirmButton = {
                        TextButton(onClick = { confirmDiscard = false; onDiscard() }) {
                            Text("Descartar", color = MaterialTheme.colorScheme.error)
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { confirmDiscard = false }) { Text("Cancelar") }
                    },
                    title = { Text("Descartar entreno en curso") },
                    text = { Text("Se borra la sesión en curso sin guardarla. No aparecerá en el historial.") }
                )
            }
        }
    }
}

@Composable
internal fun ScheduledRoutineCard(
    routine: RoutineEntry,
    busy: Boolean,
    canStart: Boolean,
    onStart: (String) -> Unit,
    onEdit: (String, String, RoutineSchedule) -> Unit = { _, _, _ -> },
    onDelete: (String) -> Unit = {},
    onEditContent: (String) -> Unit = {},
    onSetProgression: (String, String) -> Unit = { _, _ -> },
    onSetFavorite: (String, Boolean) -> Unit = { _, _ -> }
) {
    var editing by remember(routine.id) { mutableStateOf(false) }
    var confirmingDelete by remember(routine.id) { mutableStateOf(false) }
    var editTitle by remember(routine.id) { mutableStateOf(routine.title) }
    var editPlanning by remember(routine.id) {
        mutableStateOf(if (routine.scheduledDate != null) "date"
            else if (routine.weekday != null) "weekly" else "library")
    }
    var editDate by remember(routine.id) {
        mutableStateOf(routine.scheduledDate?.take(10) ?: LocalDate.now().toString())
    }
    var editWeekday by remember(routine.id) { mutableStateOf(routine.weekday ?: 1) }
    var editClock by remember(routine.id) {
        mutableStateOf(routine.timeMinutes?.let { "%02d:%02d".format(it / 60, it % 60) } ?: "")
    }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Row(modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically) {
                Text(routine.title, style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f))
                // Estrella de favorita (paridad FavoritesHub iOS).
                IconButton(onClick = {
                    onSetFavorite(routine.id, !routine.isFavorite)
                }, enabled = !busy) {
                    Icon(
                        if (routine.isFavorite) Icons.Default.Star
                        else Icons.Default.StarBorder,
                        contentDescription = if (routine.isFavorite)
                            "Quitar de favoritas" else "Marcar como favorita",
                        tint = if (routine.isFavorite) brandGreen
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            val label = if (routine.scheduledDate != null) routine.scheduledDate else
                routine.weekday?.let { day ->
                    listOf("Lunes", "Martes", "Miércoles", "Jueves", "Viernes",
                        "Sábado", "Domingo").getOrNull(day - 1)
                } ?: "Sin fecha"
            val hour = routine.timeMinutes?.let { "%02d:%02d".format(it / 60, it % 60) }
            Text(label + (hour?.let { " · $it" } ?: ""),
                style = MaterialTheme.typography.bodyMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()) {
                Text("Progresión:", style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.align(androidx.compose.ui.Alignment.CenterVertically))
                androidx.compose.foundation.layout.Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.horizontalScroll(
                        androidx.compose.foundation.rememberScrollState())) {
                    dev.repera.domain.ProgressionPolicy.entries.forEach { policy ->
                        FilterChip(
                            selected = routine.progression == policy.wire,
                            onClick = { onSetProgression(routine.id, policy.wire) },
                            label = { Text(policy.displayName,
                                style = MaterialTheme.typography.labelSmall) }
                        )
                    }
                }
            }
            androidx.compose.foundation.layout.FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)) {
                TextButton(
                    onClick = { onStart(routine.id) },
                    enabled = !busy && canStart && routine.supported
                ) { Text(if (routine.supported) "Empezar" else "Formato pendiente") }
                TextButton(onClick = { onEditContent(routine.id) },
                    enabled = !busy) { Text("Contenido") }
                TextButton(onClick = {
                    editing = !editing
                    confirmingDelete = false
                }, enabled = !busy) { Text(if (editing) "Cerrar" else "Editar") }
                TextButton(onClick = { confirmingDelete = !confirmingDelete },
                    enabled = !busy) { Text("Borrar") }
            }
            if (confirmingDelete) {
                Text("¿Borrar la rutina? Los entrenos ya registrados se conservan.",
                    style = MaterialTheme.typography.bodyMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = {
                        confirmingDelete = false
                        onDelete(routine.id)
                    }, enabled = !busy) { Text("Confirmar borrado") }
                    TextButton(onClick = { confirmingDelete = false }) { Text("Cancelar") }
                }
            }
            if (editing) {
                OutlinedTextField(
                    value = editTitle, onValueChange = { editTitle = it },
                    label = { Text("Nombre") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth())
                Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf("library" to "Sin fecha", "date" to "Día concreto",
                        "weekly" to "Semanal").forEach { option ->
                        FilterChip(selected = editPlanning == option.first,
                            onClick = { editPlanning = option.first },
                            label = { Text(option.second) })
                    }
                }
                if (editPlanning == "date") {
                    // DatePicker de Apple en lugar de texto libre.
                    val ctx = androidx.compose.ui.platform.LocalContext.current
                    val cur = runCatching { LocalDate.parse(editDate) }.getOrDefault(LocalDate.now())
                    TextButton(modifier = Modifier.testTag("routine_edit_date"), onClick = {
                        android.app.DatePickerDialog(ctx, { _, y, m, d -> editDate = LocalDate.of(y, m + 1, d).toString() },
                            cur.year, cur.monthValue - 1, cur.dayOfMonth).show()
                    }) { Text("Fecha: " + cur.toString()) }
                }
                if (editPlanning == "weekly") Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    listOf("L", "M", "X", "J", "V", "S", "D").forEachIndexed { index, day ->
                        FilterChip(selected = editWeekday == index + 1,
                            onClick = { editWeekday = index + 1 },
                            label = { Text(day) })
                    }
                }
                if (editPlanning != "library") {
                    // "Hora programada": interruptor + selector de hora (18:00 por defecto), como scheduledTimeControls.
                    val ctx2 = androidx.compose.ui.platform.LocalContext.current
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        androidx.compose.material3.Switch(checked = editClock.isNotBlank(),
                            modifier = Modifier.testTag("routine_edit_time_switch"),
                            onCheckedChange = { on -> editClock = if (on) "18:00" else "" })
                        Text("  Hora programada")
                        if (editClock.isNotBlank()) {
                            val t = runCatching { LocalTime.parse(editClock) }.getOrDefault(LocalTime.of(18, 0))
                            TextButton(modifier = Modifier.testTag("routine_edit_time"), onClick = {
                                android.app.TimePickerDialog(ctx2, { _, h, mi -> editClock = "%02d:%02d".format(h, mi) },
                                    t.hour, t.minute, true).show()
                            }) { Text(editClock) }
                        }
                    }
                }
                val validDate = editPlanning != "date" ||
                    runCatching { LocalDate.parse(editDate) }.isSuccess
                val parsedClock = if (editClock.isBlank()) null else
                    runCatching { LocalTime.parse(editClock) }.getOrNull()
                val validClock = editPlanning == "library" || editClock.isBlank() ||
                    parsedClock != null
                TextButton(
                    enabled = !busy && editTitle.trim().isNotEmpty() && validDate && validClock,
                    onClick = {
                        onEdit(routine.id, editTitle, RoutineSchedule(
                            scheduledDate = if (editPlanning == "date") editDate else null,
                            weekday = if (editPlanning == "weekly") editWeekday else null,
                            timeMinutes = if (editPlanning == "library") null else
                                parsedClock?.let { it.hour * 60 + it.minute }
                        ))
                        editing = false
                    }) { Text("Guardar cambios") }
            }
        }
    }
}

private data class RoutineDraftRow(
    val id: String, val name: String, val sets: Int, val quantity: Int,
    val weightKg: Double?, val restSeconds: Int? = null
)

/** Material editor for the Swift Routine/RoutineBlock subset actually supported on Android. */
@Composable
internal fun RoutineCreatorCard(
    exercises: List<ExerciseEntry>,
    aliases: Map<String, String>,
    busy: Boolean,
    onSave: (String, String, List<RoutineDraftEntry>, Int, Int,
        RoutineSchedule, Int, Int, Int, List<Int>?) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var kind by remember { mutableStateOf("strength") }
    var search by remember { mutableStateOf("") }
    var reps by remember { mutableStateOf("10") }
    var sets by remember { mutableStateOf("3") }
    var weight by remember { mutableStateOf("") }
    var entryRest by remember { mutableStateOf("") }
    var cap by remember { mutableStateOf("12") }
    var rounds by remember { mutableStateOf("1") }
    var interval by remember { mutableStateOf("60") }
    var workSeconds by remember { mutableStateOf("20") }
    var restSeconds by remember { mutableStateOf("10") }
    var ladderText by remember { mutableStateOf("21-15-9") }
    var planning by remember { mutableStateOf("library") }
    var specificDate by remember { mutableStateOf(LocalDate.now().toString()) }
    var weekday by remember { mutableStateOf(1) }
    var clockTime by remember { mutableStateOf("") }
    val chosen = remember { mutableStateListOf<RoutineDraftRow>() }
    val weightValue = weight.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val quantity = reps.toIntOrNull()
    val setCount = sets.toIntOrNull()
    val validEntryRest = entryRest.isBlank() ||
        entryRest.toIntOrNull()?.let { it in 0..600 } == true
    val validNumeric = quantity != null && quantity in 1..10000 && validEntryRest &&
        (kind != "strength" || (setCount != null && setCount in 1..30 &&
            (weight.isBlank() || (weightValue != null &&
                weightValue.isFinite() && weightValue >= 0))))
    val candidates = remember(exercises, search, kind, chosen.size) {
        exercises.asSequence()
            .filter { kind != "strength" || it.supportsBasicInput }
            .filter { candidate -> chosen.none { it.id == candidate.id } }
            .map { entry -> entry to ExerciseAliasSearch.score(search, entry.name, aliases, entry.disciplineTags.joinToString(" "), entry.searchAliases) }
            .filter { it.second >= 0 }
            .sortedWith(compareByDescending<Pair<ExerciseEntry, Int>> { it.second }
                .thenBy { it.first.name })
            .take(8).map { it.first }.toList()
    }
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("Nueva rutina", style = MaterialTheme.typography.titleLarge)
            OutlinedTextField(
                value = title, onValueChange = { title = it },
                label = { Text("Nombre de la rutina") },
                singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("strength" to "Fuerza", "amrap" to "AMRAP",
                    "forTime" to "For Time", "emom" to "EMOM", "tabata" to "Tabata",
                    "circuit" to "Circuito", "chipper" to "Chipper", "afap" to "AFAP",
                    "ladder" to "Ladder", "deathBy" to "Muerte por",
                    "partner" to "Partner", "roundsForQuality" to "RFQ",
                    "maxEffort" to "Max effort").forEach { option ->
                        FilterChip(
                            selected = kind == option.first,
                            onClick = {
                                kind = option.first
                                chosen.clear()
                                if (option.first == "deathBy") cap = "30"
                            },
                            label = { Text(option.second) }
                        )
                    }
            }
            if (kind != "strength") {
                if (kind in setOf("amrap", "forTime", "chipper", "ladder", "deathBy",
                    "partner", "maxEffort")) {
                    OutlinedTextField(
                        value = cap, onValueChange = { cap = it.filter(Char::isDigit) },
                        label = { Text("Límite (minutos)") },
                        modifier = Modifier.fillMaxWidth(), singleLine = true
                    )
                }
                if (kind in setOf("forTime", "emom", "tabata", "circuit", "partner",
                    "roundsForQuality")) {
                    OutlinedTextField(
                        value = rounds,
                        onValueChange = { rounds = it.filter(Char::isDigit) },
                        label = { Text(if (kind == "emom") "Número de intervalos" else "Número de rondas") },
                        modifier = Modifier.fillMaxWidth(), singleLine = true
                    )
                }
                if (kind == "ladder") {
                    OutlinedTextField(
                        value = ladderText, onValueChange = { ladderText = it.take(60) },
                        label = { Text("Escalera de reps (p. ej. 21-15-9)") },
                        modifier = Modifier.fillMaxWidth(), singleLine = true
                    )
                }
                if (kind in setOf("emom", "circuit", "deathBy")) {
                    OutlinedTextField(value = interval,
                        onValueChange = { interval = it.filter(Char::isDigit) },
                        label = { Text(when (kind) {
                            "circuit" -> "Duración por estación (segundos)"
                            "deathBy" -> "Cada (segundos, 60 = EMOM)"
                            else -> "Duración del intervalo (segundos)"
                        }) },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                }
                if (kind == "tabata") {
                    OutlinedTextField(value = workSeconds,
                        onValueChange = { workSeconds = it.filter(Char::isDigit) },
                        label = { Text("Trabajo (segundos)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                }
                if (kind in setOf("tabata", "circuit")) {
                    OutlinedTextField(value = restSeconds,
                        onValueChange = { restSeconds = it.filter(Char::isDigit) },
                        label = { Text(if (kind == "tabata") "Descanso por intervalo (segundos)"
                            else "Descanso entre rondas (segundos)") },
                        singleLine = true, modifier = Modifier.fillMaxWidth())
                }
            }
            OutlinedTextField(
                value = reps, onValueChange = { reps = it.filter(Char::isDigit) },
                label = { Text("Repeticiones por ejercicio") },
                modifier = Modifier.fillMaxWidth(), singleLine = true
            )
            if (kind == "strength") {
                OutlinedTextField(
                    value = sets, onValueChange = { sets = it.filter(Char::isDigit) },
                    label = { Text("Series por ejercicio") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                OutlinedTextField(
                    value = entryRest,
                    onValueChange = { entryRest = it.filter(Char::isDigit) },
                    label = { Text("Descanso opcional (segundos)") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                OutlinedTextField(
                    value = weight, onValueChange = { weight = it },
                    label = { Text("Peso prescrito opcional (kg)") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
            }
            Text("Programación", style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("library" to "Sin fecha", "date" to "Día concreto", "weekly" to "Semanal")
                    .forEach { option ->
                        FilterChip(selected = planning == option.first,
                            onClick = { planning = option.first },
                            label = { Text(option.second) })
                    }
            }
            if (planning == "date") {
                OutlinedTextField(
                    value = specificDate,
                    onValueChange = { specificDate = it.take(10) },
                    label = { Text("Fecha (AAAA-MM-DD)") },
                    singleLine = true, modifier = Modifier.fillMaxWidth()
                )
            }
            if (planning == "weekly") {
                Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    listOf("L", "M", "X", "J", "V", "S", "D").forEachIndexed { index, label ->
                        FilterChip(selected = weekday == index + 1,
                            onClick = { weekday = index + 1 },
                            label = { Text(label) })
                    }
                }
            }
            if (planning != "library") {
                OutlinedTextField(value = clockTime,
                    onValueChange = { clockTime = it.take(5) },
                    label = { Text("Hora opcional (HH:mm)") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true)
            }
            Text("Ejercicios de la rutina", style = MaterialTheme.typography.titleMedium)
            chosen.forEach { draft ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(draft.name + " · " +
                        (if (kind == "strength") "${draft.sets}×" else "") +
                        "${draft.quantity} reps" +
                        (draft.restSeconds?.let { " · ${it}s descanso" } ?: ""))
                    TextButton(onClick = { chosen.remove(draft) }, enabled = !busy) {
                        Text("Quitar")
                    }
                }
            }
            OutlinedTextField(
                value = search, onValueChange = { search = it },
                label = { Text("Buscar para añadir") },
                modifier = Modifier.fillMaxWidth(), singleLine = true
            )
            candidates.forEach { candidate ->
                TextButton(
                    enabled = !busy && validNumeric,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = {
                        if (quantity != null) {
                            chosen.add(RoutineDraftRow(
                                candidate.id,
                                candidate.name,
                                if (kind == "strength") setCount ?: 3 else 1,
                                quantity,
                                if (kind == "strength" && candidate.allowsWeight) weightValue else null,
                                restSeconds = if (kind == "strength")
                                    entryRest.toIntOrNull()?.takeIf { it in 0..600 } else null
                            ))
                        }
                    }
                ) { Text("+ " + candidate.name) }
            }
            val validDate = planning != "date" || runCatching {
                LocalDate.parse(specificDate)
            }.isSuccess
            val parsedClock = if (clockTime.isBlank()) null else
                runCatching { LocalTime.parse(clockTime) }.getOrNull()
            val validClock = planning == "library" || clockTime.isBlank() || parsedClock != null
            val ladderScheme = if (kind != "ladder") null else
                ladderText.split('-', '·', ',', ' ', '/').mapNotNull { it.trim().toIntOrNull() }
            val validLadder = kind != "ladder" ||
                (ladderScheme != null && ladderScheme.size in 2..12 &&
                    ladderScheme.all { it in 1..1000 })
            val validCap = kind in setOf("afap", "roundsForQuality", "emom", "tabata",
                "circuit") ||
                cap.toIntOrNull()?.let { it in 1..180 } == true
            val validRounds = kind !in setOf("forTime", "emom", "tabata", "circuit",
                "partner", "roundsForQuality") ||
                rounds.toIntOrNull()?.let { it in 1..100 } == true
            val validIntervals = (kind !in setOf("emom", "circuit", "deathBy") ||
                interval.toIntOrNull()?.let { it in 15..600 } == true) &&
                (kind != "tabata" ||
                    (workSeconds.toIntOrNull()?.let { it in 5..600 } == true &&
                    restSeconds.toIntOrNull()?.let { it in 0..600 } == true &&
                    (workSeconds.toIntOrNull() ?: 601) + (restSeconds.toIntOrNull() ?: 601) <= 600)) &&
                (kind != "circuit" ||
                    restSeconds.toIntOrNull()?.let { it in 0..600 } == true)
            Button(
                enabled = !busy && title.trim().isNotEmpty() &&
                    chosen.isNotEmpty() &&
                    (kind == "strength" || (validCap && validRounds && validIntervals &&
                        validLadder)) &&
                    validDate && validClock,
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    val entries = chosen.map {
                        RoutineDraftEntry(it.id, it.quantity, it.sets, it.weightKg,
                            restSeconds = it.restSeconds)
                    }
                    onSave(title, kind, entries, cap.toIntOrNull() ?: 12,
                        rounds.toIntOrNull() ?: 1,
                        RoutineSchedule(
                            scheduledDate = if (planning == "date") specificDate else null,
                            weekday = if (planning == "weekly") weekday else null,
                            timeMinutes = if (planning == "library") null else parsedClock?.let {
                                it.hour * 60 + it.minute
                            }
                        ),
                        interval.toIntOrNull() ?: 60, workSeconds.toIntOrNull() ?: 20,
                        restSeconds.toIntOrNull() ?: 10, ladderScheme)
                }
            ) { Text("Guardar rutina") }
        }
    }
}

/** Drill-down stays inside the workout, preserving the back-to-summary behaviour. */
/** Accessible Material 3 bars; absent sessions remain zero, not fabricated activity. */
@Composable
internal fun WeekTrainingBars(totals: List<Int>, monday:Boolean=true) {
    if (totals.size != 7) return
    val labels = if(monday) listOf("L", "M", "X", "J", "V", "S", "D") else listOf("D","L","M","X","J","V","S")
    val scale = (totals.maxOrNull() ?: 0).coerceAtLeast(1).toFloat()
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        totals.forEachIndexed { index, count ->
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(labels[index], style = MaterialTheme.typography.labelMedium)
                LinearProgressIndicator(
                    progress = { count.toFloat() / scale },
                    modifier = Modifier.weight(1f),
                    color = brandGreen
                )
                Text(count.toString(), style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}

/** Seven-day Material 3 date picker, saved across configuration changes. */
// Locale española explícita: todos los textos de la app están en español
// fijo; la fecha no puede salir en el idioma del dispositivo (Oct 24, 2026).
internal val reperaDayFormatter: java.time.format.DateTimeFormatter =
    java.time.format.DateTimeFormatter
        .ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)
        .withLocale(java.util.Locale("es", "ES"))

@Composable
private fun WeekDayCell(day: LocalDate, label: String, isSelected: Boolean, hasCompleted: Boolean, modifier: Modifier, onSelect: (LocalDate) -> Unit) {
    // Celda propia (no FilterChip): el padding interno del chip
    // envolvía los números de dos cifras ("1/9" en vez de 19).
    // Letra 11sp sobre número 17sp como calendarDayColumn (iOS).
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
            .clip(androidx.compose.foundation.shape.RoundedCornerShape(12.dp))
            .background(
                if (isSelected) brandGreen.copy(alpha = 0.18f)
                else androidx.compose.ui.graphics.Color.Transparent
            )
            .clickable { onSelect(day) }
            .semantics(mergeDescendants = true) {
                if (hasCompleted) stateDescription = "Entrenamiento completado"
            }
            .padding(vertical = 8.dp)
    ) {
        Text(label, fontSize = 11.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1, softWrap = false)
        Text("${day.dayOfMonth}", fontSize = 17.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            maxLines = 1, softWrap = false)
        // Apple HomeView (6ac9f0e4/b75ecbcb): punto SOLO si hay entreno finalizado (Repera o Salud);
        // seleccionar no cambia su visibilidad y el hueco se reserva siempre.
        Box(Modifier.padding(top = 2.dp).size(4.dp).clip(androidx.compose.foundation.shape.CircleShape)
            .background(if (hasCompleted) brandGreen else androidx.compose.ui.graphics.Color.Transparent))
    }
}

/** Geometria de la tira semanal, calcada de HomeView.weekSelectorCard en el
 *  corte Apple 0a640da8 (las formulas anteriores de ancho fijo de 7 dias,
 *  centrado y padding exterior fueron retiradas por Apple: comentario
 *  "SOLO los días son edge-to-edge..." en weekSelectorCard). */
internal object WeekCalendarGeometry {
    const val PREFERRED_SIDE_DP = 64f  // weekCarouselHeight 72 - 8
    const val GAP_DP = 4f
    const val EXTRA_DP = 12f
    const val EXPANDED_MIN_WIDTH_DP = 620f
    fun isExpanded(widthDp: Float): Boolean = widthDp >= EXPANDED_MIN_WIDTH_DP
    fun visibleDays(widthDp: Float): Int =
        if (!isExpanded(widthDp)) 7
        else maxOf(7, ((widthDp + GAP_DP) / (PREFERRED_SIDE_DP + EXTRA_DP)).toInt())
    fun sideDp(widthDp: Float): Float {
        val n = visibleDays(widthDp)
        return minOf(PREFERRED_SIDE_DP, maxOf(1f, (widthDp - GAP_DP * (n - 1)) / n))
    }
    fun spacingDp(widthDp: Float): Float {
        val n = visibleDays(widthDp)
        return if (isExpanded(widthDp) && n > 1)
            maxOf(GAP_DP, (widthDp - PREFERRED_SIDE_DP * n) / (n - 1))
        else GAP_DP
    }
}

@Composable
internal fun WeekCalendarStrip(selected: LocalDate, monday:Boolean=true, completedDays:Set<LocalDate> = emptySet(), returnToDay: LocalDate? = null, onSelect: (LocalDate) -> Unit) {
    val weekStart = dev.repera.domain.StatsEngine.startOfWeek(selected,monday)
    Card(modifier = Modifier.fillMaxWidth().testTag("week_calendar_card")) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("${weekStart.dayOfMonth}/${weekStart.monthValue} – " +
                "${weekStart.plusDays(6).dayOfMonth}/${weekStart.plusDays(6).monthValue}",
                style = MaterialTheme.typography.titleSmall,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(top = 12.dp).let { m ->
                    // Apple weekSelector: tocar la etiqueta vuelve a la semana actual.
                    if (returnToDay != null) m.clickable(onClickLabel = "Volver a la semana actual") { onSelect(returnToDay) } else m
                })
            val days = if(monday) listOf("L", "M", "X", "J", "V", "S", "D") else listOf("D","L","M","X","J","V","S")
            androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth()) {
                // Carrusel horizontal unico, como el corte Apple (0a640da8
                // HomeView.weekSelectorCard): compacto = 7 dias que llenan el
                // ancho; expandido (>=620) = mas de 7 dias edge-to-edge.
                // El scroll es la navegacion entre semanas (sin botones).
                val expanded = WeekCalendarGeometry.isExpanded(maxWidth.value)
                val spacing = WeekCalendarGeometry.spacingDp(maxWidth.value).dp
                val side = WeekCalendarGeometry.sideDp(maxWidth.value).dp
                val scrollState = androidx.compose.foundation.rememberScrollState()
                // Anclar el scroll para que la semana seleccionada quede
                // visible (la ventana empieza 7 dias antes de weekStart).
                val density = androidx.compose.ui.platform.LocalDensity.current
                LaunchedEffect(weekStart, maxWidth) {
                    val targetPx = with(density) { ((side + spacing) * 7).toPx() }.toInt()
                    scrollState.scrollTo(targetPx)
                }
                // Solo los dias van edge-to-edge (comentario Apple en el
                // corte); la etiqueta conserva margen. Padding inferior para
                // que el borde de la tarjeta no corte las celdas.
                Row(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp)
                        .horizontalScroll(scrollState)
                        .testTag(if (expanded) "week_strip_expanded" else "week_strip_compact"),
                    horizontalArrangement = Arrangement.spacedBy(spacing)) {
                    for (offset in -7..13) {
                        val day = weekStart.plusDays(offset.toLong())
                        val label = days[(day.dayOfWeek.value - (if(monday) 1 else 0) + 7) % 7]
                        // Ancho fijo en ambos modos (weight no aplica dentro
                        // de scroll): en compacto side=(w-24)/7 llena justo.
                        WeekDayCell(day, label, day == selected, day in completedDays,
                            Modifier.width(side), onSelect)
                    }
                }
            }
        }
    }
}

@Composable
internal fun WorkoutHistoryCard(
    workout: WorkoutHistoryEntry,
    busy: Boolean = false,
    onReviseFinishedSet: (String, String, String, Int, Double?, Int?) -> Unit =
        { _, _, _, _, _, _ -> },
    onDeleteFinishedSet: (String, String, String) -> Unit = { _, _, _ -> },
    onDeleteWorkout: (String) -> Unit = {},
    onOpenExerciseFromSession: (String, String, String) -> Unit = { _, _, _ -> },
    accountId: String = "",
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    onUpdateFinishedWorkout: (String, WorkoutRepository.FinishedWorkoutEdit) -> Unit = { _, _ -> },
    /** Serie de FC de la sesión (epoch ms → lpm) desde Salud; vacía sin
     *  permisos o sin datos (la sección solo se pinta con ≥2 muestras). */
    heartSeriesProvider: suspend (String) -> List<Pair<Long, Int>> = { emptyList() }
) {
    var expanded by remember(workout.id) { mutableStateOf(false) }
    var selectedMovement by remember(workout.id) { mutableStateOf<Int?>(null) }
    var editingSetId by remember(workout.id) { mutableStateOf<String?>(null) }
    var editQuantity by remember(workout.id) { mutableStateOf("") }
    var editWeight by remember(workout.id) { mutableStateOf("") }
    var editDuration by remember(workout.id) { mutableStateOf("") }
    // iOS: borrar registro completo solo tras confirmación explícita
    // (OGConfirmSheet «¿Eliminar registro?»); nunca directo.
    var pendingDelete by remember(workout.id) { mutableStateOf(false) }
    if (pendingDelete) {
        AlertDialog(
            onDismissRequest = { pendingDelete = false },
            title = { Text("¿Eliminar registro?") },
            text = { Text("Se borrará «" + workout.title + "». No se puede deshacer.") },
            confirmButton = {
                TextButton(onClick = {
                    pendingDelete = false
                    onDeleteWorkout(workout.id)
                }, enabled = !busy) { Text("Eliminar") }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = false }) { Text("Cancelar") }
            }
        )
    }
    // Gesto deslizar-para-revelar (paridad RegisterSwipeRevealCard iOS, math
    // portada en SwipeRevealMath): arrastrar a la izquierda descubre la
    // acción de borrado; soltar más allá del 45% la deja abierta. El icono de
    // papelera visible permanece como vía accesible equivalente.
    val revealWidthPx = with(androidx.compose.ui.platform.LocalDensity.current) {
        96.dp.toPx()
    }
    var swipeOffset by remember(workout.id) { mutableStateOf(0f) }
    Box(modifier = Modifier.fillMaxWidth()) {
        if (swipeOffset < 0f) {
            TextButton(
                onClick = { swipeOffset = 0f; pendingDelete = true },
                enabled = !busy,
                modifier = Modifier.align(Alignment.CenterEnd).width(96.dp)
                    .fillMaxHeight()
                    .background(MaterialTheme.colorScheme.errorContainer)
            ) {
                Text("Eliminar", color = MaterialTheme.colorScheme.onErrorContainer,
                    style = MaterialTheme.typography.labelLarge)
            }
        }
        Card(modifier = Modifier.fillMaxWidth().animateContentSize()
            .offset { androidx.compose.ui.unit.IntOffset(swipeOffset.toInt(), 0) }
            .pointerInput(workout.id, busy) {
                if (busy) return@pointerInput
                detectDragGestures(
                    onDrag = { change, dragAmount ->
                        if (kotlin.math.abs(dragAmount.x) >
                            kotlin.math.abs(dragAmount.y)) {
                            swipeOffset =
                                dev.repera.domain.SwipeRevealMath.clampedOffset(
                                    start = swipeOffset,
                                    translation = dragAmount.x,
                                    revealWidth = revealWidthPx)
                            change.consume()
                        }
                    },
                    onDragEnd = {
                        swipeOffset = if (dev.repera.domain.SwipeRevealMath
                                .shouldOpen(projected = swipeOffset,
                                    current = swipeOffset,
                                    revealWidth = revealWidthPx))
                            -revealWidthPx else 0f
                    }
                )
            }) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            Row(modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically) {
                Text(workout.title, style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f))
                IconButton(onClick = { pendingDelete = true }, enabled = !busy) {
                    Icon(Icons.Default.Delete, contentDescription = "Eliminar registro")
                }
            }
            if (workout.startedAt.isNotBlank()) {
                Text(workout.startedAt, style = MaterialTheme.typography.labelMedium)
            }
            workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.let { sport ->
                Text(sport.title, style = MaterialTheme.typography.labelLarge)
                val summary = buildList {
                    workout.activeDurationSeconds?.let { add(dev.repera.domain.LiveSportHistory.formatDuration(it)) }
                    workout.recordedDistanceMeters?.takeIf { it > 0 }?.let { add(dev.repera.domain.ReperaNumberFormat.decimal(it / 1000)+" km") }
                }
                if (summary.isNotEmpty()) Text(summary.joinToString(" · "),style=MaterialTheme.typography.bodyMedium)
            }
            workout.results.forEach { result ->
                Text(result, style = MaterialTheme.typography.titleSmall)
            }
            if (!expanded) {
                TextButton(onClick = { expanded = true }) { Text(if (workout.liveSportID != null) "Ver actividad" else "Ver ejercicios y resultados") }
            } else if (selectedMovement != null) {
                val index = selectedMovement!!
                val exercise = workout.movements.getOrNull(index)
                TextButton(onClick = { selectedMovement = null }) {
                    Text("← Volver al resumen")
                }
                if (exercise != null) {
                    // Abrir la ficha con contexto de sesión (tarjeta «Esta
                    // sesión», paridad iOS al tocar un movimiento del registro).
                    // Apple 49de3076: snapshots antiguos BTt/T2B se muestran con
                    // el nombre oficial (alias inequivocos, nunca nombres parecidos).
                    Text(dev.repera.domain.WODHistoryPresentation.officialName(exercise.name) ?: exercise.name,
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.clickable(enabled = !busy) {
                            if (exercise.catalogExerciseId.isNotBlank())
                                onOpenExerciseFromSession(exercise.catalogExerciseId,
                                    workout.id, exercise.entryId)
                        })
                    if (exercise.registered.isEmpty()) {
                        Text(if (exercise.wod && workout.results.isNotEmpty())
                            "Resultado registrado para todo el bloque WOD"
                            else "Este ejercicio no contiene series confirmadas")
                    } else {
                        exercise.registered.forEachIndexed { n, line ->
                            Text("Serie ${n + 1} · $line")
                        }
                    }
                    if (exercise.editableSets.isNotEmpty()) {
                        Text("Corregir series registradas",
                            style = MaterialTheme.typography.titleSmall)
                        exercise.editableSets.forEachIndexed { n, set ->
                            if (editingSetId == set.setId) {
                                OutlinedTextField(
                                    value = editQuantity,
                                    onValueChange = { editQuantity = it.filter(Char::isDigit) },
                                    label = { Text("Cantidad (reps / cal / m)") },
                                    singleLine = true, modifier = Modifier.fillMaxWidth())
                                OutlinedTextField(
                                    value = editWeight,
                                    onValueChange = { editWeight = it.take(8) },
                                    label = { Text("Peso kg (vacío = sin peso)") },
                                    singleLine = true, modifier = Modifier.fillMaxWidth())
                                OutlinedTextField(
                                    value = editDuration,
                                    onValueChange = { editDuration = it.filter(Char::isDigit) },
                                    label = { Text("Duración s (opcional)") },
                                    singleLine = true, modifier = Modifier.fillMaxWidth())
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    val quantityValue = editQuantity.toIntOrNull()
                                    TextButton(
                                        enabled = !busy && quantityValue != null &&
                                            quantityValue >= 0 &&
                                            (editWeight.isBlank() ||
                                                dev.repera.domain.ReperaNumberFormat.parse(editWeight) != null),
                                        onClick = {
                                            onReviseFinishedSet(
                                                workout.id, exercise.entryId, set.setId,
                                                quantityValue ?: 0,
                                                editWeight.takeIf { it.isNotBlank() }
                                                    ?.let { dev.repera.domain.ReperaNumberFormat.parse(it) },
                                                editDuration.toIntOrNull())
                                            editingSetId = null
                                        }) { Text("Guardar") }
                                    TextButton(onClick = { editingSetId = null }) {
                                        Text("Cancelar")
                                    }
                                }
                            } else {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text("Serie ${n + 1} · ${set.line}",
                                        style = MaterialTheme.typography.bodyMedium)
                                    Row {
                                        TextButton(enabled = !busy, onClick = {
                                            editingSetId = set.setId
                                            editQuantity = ""
                                            editWeight = ""
                                            editDuration = ""
                                        }) { Text("Editar") }
                                        TextButton(enabled = !busy, onClick = {
                                            onDeleteFinishedSet(
                                                workout.id, exercise.entryId, set.setId)
                                        }) { Text("Borrar") }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Valoración verificable de la sesión (SessionReviewCard iOS en
                // Historial; en Android el detalle vive en la tarjeta expandida).
                workout.review?.let { SessionReviewCard(it) }
                // Curva de pulso de la sesión (extras.heartRateSeries iOS):
                // solo se muestra con datos de Salud (≥2 muestras).
                SessionMovementSection(workout.id)
                SessionSportMetricRow(workout)
                RouteUnavailableNotice(workout)
                HeartRateCurveSection(workout.id, heartSeriesProvider)
                // Ruta GPS: distancia/desnivel/splits y perfil de altitud
                // (CardioRouteComponents iOS; el análisis es 1:1 en dominio).
                if (workout.routePoints.size >= 2) {
                    CardioRouteSection(workout.routePoints, showComputedSplits = workout.liveKilometerSplitsSeconds.isEmpty(),
                        waterSport = workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.isWaterSport == true)
                }
                val splitHeart by produceState<List<Pair<Long,Int>>>(emptyList(),workout.id,workout.liveKilometerSplitsSeconds) {
                    if (workout.liveKilometerSplitsSeconds.isNotEmpty())
                        value = runCatching { heartSeriesProvider(workout.id) }.getOrDefault(emptyList())
                }
                LiveKilometerSplitsSection(workout.liveKilometerSplitsSeconds,
                    workout.liveSportID?.let(dev.repera.domain.LiveSport::byId)?.displaysSpeed == true,
                    workout.routePoints, splitHeart)
                FinishedWorkoutEditorSection(
                    workout = workout,
                    accountId = accountId,
                    busy = busy,
                    exerciseCatalog = exerciseCatalog,
                    onSave = { onUpdateFinishedWorkout(workout.id, it) })
                workout.movements.forEachIndexed { index, movement ->
                    TextButton(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { selectedMovement = index }
                    ) {
                        Text(movement.name + if (movement.registered.isNotEmpty())
                            " · ${movement.registered.size} series" else
                            if (movement.wod && workout.results.isNotEmpty())
                                " · resultado por bloque" else "")
                    }
                }
                TextButton(onClick = { expanded = false }) {
                    Text("Ocultar detalle")
                }
            }
        }
    }
    }
}

@Composable
internal fun CountCard(title: String, count: Int?, hasOverview: Boolean) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(count?.toString() ?: "—", style = MaterialTheme.typography.headlineLarge)
            if (!hasOverview) Text("No hay datos locales cargados")
        }
    }
}

@Composable
internal fun OverviewEmptyActions(
    overview: StateOverview?,
    busy: Boolean,
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit
) {
    if (overview == null) {
        Button(
            onClick = onInitializeLocal,
            enabled = !busy,
            modifier = Modifier.fillMaxWidth()
        ) { Text("Empezar con catálogo Repera") }
        OutlinedButton(
            onClick = onImportJson,
            enabled = !busy,
            modifier = Modifier.fillMaxWidth()
        ) { Text("Importar historial JSON") }
    }
}

@Composable
internal fun AccountSyncCard(
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit
) {
    Text("Cuenta", style = MaterialTheme.typography.titleMedium)
    // Entrada a Repera Pro desde ajustes (paridad SettingsView iOS,
    // contexto settings). Pro activo muestra enlace de gestión.
    val subscriptions = dev.repera.mobile.monetization.LocalSubscriptions.current
    if (subscriptions != null) {
        if (subscriptions.isPro) {
            val uriHandler = androidx.compose.ui.platform.LocalUriHandler.current
            TextButton(onClick = {
                uriHandler.openUri(dev.repera.mobile.monetization.CommercialConfig.MANAGE_SUBSCRIPTIONS_URL)
            }) { Text("Repera Pro activo · Gestionar") }
        } else {
            TextButton(onClick = {
                subscriptions.presentPaywall(
                    dev.repera.domain.monetization.PaywallContext.SETTINGS,
                    feature = null
                )
            }) { Text("Conocer Repera Pro") }
        }
    }
    if (overview != null) {
        OutlinedButton(onClick = onExportJson, enabled = !busy,
            modifier = Modifier.fillMaxWidth()) {
            Text("Exportar copia JSON")
        }
    }
    TextButton(onClick = onSignOut, enabled = !busy) { Text("Cerrar sesión") }
}

/** Benchmark WOD catalog picker, twin of the iPhone WODCatalogPickerView. */
@Composable
internal fun BenchmarkWodPicker(
    busy: Boolean,
    enabled: Boolean,
    onAdd: (String) -> Unit
) {
    var query by rememberSaveable { mutableStateOf("") }
    val results = remember(query) { dev.repera.domain.CatalogWods.search(query) }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("WODs benchmark", style = MaterialTheme.typography.titleLarge)
            Text("Girls, Heroes y Opens del catálogo Repera, con bandas de puntuación de referencia.",
                style = MaterialTheme.typography.bodySmall)
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                label = { Text("Buscar benchmark") }
            )
            results.take(12).forEach { template ->
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(template.name + " · " + template.formatLabel +
                        (template.typicalLabel?.let { " · $it" } ?: ""),
                        style = MaterialTheme.typography.titleMedium)
                    Text(template.musclesLabel, style = MaterialTheme.typography.labelSmall)
                    Text(template.movements.joinToString(" · ") { move ->
                        val amount = move.reps?.let { "$it reps" }
                            ?: move.distanceMeters?.let { "$it m" }
                            ?: move.calories?.let { "$it cal" } ?: ""
                        (amount + " " + move.name).trim()
                    }, style = MaterialTheme.typography.bodySmall)
                    template.scoreBands?.let { bands ->
                        val elite = bands.eliteMaxSeconds?.let { "élite < %d:%02d".format(it / 60, it % 60) }
                            ?: bands.eliteMinRounds?.let { "élite ≥ ${it.toInt()} rondas" }
                        if (elite != null) Text(elite, style = MaterialTheme.typography.labelSmall)
                    }
                    TextButton(onClick = { onAdd(template.id) },
                        enabled = !busy && enabled) {
                        Text("Añadir a mis entrenamientos")
                    }
                }
            }
            if (results.isEmpty()) Text("Sin benchmarks coincidentes",
                style = MaterialTheme.typography.bodyMedium)
        }
    }
}

/** Resumen y perfil de la ruta GPS de una sesión (CardioRouteComponents iOS).
 *  Distancia/desnivel/splits del dominio; perfil dibujado en Canvas. El mapa
 *  nativo de la ruta es un sub-gap pendiente de componente. */
/** Apple fafe016a WorkoutMapTapTarget: el preview del mapa no recibe gestos;
 *  una superficie tactil independiente CAPTURA todo su rectangulo y abre el
 *  mapa a pantalla completa (interactivo). Generico sobre el contenido del
 *  mapa, como el original. */
@Composable
internal fun RouteMapTapTarget(label: String, modifier: Modifier = Modifier,
    map: @Composable (interactive: Boolean, modifier: Modifier) -> Unit) {
    var fullScreen by rememberSaveable { mutableStateOf(false) }
    Box(modifier) {
        map(false, Modifier.matchParentSize())
        Box(modifier = Modifier
            .matchParentSize()
            .clickable { fullScreen = true }
            .semantics { contentDescription = label })
    }
    if (fullScreen) {
        Dialog(onDismissRequest = { fullScreen = false },
            properties = DialogProperties(usePlatformDefaultWidth = false)) {
            Box(Modifier.fillMaxSize().testTag("fullscreen-route-root")) {
                map(true, Modifier.fillMaxSize().testTag("fullscreen-route-map"))
                // Apple WorkoutMapZoomDestination: cierre explicito arriba a la
                // derecha ("Cerrar mapa"), no solo gesto atras/scrim.
                IconButton(onClick = { fullScreen = false },
                    modifier = Modifier.align(Alignment.TopEnd).padding(top = 10.dp, end = 16.dp)
                        .testTag("fullscreen-route-close")) {
                    Surface(shape=androidx.compose.foundation.shape.CircleShape,
                        color=MaterialTheme.colorScheme.surface,
                        contentColor=MaterialTheme.colorScheme.onSurface) {
                        Icon(Icons.Default.Close, contentDescription = "Cerrar mapa",
                            modifier=Modifier.padding(8.dp))
                    }
                }
            }
        }
    }
}

@Composable
internal fun CardioRouteSection(points: List<dev.repera.domain.WorkoutRoutePoint>, showComputedSplits: Boolean = true, waterSport: Boolean = false) {
    val analysis = remember(points) {
        dev.repera.domain.CardioRouteAnalysis.analyze(points.map {
            dev.repera.domain.CardioRouteAnalysis.Sample(
                epochSeconds = it.recordedAtEpochMs / 1000.0,
                latitude = it.latitude,
                longitude = it.longitude,
                altitudeMeters = it.altitudeMeters
            )
        })
    }
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("Ruta", style = MaterialTheme.typography.titleMedium)
        // Apple fafe016a: preview sin gestos + superficie tactil independiente
        // que abre el recorrido a pantalla completa.
        RouteMapTapTarget(label = "Ampliar recorrido",
            modifier = Modifier.fillMaxWidth().height(180.dp)
                .clip(RoundedCornerShape(10.dp))) { interactive, mapModifier ->
            RouteMapView(points = points, isInteractive = interactive, waterSport = waterSport,
                modifier = mapModifier)
        }
        // Solo los recorridos ya guardados muestran su escala de color (Apple c04c7dd9).
        RouteSpeedLegend(water = waterSport)
        if (points.any { it.isEstimated == true }) {
            // Apple 303453ff: la reconstruccion se rotula, no se presenta como GPS.
            Text("El tramo discontinuo se ha estimado en línea recta tras un cierre inesperado; no es una medición GPS.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text("Distancia", style = MaterialTheme.typography.bodyMedium)
            Text(dev.repera.domain.ReperaNumberFormat.decimal(analysis.distanceMeters / 1000) + " km",
                style = MaterialTheme.typography.bodyMedium)
        }
        if (analysis.ascentMeters > 0 || analysis.descentMeters > 0) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Desnivel", style = MaterialTheme.typography.bodyMedium)
                Text("+%.0f m / −%.0f m".format(analysis.ascentMeters,
                    analysis.descentMeters), style = MaterialTheme.typography.bodyMedium)
            }
        }
        if (analysis.profile.size >= 2) {
            val minAlt = analysis.profile.minOf { it.altitudeMeters }
            val maxAlt = analysis.profile.maxOf { it.altitudeMeters }
            val maxDist = analysis.profile.last().distanceKm
            // Scrub táctil (paridad chartXSelection iOS): durante el arrastre
            // se selecciona el punto más cercano del perfil (regla discontinua
            // + marcador + etiqueta «m · km») y al soltar se limpia, como iOS.
            var selectedDistance by remember { mutableStateOf<Double?>(null) }
            val picked = selectedDistance?.let { sel ->
                analysis.profile.minByOrNull {
                    kotlin.math.abs(it.distanceKm - sel) }
            }
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Perfil del recorrido",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    if (picked != null) "${dev.repera.domain.ReperaNumberFormat.decimal(picked.altitudeMeters, maximumFractionDigits = 0)} m · ${dev.repera.domain.ReperaNumberFormat.decimal(picked.distanceKm)} km"
                    else "↑ ${analysis.ascentMeters.toInt()} m",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (picked != null) MaterialTheme.colorScheme.primary
                        else MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Canvas(modifier = Modifier.fillMaxWidth().height(96.dp)
                .pointerInput(analysis.profile) {
                    detectDragGestures(
                        onDragStart = { start ->
                            val span = maxDist.coerceAtLeast(0.001)
                            selectedDistance = (start.x / size.width.toFloat())
                                .coerceIn(0f, 1f) * span
                        },
                        onDrag = { change, _ ->
                            val span = maxDist.coerceAtLeast(0.001)
                            selectedDistance = (change.position.x /
                                size.width.toFloat()).coerceIn(0f, 1f) * span
                            change.consume()
                        },
                        onDragEnd = { selectedDistance = null },
                        onDragCancel = { selectedDistance = null }
                    )
                }) {
                val spanAlt = (maxAlt - minAlt).coerceAtLeast(1.0)
                val spanDist = maxDist.coerceAtLeast(0.001)
                val path = androidx.compose.ui.graphics.Path()
                analysis.profile.forEachIndexed { i, p ->
                    val x = (p.distanceKm / spanDist).toFloat() * size.width
                    val y = size.height -
                        (((p.altitudeMeters - minAlt) / spanAlt).toFloat() * size.height)
                    if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
                }
                drawPath(path, color = BodyMapPalette.fill(3),
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4f))
                if (picked != null) {
                    val px = (picked.distanceKm / spanDist).toFloat() * size.width
                    val py = size.height -
                        (((picked.altitudeMeters - minAlt) / spanAlt).toFloat() *
                            size.height)
                    // Regla discontinua (iOS RuleMark dash [3,3]).
                    drawLine(
                        color = androidx.compose.ui.graphics.Color(0x73FFFFFF),
                        start = androidx.compose.ui.geometry.Offset(px, 0f),
                        end = androidx.compose.ui.geometry.Offset(px, size.height),
                        strokeWidth = 2f,
                        pathEffect = androidx.compose.ui.graphics.PathEffect
                            .dashPathEffect(floatArrayOf(8f, 8f))
                    )
                    drawCircle(color = BodyMapPalette.fill(3), radius = 9f,
                        center = androidx.compose.ui.geometry.Offset(px, py))
                }
            }
            Text("Altitud ${minAlt.toInt()}–${maxAlt.toInt()} m sobre la distancia · arrastra para inspeccionar",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        if (showComputedSplits && analysis.splits.isNotEmpty()) {
            analysis.splits.forEach { split ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Km ${split.kilometer}", style = MaterialTheme.typography.bodyMedium)
                    val m = (split.paceSecondsPerKm / 60).toInt()
                    val sec = (split.paceSecondsPerKm % 60).toInt()
                    Text("%d:%02d min/km".format(m, sec),
                        style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}

/** Guía de carga (port 1:1 del body de ExerciseLoadGuideCard iOS). */
@Composable
internal fun LoadGuideSection(guide: LoadGuide, onApply: (Double) -> Unit) {
    val last = guide.lastSession
    if (last == null && guide.suggestedKg == null) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth()) {
            Text("↻", style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary)
            Column {
                Text("Sin historial aún", style = MaterialTheme.typography.titleSmall)
                Text("Tras la primera vez verás aquí pesos y una sugerencia para tu RIR.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        return
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.fillMaxWidth()) {
        if (last != null) {
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween) {
                Text("ÚLTIMA VEZ", style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(loadGuideShortDate(last.dateEpochMillis),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            val topId = last.topSet
            last.sets.forEachIndexed { index, set ->
                val isTop = set === topId
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Text("${index + 1}",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isTop) MaterialTheme.colorScheme.onPrimary
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier
                            .size(22.dp)
                            .background(
                                if (isTop) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.surfaceVariant,
                                CircleShape)
                            .wrapContentSize(Alignment.Center))
                    Text(loadGuideSetLine(set),
                        style = if (isTop) MaterialTheme.typography.titleMedium
                            else MaterialTheme.typography.bodyMedium,
                        color = if (isTop) MaterialTheme.colorScheme.onSurface
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.weight(1f))
                    if (isTop) {
                        Text("TOP", style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .background(MaterialTheme.colorScheme.primary
                                    .copy(alpha = 0.15f), RoundedCornerShape(50))
                                .padding(horizontal = 6.dp, vertical = 3.dp))
                    }
                }
            }
        }
        if (guide.suggestedKg != null) {
            if (last != null) HorizontalDivider()
            Text("CARGA SUGERIDA", style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(loadGuideKgLabel(guide.suggestedKg) + " kg",
                        style = MaterialTheme.typography.headlineLarge,
                        color = MaterialTheme.colorScheme.primary)
                    Text(loadGuideCaption(guide),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Button(onClick = { onApply(guide.suggestedKg) }) {
                    Text("Aplicar")
                }
            }
        }
    }
}

internal fun loadGuideShortDate(epochMillis: Long): String {
    if (epochMillis <= 0) return ""
    val fmt = java.time.format.DateTimeFormatter.ofPattern("d MMM",
        java.util.Locale("es", "ES"))
    return java.time.Instant.ofEpochMilli(epochMillis)
        .atZone(java.time.ZoneId.systemDefault()).format(fmt)
}

/** kg con formato español recortado (ReperaNumberFormat.decimal, 7bbf1a17). */
internal fun loadGuideKgLabel(kg: Double): String =
    dev.repera.domain.ReperaNumberFormat.decimal(kg)

/** decimal recortado (sustituye al %g recortado manual, 7bbf1a17). */
internal fun loadGuideG(v: Double): String =
    dev.repera.domain.ReperaNumberFormat.decimal(v)

internal fun loadGuideCaption(guide: LoadGuide): String {
    val rir = "RIR " + loadGuideG(guide.effectiveRir) +
        (if (guide.assumedRir) " (asumido)" else "")
    return "${guide.targetReps} reps · $rir · ${guide.suggestionSource}"
}

/** Línea de serie (misma forma que SetSummaryLine.displayLine). */
internal fun loadGuideSetLine(set: LoadGuideSet): String =
    dev.repera.domain.SetSummaryLine.displayLine(
        reps = set.reps, quantityUnit = set.unit,
        weightKg = set.weightKg, durationSeconds = set.durationSeconds)

/** Curva de pulso de la sesión con scrub (port de la sección «Ritmo
 *  cardíaco» de CardioRouteComponents iOS): cabecera con punto elegido o
 *  media, línea con regla discontinua y marcador durante el arrastre. */
@Composable
internal fun HeartRateCurveSection(
    sessionId: String,
    provider: suspend (String) -> List<Pair<Long, Int>>
) {
    val series by produceState(initialValue = emptyList<Pair<Long, Int>>(),
        key1 = sessionId) {
        value = runCatching { provider(sessionId) }.getOrDefault(emptyList())
    }
    if (series.size < 2) return
    val minBpm = series.minOf { it.second }
    val maxBpm = series.maxOf { it.second }
    val t0 = series.first().first
    val t1 = series.last().first
    var selectedTime by remember(sessionId) { mutableStateOf<Long?>(null) }
    val picked = selectedTime?.let { sel ->
        series.minByOrNull { kotlin.math.abs(it.first - sel) }
    }
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Ritmo cardíaco", style = MaterialTheme.typography.titleMedium)
            Text(
                if (picked != null) "${picked.second} lpm"
                else "Media ${series.map { it.second }.average().toInt()} lpm",
                style = MaterialTheme.typography.bodySmall,
                color = if (picked != null) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant)
        }
        val spanT = (t1 - t0).coerceAtLeast(1L).toDouble()
        val spanBpm = (maxBpm - minBpm).coerceAtLeast(1).toDouble()
        Canvas(modifier = Modifier.fillMaxWidth().height(96.dp)
            .pointerInput(series) {
                detectDragGestures(
                    onDragStart = { start ->
                        selectedTime = t0 + ((start.x / size.width.toFloat())
                            .coerceIn(0f, 1f) * spanT).toLong()
                    },
                    onDrag = { change, _ ->
                        selectedTime = t0 + ((change.position.x /
                            size.width.toFloat()).coerceIn(0f, 1f) * spanT).toLong()
                        change.consume()
                    },
                    onDragEnd = { selectedTime = null },
                    onDragCancel = { selectedTime = null }
                )
            }) {
            val path = androidx.compose.ui.graphics.Path()
            series.forEachIndexed { i, (t, bpm) ->
                val x = (((t - t0) / spanT).toFloat()) * size.width
                val y = size.height -
                    (((bpm - minBpm) / spanBpm).toFloat() * size.height)
                if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }
            drawPath(path, color = androidx.compose.ui.graphics.Color(0xFFFF453A),
                style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4f))
            if (picked != null) {
                val px = (((picked.first - t0) / spanT).toFloat()) * size.width
                val py = size.height -
                    (((picked.second - minBpm) / spanBpm).toFloat() * size.height)
                drawLine(
                    color = androidx.compose.ui.graphics.Color(0x73FFFFFF),
                    start = androidx.compose.ui.geometry.Offset(px, 0f),
                    end = androidx.compose.ui.geometry.Offset(px, size.height),
                    strokeWidth = 2f,
                    pathEffect = androidx.compose.ui.graphics.PathEffect
                        .dashPathEffect(floatArrayOf(8f, 8f))
                )
                drawCircle(color = androidx.compose.ui.graphics.Color(0xFFFF453A),
                    radius = 9f,
                    center = androidx.compose.ui.geometry.Offset(px, py))
            }
        }
        Text("${minBpm}–${maxBpm} lpm durante la sesión · arrastra para inspeccionar",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

