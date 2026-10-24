package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
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
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.draw.clip
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


internal val brandGreen = Color(0xFF30D158)

@Composable
internal fun ActiveWorkoutCard(
    active: ActiveWorkout,
    busy: Boolean,
    onLogSet: (Int, Double?, Double?, Boolean, String?, Int?, Int?) -> Unit,
    onReviseSet: (String, Int, Double?, String?, Int?, Int?) -> Unit,
    onDeleteSet: (String) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onLogDropSet: (Int, Double?, List<Pair<Int, Double?>>) -> Unit = { _, _, _ -> },
    onLogRestPauseSet: (List<Pair<Int, Int>>, Double?) -> Unit = { _, _ -> }
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
    var rirText by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("")
    }
    var editingId by remember(active.id, active.index) { mutableStateOf<String?>(null) }
    var editingQuantity by remember(active.id, active.index) { mutableStateOf("") }
    var editingWeight by remember(active.id, active.index) { mutableStateOf("") }
    var editingDeficit by remember(active.id, active.index) { mutableStateOf("") }
    var editingUnit by remember(active.id, active.index) { mutableStateOf(active.quantityUnit) }
    var editingDuration by remember(active.id, active.index) { mutableStateOf("") }
    val parsedRir = rirText.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val parsedQuantity = quantity.toIntOrNull()
    val parsedWeight = weight.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val valid = parsedQuantity != null && parsedQuantity >= 0 &&
        (!active.allowsWeight || weight.isBlank() ||
            (parsedWeight != null && parsedWeight.isFinite() && parsedWeight >= 0)) &&
        (!active.allowsDeficit || deficit.isBlank() ||
            (deficit.toIntOrNull()?.let { it in 0..100 } == true)) &&
        (rirText.isBlank() || (parsedRir != null && parsedRir.isFinite() && parsedRir >= 0)) &&
        validDuration && (unit in if (active.cardioToggle) setOf("calories", "meters")
            else setOf(active.quantityUnit))
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text("Ejercicio ${active.index + 1}/${active.total}: ${active.exerciseName}",
                style = MaterialTheme.typography.titleMedium)
            Text("${active.completedSets} series registradas")
            active.sets.forEachIndexed { index, set ->
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    Text((if (set.phase == "warmup") "Calentamiento" else "Serie") +
                        " ${index + 1}: ${set.reps} " + when (set.unit) {
                            "calories" -> "cal"
                            "meters" -> "m"
                            else -> "reps"
                        } +
                        (set.weightKg?.let { " · $it kg" } ?: "") +
                        (set.deficitCm?.let { " · $it cm déficit" } ?: "") +
                        (set.rir?.let { " · RIR $it" } ?: "") +
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
                val editWeight = editingWeight.trim().replace(',', '.')
                    .takeIf { it.isNotBlank() }?.toDoubleOrNull()
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
            if (!active.durationInput) OutlinedTextField(
                value = rirText,
                onValueChange = { rirText = it },
                label = { Text("RIR opcional (repeticiones en reserva)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (!active.durationInput) Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start
            ) {
                Checkbox(checked = warmup, onCheckedChange = { warmup = it }, enabled = !busy)
                Text("Serie de calentamiento", modifier = Modifier.padding(top = 12.dp))
            }
            if (!active.durationInput && !warmup) {
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
                    val weight = parts.getOrNull(1)?.trim()?.replace(',', '.')
                        ?.toDoubleOrNull()
                    reps to weight
                }
            val restSecondsValue = clusterRest.toIntOrNull()
            val parsedClusters = if (technique != "restpause") emptyList() else
                clustersText.split('+', ',', ' ').mapNotNull { it.trim().toIntOrNull() }
                    .map { it to (restSecondsValue ?: 15) }
            val validTechnique = when (technique) {
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
                    if (parsedQuantity != null) when (technique) {
                        "dropset" -> onLogDropSet(
                            parsedQuantity,
                            if (active.allowsWeight) parsedWeight else null,
                            parsedDrops)
                        "restpause" -> onLogRestPauseSet(
                            parsedClusters,
                            if (active.allowsWeight) parsedWeight else null)
                        else -> onLogSet(
                            parsedQuantity,
                            if (active.allowsWeight) parsedWeight else null,
                            if (active.durationInput) null else parsedRir,
                            if (active.durationInput) false else warmup,
                            unit,
                            parsedDuration,
                            if (active.allowsDeficit) deficit.toIntOrNull() else null
                        )
                    }
                },
                enabled = !busy && valid && validTechnique,
                modifier = Modifier.fillMaxWidth()
            ) { Text("Registrar serie") }
            OutlinedButton(onClick = onNext, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                Text(if (active.index + 1 == active.total) "Terminar último ejercicio" else "Siguiente ejercicio")
            }
            TextButton(onClick = onFinish, enabled = !busy) { Text("Finalizar entrenamiento") }
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
    onOpenClock: () -> Unit
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
    onSetProgression: (String, String) -> Unit = { _, _ -> }
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
            Text(routine.title, style = MaterialTheme.typography.titleMedium)
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
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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
                    value = editTitle, onValueChange = { editTitle = it.take(100) },
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
                if (editPlanning == "date") OutlinedTextField(
                    value = editDate, onValueChange = { editDate = it.take(10) },
                    label = { Text("Fecha (AAAA-MM-DD)") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth())
                if (editPlanning == "weekly") Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    listOf("L", "M", "X", "J", "V", "S", "D").forEachIndexed { index, day ->
                        FilterChip(selected = editWeekday == index + 1,
                            onClick = { editWeekday = index + 1 },
                            label = { Text(day) })
                    }
                }
                if (editPlanning != "library") OutlinedTextField(
                    value = editClock, onValueChange = { editClock = it.take(5) },
                    label = { Text("Hora opcional (HH:mm)") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth())
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
            .map { entry -> entry to ExerciseAliasSearch.score(search, entry.name, aliases) }
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
                    title.trim().length <= 100 && chosen.isNotEmpty() &&
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
internal fun WeekTrainingBars(totals: List<Int>) {
    if (totals.size != 7) return
    val labels = listOf("L", "M", "X", "J", "V", "S", "D")
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
internal fun WeekCalendarStrip(selected: LocalDate, onSelect: (LocalDate) -> Unit) {
    val weekStart = selected.minusDays((selected.dayOfWeek.value - 1).toLong())
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween) {
                TextButton(onClick = { onSelect(selected.minusWeeks(1)) }) {
                    Text("‹ Semana")
                }
                Text("${weekStart.dayOfMonth}/${weekStart.monthValue} – " +
                    "${weekStart.plusDays(6).dayOfMonth}/${weekStart.plusDays(6).monthValue}",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.padding(top = 12.dp))
                TextButton(onClick = { onSelect(selected.plusWeeks(1)) }) {
                    Text("Semana ›")
                }
            }
            // Los 7 días siempre visibles (sin scroll): el día de hoy nunca
            // queda escondido al final de la semana.
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                val days = listOf("L", "M", "X", "J", "V", "S", "D")
                repeat(7) { index ->
                    val day = weekStart.plusDays(index.toLong())
                    // Celda propia (no FilterChip): el padding interno del chip
                    // envolvía los números de dos cifras ("1/9" en vez de 19).
                    // Letra 11sp sobre número 17sp como calendarDayColumn (iOS).
                    val isSelected = day == selected
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier
                            .weight(1f)
                            .clip(androidx.compose.foundation.shape.RoundedCornerShape(12.dp))
                            .background(
                                if (isSelected) brandGreen.copy(alpha = 0.18f)
                                else androidx.compose.ui.graphics.Color.Transparent
                            )
                            .clickable { onSelect(day) }
                            .padding(vertical = 8.dp)
                    ) {
                        Text(days[index], fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1, softWrap = false)
                        Text("${day.dayOfMonth}", fontSize = 17.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                            maxLines = 1, softWrap = false)
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
    onDeleteFinishedSet: (String, String, String) -> Unit = { _, _, _ -> }
) {
    var expanded by remember(workout.id) { mutableStateOf(false) }
    var selectedMovement by remember(workout.id) { mutableStateOf<Int?>(null) }
    var editingSetId by remember(workout.id) { mutableStateOf<String?>(null) }
    var editQuantity by remember(workout.id) { mutableStateOf("") }
    var editWeight by remember(workout.id) { mutableStateOf("") }
    var editDuration by remember(workout.id) { mutableStateOf("") }
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            Text(workout.title, style = MaterialTheme.typography.titleMedium)
            if (workout.startedAt.isNotBlank()) {
                Text(workout.startedAt, style = MaterialTheme.typography.labelMedium)
            }
            workout.results.forEach { result ->
                Text(result, style = MaterialTheme.typography.titleSmall)
            }
            if (!expanded) {
                TextButton(onClick = { expanded = true }) { Text("Ver ejercicios y resultados") }
            } else if (selectedMovement != null) {
                val index = selectedMovement!!
                val exercise = workout.movements.getOrNull(index)
                TextButton(onClick = { selectedMovement = null }) {
                    Text("← Volver al resumen")
                }
                if (exercise != null) {
                    Text(exercise.name, style = MaterialTheme.typography.titleMedium)
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
                                                editWeight.replace(',', '.')
                                                    .toDoubleOrNull() != null),
                                        onClick = {
                                            onReviseFinishedSet(
                                                workout.id, exercise.entryId, set.setId,
                                                quantityValue ?: 0,
                                                editWeight.takeIf { it.isNotBlank() }
                                                    ?.replace(',', '.')?.toDoubleOrNull(),
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
    Text("Cuenta y sincronización", style = MaterialTheme.typography.titleMedium)
    Button(
        onClick = onDriveSync, enabled = !busy,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black)
    ) {
        if (syncing) CircularProgressIndicator(
            modifier = Modifier.padding(end = 8.dp))
        Text(if (syncing) "Sincronizando…" else "Sincronizar con Google Drive")
    }
    if (status != null) Text(status)
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
