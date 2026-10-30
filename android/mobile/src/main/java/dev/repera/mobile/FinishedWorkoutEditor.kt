package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.ui.zIndex
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material.icons.outlined.KeyboardArrowUp
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

/** Editor de un entreno terminado (WorkoutDetailView.isEditing iOS): título,
 *  inicio/fin, lugar (sólo sin ruta) y notas. Trabaja sobre un BORRADOR local:
 *  nada se escribe hasta «Guardar»; «Cancelar» descarta (historial intacto).
 *
 *  @param forceEditing abre ya en modo edición (página full iOS DayEditorView).
 *  @param onOpenFullEditor si no es null, «Editar entreno» navega en vez de inline.
 *  @param onDismiss tras Guardar/Cancelar en modo página (pop). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun FinishedWorkoutEditorSection(
    workout: WorkoutHistoryEntry,
    accountId: String,
    busy: Boolean,
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    effortUnit: String = "rir",
    forceEditing: Boolean = false,
    onOpenFullEditor: (() -> Unit)? = null,
    onDismiss: (() -> Unit)? = null,
    onSave: (WorkoutRepository.FinishedWorkoutEdit) -> Unit
) {
    var editing by remember(accountId, workout.id, forceEditing) { mutableStateOf(forceEditing) }
    val hasRoute = workout.routePoints.size >= 2
    if (!editing) {
        // R5 P1-10: no mostrar pin GPS anónimo sin lugar elegido (iOS hasChosenPlace).
        val chosen = workout.locationPin?.takeIf { it.hasChosenPlace }
        if (!hasRoute && chosen != null) {
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                WorkoutPlacePickerRow(
                    pin = chosen,
                    accountId = accountId,
                    onPinChange = {},
                    readOnly = true
                )
            }
        }
        workout.notes?.let {
            ReperaSectionTitle("Notas")
            Text(it, style = MaterialTheme.typography.bodyMedium)
        }
        TextButton(
            onClick = {
                if (onOpenFullEditor != null) onOpenFullEditor() else editing = true
            },
            enabled = !busy,
            modifier = Modifier.testTag("edit_finished_workout")
        ) { Text("Editar entreno") }
        return
    }
    // Borrador: se reinicia cada vez que se entra en edición.
    var title by remember(accountId, workout.id) { mutableStateOf(workout.title) }
    var startIso by remember(accountId, workout.id) { mutableStateOf(workout.startedAtIso) }
    var endIso by remember(accountId, workout.id) { mutableStateOf(workout.finishedAtIso) }
    var notes by remember(accountId, workout.id) { mutableStateOf(workout.notes.orEmpty()) }
    var pin by remember(accountId, workout.id) {
        mutableStateOf(workout.locationPin?.takeIf { it.hasChosenPlace })
    }
    var pinEdited by remember(accountId, workout.id) { mutableStateOf(false) }
    // Borrador del CONTENIDO: copia JSON con ids; solo se escribe al Guardar.
    val blocks = remember(accountId, workout.id) {
        // «Comenzar» sin WOD previo tiene cero bloques, pero se puede
        // enriquecer la MISMA actividad con la pizarra después de la clase.
        runCatching { org.json.JSONArray(workout.editableBlocksJson ?: "[]") }.getOrNull()
    }
    // Marca WOD completada (Apple changingScore): borrador de visualización; al guardar se reproducen las ediciones.
    var scoreSession by remember(accountId, workout.id) {
        mutableStateOf(workout.scoreSessionJson?.let { runCatching { org.json.JSONObject(it) }.getOrNull() })
    }
    val scoreEdits = remember(accountId, workout.id) { mutableStateListOf<WorkoutRepository.ScoreEdit>() }
    var contentVersion by remember(accountId, workout.id) { mutableIntStateOf(0) }
    var contentDirty by remember(accountId, workout.id) { mutableStateOf(false) }
    var showBoardScanner by remember(accountId, workout.id) { mutableStateOf(false) }
    var recordNewSetsAsPerformed by remember(accountId, workout.id) { mutableStateOf(false) }
    if (showBoardScanner) {
        ReperaModalBottomSheet(onDismissRequest = { showBoardScanner = false }) {
            BoardScanScreen(
                busy = busy,
                overview = null,
                catalogOverride = exerciseCatalog,
                asSheet = true,
                onConfirm = { _, _, _ -> },
                onBack = { showBoardScanner = false },
                onImportBlocks = { imported ->
                    imported.forEach { block ->
                        blocks?.put(BoardScanImport.wireBlock(block))
                    }
                    contentDirty = true
                    contentVersion++
                    showBoardScanner = false
                }
            )
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (!forceEditing) {
            Text("Editar", style = MaterialTheme.typography.titleMedium)
        }
        Text(
            "Edita los datos registrados sin modificar la rutina programada.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        OutlinedTextField(value = title, onValueChange = { title = it },
            label = { Text("Nombre del entreno") }, singleLine = true,
            modifier = Modifier.fillMaxWidth().testTag("edit_title"))
        val zone = ZoneId.systemDefault()
        val startZ = remember(startIso) {
            startIso?.let { runCatching { Instant.parse(it).atZone(zone) }.getOrNull() }
                ?: ZonedDateTime.now(zone)
        }
        val durationMin = remember(startIso, endIso) {
            val e = endIso?.let { runCatching { Instant.parse(it).atZone(zone) }.getOrNull() }
            if (e != null) maxOf(1, java.time.Duration.between(startZ, e).toMinutes().toInt())
            else 45
        }
        fun applyStartKeepingDuration(newStart: ZonedDateTime) {
            startIso = newStart.toInstant().toString()
            endIso = newStart.plusMinutes(durationMin.toLong()).toInstant().toString()
        }
        WorkoutDateTimeDurationRow(
            dayIso = startZ.toLocalDate().toString(),
            clock = "%02d:%02d".format(startZ.hour, startZ.minute),
            durationMinutes = durationMin,
            onDayIso = { iso ->
                val d = runCatching { java.time.LocalDate.parse(iso) }.getOrNull() ?: return@WorkoutDateTimeDurationRow
                applyStartKeepingDuration(
                    startZ.withYear(d.year).withMonth(d.monthValue).withDayOfMonth(d.dayOfMonth)
                )
            },
            onClock = { clock ->
                val t = runCatching { java.time.LocalTime.parse(clock) }.getOrNull()
                    ?: return@WorkoutDateTimeDurationRow
                applyStartKeepingDuration(startZ.withHour(t.hour).withMinute(t.minute).withSecond(0).withNano(0))
            },
            onDurationMinutes = { mins ->
                val m = mins.coerceIn(1, 600)
                startIso = startZ.toInstant().toString()
                endIso = startZ.plusMinutes(m.toLong()).toInstant().toString()
            },
            dayTestTag = "edit_start_date",
            timeTestTag = "edit_start_time",
            durationTestTag = "edit_duration"
        )
        if (!hasRoute) {
            ReperaSectionTitle("Lugar")
            WorkoutPlacePickerRow(pin = pin, accountId = accountId,
                onPinChange = { pin = it; pinEdited = true })
        }
        if (blocks != null) {
            Text("Contenido", style = MaterialTheme.typography.titleMedium)
            key(contentVersion) {
                FinishedContentEditor(blocks, exerciseCatalog, effortUnit,
                    onEdited = { contentDirty = true },
                    onChanged = { contentDirty = true; contentVersion++ },
                    onScanBoard = { showBoardScanner = true })
            }
            if (workout.liveSportID != null) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Checkbox(
                        checked = recordNewSetsAsPerformed,
                        onCheckedChange = { recordNewSetsAsPerformed = it },
                        modifier = Modifier.testTag("edit_register_new_sets")
                    )
                    Text("Registrar las nuevas series como realizadas")
                }
                Text("Revisa antes los pesos, repeticiones y RIR. Solo las series que confirmes se incorporan a Progreso. La ruta, el pulso y las calorías originales permanecen intactos.",
                    style = MaterialTheme.typography.bodySmall)
            }
        }
        if (blocks != null && scoreSession != null) {
            for (bi in 0 until blocks.length()) {
                val b = blocks.getJSONObject(bi)
                val cap = dev.repera.domain.WodFormat.fromWire(b.optString("wodFormat"))?.capture?.name
                if (cap != "TOTAL_REPS" && cap != "ELAPSED_TIME") continue
                val fmt = dev.repera.domain.WodFormat.fromWire(b.optString("wodFormat"))
                // iOS: Rondas completas → Reps adicionales (AMRAP/Death by).
                val fields = if (cap == "TOTAL_REPS") buildList {
                    if (fmt == dev.repera.domain.WodFormat.AMRAP || fmt == dev.repera.domain.WodFormat.DEATH_BY)
                        add(CompletedWorkoutEditing.ScoreField.ROUNDS to "Rondas")
                    add(CompletedWorkoutEditing.ScoreField.REPS to
                        if (fmt == dev.repera.domain.WodFormat.AMRAP || fmt == dev.repera.domain.WodFormat.DEATH_BY)
                            "Reps adicionales" else "Repeticiones")
                } else listOf(CompletedWorkoutEditing.ScoreField.MINUTES to "Minutos", CompletedWorkoutEditing.ScoreField.SECONDS to "Segundos")
                Text("Resultado · ${b.optString("title")}", style = MaterialTheme.typography.titleMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    for ((field, label) in fields) {
                        key(workout.id, b.optString("id"), field.name) {
                            FinishedScoreField(
                                block = b,
                                field = field,
                                label = label,
                                initial = CompletedWorkoutEditing.scoreValue(
                                    b, scoreSession!!, field),
                                onCommit = { v ->
                                    val base = scoreSession ?: return@FinishedScoreField
                                    scoreSession = CompletedWorkoutEditing.changingScore(
                                        base, b, field, v)
                                    scoreEdits.add(
                                        WorkoutRepository.ScoreEdit(b.optString("id"), field, v))
                                }
                            )
                        }
                    }
                }
                if (cap == "ELAPSED_TIME") Text("Tiempo real empleado (no el time cap).", style = MaterialTheme.typography.bodySmall)
            }
        }
        OutlinedTextField(value = notes, onValueChange = { notes = it },
            label = { Text("Notas: cómo te sentiste, molestias…") }, minLines = 2, maxLines = 5,
            modifier = Modifier.fillMaxWidth().testTag("edit_notes"))
        var saveAsFavorite by remember { mutableStateOf(false) }
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            androidx.compose.material3.Switch(checked = saveAsFavorite, onCheckedChange = { saveAsFavorite = it },
                colors = reperaSwitchColors(),
                modifier = Modifier.testTag("edit_save_favorite"))
            Text("  Guardar también como favorito")
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(enabled = !busy, modifier = Modifier.testTag("edit_save"), onClick = {
                onSave(WorkoutRepository.FinishedWorkoutEdit(
                    title = title, startedAtIso = startIso, finishedAtIso = endIso,
                    notes = notes, pinEdited = pinEdited, pin = pin,
                    blocksJson = if (contentDirty) blocks?.toString() else null,
                    saveAsFavorite = saveAsFavorite, scoreEdits = scoreEdits.toList(),
                    recordNewSetsAsPerformed = recordNewSetsAsPerformed))
                if (onDismiss != null) onDismiss() else editing = false
            }) { Text("Guardar") }
            TextButton(modifier = Modifier.testTag("edit_cancel"),
                onClick = {
                    if (onDismiss != null) onDismiss() else editing = false
                }) { Text("Cancelar") }
        }
    }
}

/**
 * Página completa «Editar entreno» (iOS DayEditorView vía showCompletedEditor).
 * No edita el plan programado; solo el registro terminado.
 */
@Composable
internal fun FinishedWorkoutEditorScreen(
    workout: WorkoutHistoryEntry,
    accountId: String,
    busy: Boolean,
    exerciseCatalog: List<ExerciseEntry>,
    effortUnit: String,
    onBack: () -> Unit,
    onSave: (WorkoutRepository.FinishedWorkoutEdit) -> Unit,
) {
    androidx.activity.compose.BackHandler(onBack = onBack)
    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .testTag("finished_workout_editor_page"),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            ReperaToolbarGlassIconButton(
                icon = Icons.Outlined.Close,
                contentDescription = "Cerrar",
                onClick = onBack,
                modifier = Modifier.testTag("finished_workout_editor_back")
            )
            Spacer(Modifier.weight(1f))
        }
        ReperaPageHeader(title = "Editar entreno")
        FinishedWorkoutEditorSection(
            workout = workout,
            accountId = accountId,
            busy = busy,
            exerciseCatalog = exerciseCatalog,
            effortUnit = effortUnit,
            forceEditing = true,
            onDismiss = onBack,
            onSave = onSave
        )
    }
}

/**
 * Campo de marca WOD con estado local: no escribe 0 al vaciar el texto
 * (IME/recomposición) ni al abrir el editor sin tocar (P0-3 R6).
 */
@Composable
private fun RowScope.FinishedScoreField(
    block: org.json.JSONObject,
    field: CompletedWorkoutEditing.ScoreField,
    label: String,
    initial: Int,
    onCommit: (Int) -> Unit
) {
    var text by remember(initial) { mutableStateOf(initial.toString()) }
    var committed by remember(initial) { mutableIntStateOf(initial) }
    OutlinedTextField(
        value = text,
        onValueChange = { raw ->
            val filtered = raw.filter { it.isDigit() }.take(5)
            text = filtered
            if (filtered.isEmpty()) return@OutlinedTextField
            val v = filtered.toIntOrNull() ?: return@OutlinedTextField
            if (v == committed) return@OutlinedTextField
            committed = v
            onCommit(v)
        },
        label = { Text(label) },
        singleLine = true,
        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
            keyboardType = androidx.compose.ui.text.input.KeyboardType.Number),
        modifier = Modifier.weight(1f)
            .testTag("edit_score_${block.optString("id")}_${field.name}")
    )
}

/** Editor de bloques de un entreno terminado: reordenar, quitar, añadir
 *  ejercicio y editar series (reps / kg / esfuerzo). Los bloques WOD se muestran sin
 *  edición (Android no tiene editor de movimientos). Opera sobre el borrador. */
@Composable
private fun FinishedContentEditor(
    blocks: org.json.JSONArray,
    catalog: List<ExerciseEntry>,
    effortUnit: String = "rir",
    onEdited: () -> Unit,
    onChanged: () -> Unit,
    onScanBoard: () -> Unit = {}
) {
    val nameById = remember(catalog) { catalog.associate { it.id to it.name } }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        val blkHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
        val geo = remember { EditorGeometry() }
        for (b in 0 until blocks.length()) {
            DragReorderItem(b, blkHeights, blocks.length(),
                onDrop = { _, t -> if (t != b && EditorBlockOps.moveBlock(blocks, b, t)) onChanged() },
                onMoveTo = { t -> if (EditorBlockOps.moveBlock(blocks, b, t)) onChanged() },
                onBounds = { top, bottom -> geo.blocks[b] = top to bottom }) { handle ->
            val block = blocks.getJSONObject(b)
            var title by remember(block.optString("id")) { mutableStateOf(block.optString("title")) }
            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Icon(Icons.Outlined.DragHandle, contentDescription = "Reordenar", modifier = handle.testTag("block_drag_$b").padding(8.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                OutlinedTextField(value = title, singleLine = true, label = { Text("Bloque ${b + 1}") },
                    modifier = Modifier.weight(1f).testTag("block_title_$b"),
                    onValueChange = { title = it; block.put("title", it); onEdited() })
                TextButton(enabled = b > 0, modifier = Modifier.testTag("block_up_$b"), onClick = {
                    EditorBlockOps.moveBlock(blocks, b, b - 1); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowUp, contentDescription = "Subir") }
                TextButton(enabled = b < blocks.length() - 1, modifier = Modifier.testTag("block_down_$b"), onClick = {
                    EditorBlockOps.moveBlock(blocks, b, b + 1); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowDown, contentDescription = "Bajar") }
                TextButton(modifier = Modifier.testTag("block_remove_$b"), onClick = {
                    EditorBlockOps.removeBlock(blocks, b); onChanged() }) { Text("Quitar") }
            }
            if (block.optString("kind") != "strength") {
                var fmtOpen by remember { mutableStateOf(false) }
                val cur = dev.repera.domain.WodFormat.fromWire(block.optString("wodFormat"))
                TextButton(modifier = Modifier.testTag("block_format_$b"), onClick = { fmtOpen = true }) {
                    Text("Formato: ${cur?.displayName ?: "sin formato"}") }
                DropdownMenu(expanded = fmtOpen, onDismissRequest = { fmtOpen = false }) {
                    dev.repera.domain.WodFormat.values().forEach { f ->
                        DropdownMenuItem(text = { Text(f.displayName) }, modifier = Modifier.testTag("block_format_${b}_${f.wireName}"),
                            onClick = { fmtOpen = false; block.put("wodFormat", f.wireName); onChanged() })
                    }
                }
                WodMovementsEditor(blocks, b, nameById, catalog, geo, onEdited, onChanged, effortUnit)
                return@DragReorderItem
            }
            val items = block.optJSONArray("exercises") ?: org.json.JSONArray().also { block.put("exercises", it) }
            val exHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                DragReorderItem(i, exHeights, items.length(),
                    onDrop = { cy, t -> handleItemDrop(blocks, geo, b, item.optString("id"), i, items, cy, t,
                        { id -> nameById[id] ?: "Ejercicio" },
                        { null }, onChanged) },
                    onMoveTo = { t -> if (EditorBlockOps.reorder(items, i, t)) onChanged() },
                    onBounds = { top, bottom -> geo.items.getOrPut(b) { mutableMapOf() }[item.optString("id")] = top to bottom }) { handle ->
                SwipeRemove(item.optString("id"), "ex_swipe", { val ix = (0 until items.length()).firstOrNull { items.getJSONObject(it).optString("id") == item.optString("id") }; if (ix != null) { items.remove(ix); onChanged() } }) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Icon(Icons.Outlined.DragHandle, contentDescription = "Reordenar", modifier = handle.testTag("ex_drag_${b}_$i").padding(8.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(item.optString("exerciseId").let { id ->
                        if (id.startsWith(EditorBlockOps.PENDING_PREFIX)) id.removePrefix(EditorBlockOps.PENDING_PREFIX) + " (nuevo, se crea al guardar)"
                        else nameById[id] ?: "Ejercicio" },
                        style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    TextButton(enabled = i > 0, modifier = Modifier.testTag("ex_up_${b}_$i"), onClick = {
                        swap(items, i, i - 1); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowUp, contentDescription = "Subir") }
                    TextButton(enabled = i < items.length() - 1, modifier = Modifier.testTag("ex_down_${b}_$i"), onClick = {
                        swap(items, i, i + 1); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowDown, contentDescription = "Bajar") }
                    var moving by remember { mutableStateOf(false) }
                    val targets = (0 until blocks.length()).filter { it != b }
                    if (targets.isNotEmpty()) {
                        TextButton(modifier = Modifier.testTag("ex_move_${b}_$i"),
                            onClick = { moving = true }) { Text("Mover") }
                        DropdownMenu(expanded = moving, onDismissRequest = { moving = false }) {
                            targets.forEach { t ->
                                DropdownMenuItem(
                                    text = { Text(blocks.getJSONObject(t).optString("title").ifBlank { "Bloque ${t + 1}" }) },
                                    modifier = Modifier.testTag("ex_move_to_${b}_${i}_$t"),
                                    onClick = {
                                        moving = false
                                        val ok = EditorBlockOps.moveItem(blocks, b, item.optString("id"), t, null,
                                            { id -> nameById[id] ?: "Ejercicio" }, { null })
                                        if (!ok) onEdited()
                                        onChanged()
                                    })
                            }
                        }
                    }
                    TextButton(modifier = Modifier.testTag("ex_remove_${b}_$i"), onClick = {
                        items.remove(i); onChanged() }) { Text("Quitar") }
                }
                }
                val sets = item.optJSONArray("plannedSets") ?: org.json.JSONArray().also { item.put("plannedSets", it) }
                // Apple f7109bd7 (WorkoutDetailView.editSetColumnHeaders):
                // «Reps / m» y selector de unidad por serie en recorridos.
                val exRawName = item.optString("exerciseId").let { id ->
                    nameById[id] ?: id.removePrefix(EditorBlockOps.PENDING_PREFIX) }
                val repsOrMeters = dev.repera.domain.ExerciseInput.supportsRepsOrMeters(exRawName)
                for (s in 0 until sets.length()) {
                    val set = sets.getJSONObject(s)
                    val setUnit = set.optString("targetQuantityUnit").takeIf { it == "reps" || it == "meters" }
                        ?: item.optString("quantityUnit").takeIf { it == "reps" || it == "meters" }
                        ?: dev.repera.domain.ExerciseInput.defaultQuantityUnit(exRawName, null)
                    var reps by remember { mutableStateOf(set.optInt("targetReps").toString()) }
                    var kg by remember { mutableStateOf(
                        if (set.has("targetWeightKg") && !set.isNull("targetWeightKg"))
                            set.getDouble("targetWeightKg").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() }
                        else "") }
                    // Apple editableSetRow (VStack): el picker de unidad va en su
                    // propia fila SOBRE los campos; en una sola fila se recorta en telefonos.
                    Column {
                    if (repsOrMeters) {
                        // Apple: Picker «Unidad de la serie» (segmented, ancho completo)
                        // - solo edicion explicita, nunca conversion automatica.
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            listOf("reps" to "Repeticiones", "meters" to "Metros").forEach { (u, lbl) ->
                                ReperaFilterChip(selected = setUnit == u,
                                    onClick = { set.put("targetQuantityUnit", u); onChanged() },
                                    label = { Text(lbl) },
                                    modifier = Modifier.weight(1f).testTag("set_unit_${u}_${b}_${i}_$s"))
                            }
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Text("Serie ${s + 1}", modifier = Modifier.width(64.dp))
                        OutlinedTextField(value = reps,
                            label = { Text(if (repsOrMeters) "Reps / m" else "Reps") }, singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_reps_${b}_${i}_$s"),
                            onValueChange = { v ->
                                // Apple: tope 100_000 en metros con recorrido.
                                reps = v.filter { it.isDigit() }
                                    .take(if (repsOrMeters && setUnit == "meters") 6 else 4)
                                set.put("targetReps", reps.toIntOrNull() ?: 0)
                                onEdited()
                            })
                        val hspuDeficit = dev.repera.domain.ExerciseInput.mode(
                            exRawName, null, null, null) ==
                            dev.repera.domain.ExerciseInputMode.HSPU_DEFICIT
                        OutlinedTextField(value = kg,
                            label = { Text(if (hspuDeficit) "Déficit (cm)" else "Kg") },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_kg_${b}_${i}_$s"),
                            onValueChange = { v ->
                                kg = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                                val parsed = dev.repera.domain.ReperaNumberFormat.parse(kg)
                                if (parsed != null) set.put("targetWeightKg", parsed) else set.remove("targetWeightKg")
                                onEdited()
                            })
                        var rir by remember(effortUnit) { mutableStateOf(
                            if (set.has("targetRir") && !set.isNull("targetRir"))
                                set.getDouble("targetRir").let {
                                    val display = dev.repera.domain.Effort.fromRIR(it, effortUnit)
                                    if (display % 1.0 == 0.0) display.toInt().toString() else display.toString()
                                }
                            else "") }
                        OutlinedTextField(value = rir,
                            label = { Text(dev.repera.domain.Effort.displayName(effortUnit)) },
                            singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_rir_${b}_${i}_$s"),
                            onValueChange = { v ->
                                rir = v.filter { it.isDigit() || it == '.' || it == ',' }.take(4)
                                val parsed = dev.repera.domain.ReperaNumberFormat.parse(rir)
                                if (parsed != null && parsed in 0.0..10.0) {
                                    set.put("targetRir",
                                        dev.repera.domain.Effort.toRIR(parsed, effortUnit))
                                } else set.remove("targetRir")
                                onEdited()
                            })
                        TextButton(modifier = Modifier.testTag("set_remove_${b}_${i}_$s"),
                            onClick = { sets.remove(s); onChanged() }) { Icon(Icons.Outlined.Close, contentDescription = "Eliminar") }
                    }
                    }
                }
                TextButton(modifier = Modifier.testTag("set_add_${b}_$i"), onClick = {
                    val last = sets.optJSONObject(sets.length() - 1)
                    sets.put(org.json.JSONObject()
                        .put("id", java.util.UUID.randomUUID().toString())
                        .put("targetReps", last?.optInt("targetReps") ?: 8)
                        .apply { if (last != null && last.has("targetWeightKg")) put("targetWeightKg", last.get("targetWeightKg")) })
                    onChanged()
                }) { Text("Añadir serie") }
                }
            }
            var picking by remember { mutableStateOf(false) }
            TextButton(modifier = Modifier.testTag("ex_add_$b"), enabled = catalog.isNotEmpty(),
                onClick = { picking = true }) { Text("Añadir ejercicio") }
            if (picking) {
                var q by remember { mutableStateOf("") }
                val normalized = remember(q) { foldForSearch(q) }
                val filtered = remember(q, catalog) {
                    if (normalized.isBlank()) catalog
                    else catalog.filter { foldForSearch(it.name).contains(normalized) }
                }
                AlertDialog(
                    onDismissRequest = { picking = false },
                    title = { Text("Añadir ejercicio") },
                    text = {
                        Column {
                            OutlinedTextField(value = q, onValueChange = { q = it }, singleLine = true,
                                label = { Text("Buscar en todo el catálogo") },
                                modifier = Modifier.fillMaxWidth().testTag("ex_search"))
                            androidx.compose.foundation.lazy.LazyColumn(Modifier.heightIn(max = 320.dp)) {
                                items(filtered.size, key = { filtered[it].id }) { idx ->
                                    val entry = filtered[idx]
                                    TextButton(modifier = Modifier.fillMaxWidth().testTag("ex_pick_${entry.id}"),
                                        onClick = {
                                            picking = false
                                            items.put(org.json.JSONObject()
                                                .put("id", java.util.UUID.randomUUID().toString())
                                                .put("exerciseId", entry.id)
                                                .put("plannedSets", org.json.JSONArray().put(org.json.JSONObject()
                                                    .put("id", java.util.UUID.randomUUID().toString()).put("targetReps", 8))))
                                            onChanged()
                                        }) { Text(entry.name, modifier = Modifier.fillMaxWidth()) }
                                }
                            }
                        }
                    },
                    confirmButton = {},
                    dismissButton = { TextButton(onClick = { picking = false }) { Text("Cancelar") } }
                )
            }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(modifier = Modifier.testTag("block_add_strength"), onClick = {
                blocks.put(EditorBlockOps.newBlock("strength", blocks.length() + 1)); onChanged() }) { Text("Añadir bloque de fuerza") }
            TextButton(modifier = Modifier.testTag("block_add_wod"), onClick = {
                blocks.put(EditorBlockOps.newBlock("wod", blocks.length() + 1, "amrap")); onChanged() }) { Text("Añadir bloque WOD") }
        }
        TextButton(
            modifier = Modifier.fillMaxWidth().testTag("completed_scan_board"),
            onClick = onScanBoard
        ) { Text("Escanear pizarra") }
    }
}

private fun swap(array: org.json.JSONArray, a: Int, b: Int) {
    val x = array.get(a); val y = array.get(b)
    array.put(a, y); array.put(b, x)
}

/** Búsqueda sin mayúsculas ni diacríticos (como la búsqueda de catálogo de iOS). */
internal fun foldForSearch(text: String): String =
    java.text.Normalizer.normalize(text.trim().lowercase(), java.text.Normalizer.Form.NFD)
        .replace(Regex("\\p{InCombiningDiacriticalMarks}+"), "")


/** Editor de movimientos WOD (WODMovementEditor de Apple): REST, nombre, series, cal/m, peso H/M, escala, notas. */
@Composable
private fun WodMovementsEditor(
    blocks: org.json.JSONArray, b: Int, nameById: Map<String, String>, catalog: List<ExerciseEntry>,
    geo: EditorGeometry, onEdited: () -> Unit, onChanged: () -> Unit,
    effortUnit: String = "rir"
) {
    val block = blocks.getJSONObject(b)
    val moves = block.optJSONArray("movements") ?: org.json.JSONArray().also { block.put("movements", it) }
    val mvHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
    for (i in 0 until moves.length()) {
        val m = moves.getJSONObject(i)
        val id = m.optString("id")
        DragReorderItem(i, mvHeights, moves.length(),
            onDrop = { cy, t -> handleItemDrop(blocks, geo, b, id, i, moves, cy, t, { "" }, { mv ->
                mv.optString("exerciseId").takeIf { x -> x.isNotBlank() && catalog.any { c -> c.id == x } }
                    ?: catalog.firstOrNull { c -> c.name.equals(mv.optString("name"), true) }?.id
                    ?: mv.optString("name").trim().takeIf { n -> n.isNotEmpty() }?.let { n -> EditorBlockOps.PENDING_PREFIX + n } }, onChanged) },
            onMoveTo = { t -> if (EditorBlockOps.reorder(moves, i, t)) onChanged() },
            onBounds = { top, bottom -> geo.items.getOrPut(b) { mutableMapOf() }[id] = top to bottom }) { handle ->
        SwipeRemove(id, "mv_swipe", { val ix = (0 until moves.length()).firstOrNull { moves.getJSONObject(it).optString("id") == id }; if (ix != null) { moves.remove(ix); onChanged() } }) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Icon(Icons.Outlined.DragHandle, contentDescription = "Reordenar", modifier = handle.testTag("mv_drag_${b}_$i").padding(8.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(if (m.optBoolean("isRest")) "REST" else m.optString("name"),
                style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
            TextButton(enabled = i > 0, modifier = Modifier.testTag("mv_up_${b}_$i"), onClick = {
                EditorBlockOps.moveItem(blocks, b, id, b, moves.getJSONObject(i - 1).optString("id"), { "" }, { null }); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowUp, contentDescription = "Subir") }
            TextButton(enabled = i < moves.length() - 1, modifier = Modifier.testTag("mv_down_${b}_$i"), onClick = {
                val next = if (i + 2 < moves.length()) moves.getJSONObject(i + 2).optString("id") else null
                EditorBlockOps.moveItem(blocks, b, id, b, next, { "" }, { null }); onChanged() }) { Icon(Icons.Outlined.KeyboardArrowDown, contentDescription = "Bajar") }
            var moving by remember { mutableStateOf(false) }
            val targets = (0 until blocks.length()).filter { it != b }
            if (targets.isNotEmpty() && !m.optBoolean("isRest") || targets.any { blocks.getJSONObject(it).optString("kind") != "strength" }) {
                TextButton(modifier = Modifier.testTag("mv_move_${b}_$i"), onClick = { moving = true }) { Text("Mover") }
                DropdownMenu(expanded = moving, onDismissRequest = { moving = false }) {
                    targets.forEach { t ->
                        DropdownMenuItem(text = { Text(blocks.getJSONObject(t).optString("title").ifBlank { "Bloque ${t + 1}" }) },
                            modifier = Modifier.testTag("mv_move_to_${b}_${i}_$t"),
                            onClick = {
                                moving = false
                                val ok = EditorBlockOps.moveItem(blocks, b, id, t, null, { "" }) { mv ->
                                    mv.optString("exerciseId").takeIf { x -> x.isNotBlank() && catalog.any { c -> c.id == x } }
                                        ?: catalog.firstOrNull { c -> c.name.equals(mv.optString("name"), true) }?.id
                                        ?: mv.optString("name").trim().takeIf { n -> n.isNotEmpty() }?.let { n -> EditorBlockOps.PENDING_PREFIX + n } }
                                if (ok) onChanged() else onEdited()
                            })
                    }
                }
            }
            TextButton(modifier = Modifier.testTag("mv_remove_${b}_$i"), onClick = { moves.remove(i); onChanged() }) { Text("Quitar") }
        }
        }
        if (m.optBoolean("isRest")) {
            var secs by remember(id) { mutableStateOf((if (m.has("restSeconds")) m.optInt("restSeconds") else 60).toString()) }
            OutlinedTextField(value = secs, singleLine = true, label = { Text("Segundos") },
                modifier = Modifier.fillMaxWidth().testTag("mv_rest_${b}_$i"),
                onValueChange = { v -> secs = v.filter { it.isDigit() }.take(3)
                    m.put("restSeconds", (secs.toIntOrNull() ?: 60).coerceIn(15, 300)); onEdited() })
            return@DragReorderItem
        }
        var name by remember(id) { mutableStateOf(m.optString("name")) }
        OutlinedTextField(value = name, singleLine = true, label = { Text("Nombre") },
            modifier = Modifier.fillMaxWidth().testTag("mv_name_${b}_$i"),
            onValueChange = { name = it; m.put("name", it); onEdited() })
        val catalogEntry = catalog.firstOrNull { it.id == m.optString("exerciseId") }
            ?: catalog.firstOrNull { it.name.equals(m.optString("name"), true) }
        val inputMode = catalogEntry?.let {
            dev.repera.domain.ExerciseInput.mode(it.name, it.equipment, it.targetMuscle, it.muscleGroup, it.sportTag)
        } ?: dev.repera.domain.ExerciseInput.mode(m.optString("name"), null, null, null)
        val allowsCalMeters = catalogEntry?.let {
            dev.repera.domain.ExerciseInput.supportsCaloriesAndMeters(it.name, it.equipment)
        } == true || inputMode == dev.repera.domain.ExerciseInputMode.MACHINE_WORK
        var machine by remember(id) {
            mutableStateOf(m.has("calories") && !m.isNull("calories") ||
                m.has("distanceMeters") && !m.isNull("distanceMeters") && !m.has("reps") ||
                inputMode == dev.repera.domain.ExerciseInputMode.MACHINE_WORK)
        }
        var machineUnit by remember(id) {
            mutableStateOf(
                when {
                    m.has("calories") && !m.isNull("calories") -> "calories"
                    m.has("distanceMeters") && !m.isNull("distanceMeters") -> "meters"
                    else -> "calories"
                }
            )
        }
        if (allowsCalMeters) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(modifier = Modifier.testTag("mv_unit_cal_${b}_$i"),
                    onClick = {
                        machine = true; machineUnit = "calories"
                        m.remove("reps"); m.remove("distanceMeters")
                        if (!m.has("calories")) m.put("calories", 10)
                        EditorBlockOps.writeSetsToMovement(m,
                            m.optJSONArray("explicitPlannedSets") ?: org.json.JSONArray(), true)
                        onChanged()
                    }) { Text(if (machine && machineUnit == "calories") "Calorías ✓" else "Calorías") }
                TextButton(modifier = Modifier.testTag("mv_unit_m_${b}_$i"),
                    onClick = {
                        machine = true; machineUnit = "meters"
                        m.remove("reps"); m.remove("calories")
                        if (!m.has("distanceMeters")) m.put("distanceMeters", 100)
                        EditorBlockOps.writeSetsToMovement(m,
                            m.optJSONArray("explicitPlannedSets") ?: org.json.JSONArray(), true)
                        onChanged()
                    }) { Text(if (machine && machineUnit == "meters") "Metros ✓" else "Metros") }
            }
        }
        val hspuDeficit = inputMode == dev.repera.domain.ExerciseInputMode.HSPU_DEFICIT
        val repsAndTime = inputMode == dev.repera.domain.ExerciseInputMode.REPS_AND_TIME
        val sets = m.optJSONArray("explicitPlannedSets")?.takeIf { it.length() > 0 }
            ?: CompletedWorkoutEditing.derivedSetsFor(block, m).also { m.put("explicitPlannedSets", it) }
        for (s in 0 until sets.length()) {
            val set = sets.getJSONObject(s)
            var reps by remember(id, set.optString("id")) { mutableStateOf(set.optInt("targetReps").toString()) }
            var kg by remember(id, set.optString("id")) { mutableStateOf(
                if (set.has("targetWeightKg") && !set.isNull("targetWeightKg")) set.getDouble("targetWeightKg").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() } else "") }
            var duration by remember(id, set.optString("id")) {
                mutableStateOf(
                    if (set.has("targetDurationSeconds") && !set.isNull("targetDurationSeconds"))
                        set.optInt("targetDurationSeconds").toString() else "")
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Text("Serie ${s + 1}", modifier = Modifier.width(64.dp))
                OutlinedTextField(value = reps, singleLine = true,
                    label = { Text(when {
                        machine && machineUnit == "calories" -> "Cal"
                        machine -> "m"
                        repsAndTime -> "Veces"
                        else -> "Reps"
                    }) },
                    modifier = Modifier.weight(1f).testTag("mv_set_reps_${b}_${i}_$s"),
                    onValueChange = { v -> reps = v.filter { it.isDigit() }.take(4)
                        set.put("targetReps", (reps.toIntOrNull() ?: 1).coerceAtLeast(1))
                        EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                if (repsAndTime) {
                    OutlinedTextField(value = duration, singleLine = true, label = { Text("Seg") },
                        modifier = Modifier.weight(1f).testTag("mv_set_dur_${b}_${i}_$s"),
                        onValueChange = { v -> duration = v.filter { it.isDigit() }.take(4)
                            val secs = duration.toIntOrNull()?.coerceIn(1, 3600)
                            if (secs != null) set.put("targetDurationSeconds", secs)
                            else set.remove("targetDurationSeconds")
                            EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                }
                if (!machine) OutlinedTextField(value = kg, singleLine = true,
                    label = { Text(if (hspuDeficit) "Déficit (cm)" else "Kg") },
                    modifier = Modifier.weight(1f).testTag("mv_set_kg_${b}_${i}_$s"),
                    onValueChange = { v -> kg = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                        val parsed = dev.repera.domain.ReperaNumberFormat.parse(kg)
                        if (parsed != null) set.put("targetWeightKg", parsed) else set.remove("targetWeightKg")
                        EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                if (!machine && !repsAndTime) {
                    var rir by remember(id, set.optString("id"), effortUnit) { mutableStateOf(
                        if (set.has("targetRir") && !set.isNull("targetRir")) set.getDouble("targetRir").let {
                            val display = dev.repera.domain.Effort.fromRIR(it, effortUnit)
                            if (display % 1.0 == 0.0) display.toInt().toString() else display.toString()
                        } else "") }
                    OutlinedTextField(value = rir, singleLine = true,
                        label = { Text(dev.repera.domain.Effort.displayName(effortUnit)) },
                        modifier = Modifier.weight(1f).testTag("mv_set_rir_${b}_${i}_$s"),
                        onValueChange = { v -> rir = v.filter { it.isDigit() || it == '.' || it == ',' }.take(4)
                            val p = dev.repera.domain.ReperaNumberFormat.parse(rir)
                            if (p != null && p in 0.0..10.0) {
                                set.put("targetRir",
                                    dev.repera.domain.Effort.toRIR(p, effortUnit))
                            } else set.remove("targetRir")
                            EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                }
                TextButton(enabled = sets.length() > 1, modifier = Modifier.testTag("mv_set_remove_${b}_${i}_$s"),
                    onClick = { sets.remove(s); EditorBlockOps.writeSetsToMovement(m, sets, machine); onChanged() }) { Icon(Icons.Outlined.Close, contentDescription = "Eliminar") }
            }
        }
        TextButton(enabled = sets.length() < 20, modifier = Modifier.testTag("mv_set_add_${b}_$i"), onClick = {
            val last = sets.optJSONObject(sets.length() - 1)
            sets.put(org.json.JSONObject().put("id", java.util.UUID.randomUUID().toString())
                .put("targetReps", last?.optInt("targetReps") ?: 10)
                .apply { if (last != null && last.has("targetWeightKg")) put("targetWeightKg", last.get("targetWeightKg")) })
            EditorBlockOps.writeSetsToMovement(m, sets, machine); onChanged() }) { Text("Añadir serie") }
        var female by remember(id) { mutableStateOf(if (m.has("weightFemaleKg") && !m.isNull("weightFemaleKg")) m.getDouble("weightFemaleKg").toString() else "") }
        var scale by remember(id) { mutableStateOf(m.optString("scaleAlternative")) }
        var notes by remember(id) { mutableStateOf(m.optString("notes")) }
        var dist by remember(id) { mutableStateOf(if (!machine && m.has("distanceMeters") && !m.isNull("distanceMeters")) m.optInt("distanceMeters").toString() else "") }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            var male by remember(id) { mutableStateOf(if (m.has("weightMaleKg") && !m.isNull("weightMaleKg")) m.getDouble("weightMaleKg").toString() else "") }
            if (!machine) OutlinedTextField(value = male, singleLine = true, label = { Text("Peso H (kg)") },
                modifier = Modifier.weight(1f).testTag("mv_male_${b}_$i"),
                onValueChange = { v -> male = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                    val p = dev.repera.domain.ReperaNumberFormat.parse(male)
                    if (p != null) {
                        m.put("weightMaleKg", p)
                        // Apple applyMovementWeightToEmptySets: solo series sin peso.
                        for (k in 0 until sets.length()) sets.getJSONObject(k).let { st ->
                            if (!st.has("targetWeightKg") || st.isNull("targetWeightKg")) st.put("targetWeightKg", p) }
                        EditorBlockOps.writeSetsToMovement(m, sets, machine); onChanged()
                    } else { m.remove("weightMaleKg"); onEdited() } })
            OutlinedTextField(value = female, singleLine = true, label = { Text("Peso M (kg)") },
                modifier = Modifier.weight(1f).testTag("mv_female_${b}_$i"),
                onValueChange = { v -> female = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                    val p = dev.repera.domain.ReperaNumberFormat.parse(female)
                    if (p != null) m.put("weightFemaleKg", p) else m.remove("weightFemaleKg"); onEdited() })
            if (!machine) OutlinedTextField(value = dist, singleLine = true, label = { Text("Metros") },
                modifier = Modifier.weight(1f).testTag("mv_dist_${b}_$i"),
                onValueChange = { v -> dist = v.filter { it.isDigit() }.take(4)
                    val p = dist.toIntOrNull()?.coerceIn(0, 5000)
                    if (p != null && p > 0) m.put("distanceMeters", p) else m.remove("distanceMeters"); onEdited() })
        }
        OutlinedTextField(value = scale, singleLine = true, label = { Text("Escala alternativa") },
            modifier = Modifier.fillMaxWidth().testTag("mv_scale_${b}_$i"),
            onValueChange = { scale = it; if (it.isEmpty()) m.remove("scaleAlternative") else m.put("scaleAlternative", it); onEdited() })
        OutlinedTextField(value = notes, singleLine = true, label = { Text("Notas") },
            modifier = Modifier.fillMaxWidth().testTag("mv_notes_${b}_$i"),
            onValueChange = { notes = it; if (it.isEmpty()) m.remove("notes") else m.put("notes", it); onEdited() })
        }
    }
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        TextButton(modifier = Modifier.testTag("mv_add_rest_$b"), onClick = { moves.put(EditorBlockOps.restMovement()); onChanged() }) { Text("Añadir REST") }
        var picking by remember { mutableStateOf(false) }
        TextButton(modifier = Modifier.testTag("mv_add_$b"), enabled = catalog.isNotEmpty(), onClick = { picking = true }) { Text("Añadir movimiento") }
        if (picking) {
            var q by remember { mutableStateOf("") }
            val n = remember(q) { foldForSearch(q) }
            val filtered = remember(q, catalog) { if (n.isBlank()) catalog else catalog.filter { foldForSearch(it.name).contains(n) } }
            AlertDialog(onDismissRequest = { picking = false }, title = { Text("Añadir movimiento") },
                text = { Column {
                    OutlinedTextField(value = q, onValueChange = { q = it }, singleLine = true,
                        label = { Text("Buscar en todo el catálogo") }, modifier = Modifier.fillMaxWidth().testTag("mv_search"))
                    androidx.compose.foundation.lazy.LazyColumn(Modifier.heightIn(max = 320.dp)) {
                        items(filtered.size, key = { filtered[it].id }) { idx ->
                            val e = filtered[idx]
                            TextButton(modifier = Modifier.fillMaxWidth().testTag("mv_pick_${e.id}"), onClick = {
                                picking = false
                                moves.put(org.json.JSONObject().put("id", java.util.UUID.randomUUID().toString())
                                    .put("exerciseId", e.id).put("name", e.name).put("reps", 10))
                                onChanged() }) { Text(e.name, modifier = Modifier.fillMaxWidth()) }
                        }
                    } } },
                confirmButton = {}, dismissButton = { TextButton(onClick = { picking = false }) { Text("Cancelar") } })
        }
    }
}


/** Fila reordenable por long-press (como `.draggable` de Apple). El arrastre solo mueve la fila
 *  visualmente (graphicsLayer, sin recomponer el contenido) y aplica UN reorden al soltar. */
@Composable
internal fun DragReorderItem(
    index: Int, heights: androidx.compose.runtime.snapshots.SnapshotStateMap<Int, Int>, count: Int,
    onDrop: (centerRootY: Float, target: Int) -> Unit,
    onBounds: (top: Float, bottom: Float) -> Unit = { _, _ -> },
    onMoveTo: ((target: Int) -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable (Modifier) -> Unit
) {
    var dy by remember { mutableStateOf(0f) }
    // Desplazamiento del SOLO dedo (sin la compensación de autoscroll). Es el que
    // determina destino y centro de drop: la compensación de scroll cancela el
    // movimiento del contenido y la fila queda siempre bajo el dedo.
    var dyFinger by remember { mutableStateOf(0f) }
    var top by remember { mutableStateOf(0f) }
    var bottom by remember { mutableStateOf(0f) }
    // Posición congelada al iniciar el arrastre. NO usar top/bottom durante el
    // gesto: si el autoscroll (o cualquier relayout) dispara onGloballyPositioned
    // a mitad de arrastre, positionInRoot ya incluye el translationY=dy y sumarle
    // dy otra vez desplaza el centro de drop miles de px por debajo del dedo.
    var dragTop by remember { mutableStateOf(0f) }
    var dragBottom by remember { mutableStateOf(0f) }
    val scroller = LocalDragAutoScroller.current
    var dragging by remember { mutableStateOf(false) }
    val density = androidx.compose.ui.platform.LocalDensity.current
    val windowH = androidx.compose.ui.platform.LocalConfiguration.current.screenHeightDp * density.density
    // Autoscroll continuo y acotado mientras dura el arrastre: el LaunchedEffect se cancela solo al
    // soltar/cancelar (dragging=false) o al salir de composición; no quedan corrutinas vivas.
    androidx.compose.runtime.LaunchedEffect(dragging, scroller) {
        if (!dragging || scroller == null) return@LaunchedEffect
        while (true) {
            val center = (dragTop + dragBottom) / 2f + dyFinger
            // Viewport REAL del contenedor; si aún no está medido, borde de ventana como último recurso.
            val vp = scroller.viewport() ?: (0f to windowH)
            val v = autoScrollSpeed(center, vp.first, vp.second, edgePx = 96f * density.density, maxPerFrame = 24f * density.density / 2f)
            if (v != 0f) {
                val consumed = scroller.by(v)
                // El contenido se mueve bajo la fila: compensar para que siga bajo el dedo.
                dy += consumed
            }
            androidx.compose.runtime.withFrameNanos { }
        }
    }
    var sizePx by remember { mutableStateOf(androidx.compose.ui.unit.IntSize.Zero) }
    val handle = Modifier.pointerInput(index, count) {
        detectDragGesturesAfterLongPress(
            onDragStart = { dragTop = top; dragBottom = bottom; dyFinger = 0f; dragging = true },
            onDrag = { change, amount -> change.consume(); dy += amount.y; dyFinger += amount.y },
            onDragEnd = {
                val target = dragTargetIndex(index, dyFinger, (0 until count).map { heights[it] ?: 0 })
                val center = (dragTop + dragBottom) / 2f + dyFinger
                dragging = false
                dy = 0f
                onDrop(center, target)
            },
            onDragCancel = { dragging = false; dy = 0f; dyFinger = 0f })
    }
    // Reordering must not depend on a long-press drag only. The actions carry an explicit
    // target INDEX (no row geometry), and exist only where the caller supplies onMoveTo.
    val moveActions = if (onMoveTo == null) emptyList() else moveActionTargets(index, count).map { (label, target) ->
        androidx.compose.ui.semantics.CustomAccessibilityAction(label) { onMoveTo(target); true }
    }
    // Arrastre: fondo blanco + sombra corta (no ancha) y esquinas redondeadas.
    val lifting = dragging || dy != 0f
    val liftShape = RoundedCornerShape(14.dp)
    Column(modifier
        .semantics { customActions = moveActions }
        .zIndex(if (lifting) 2f else 0f)
        .graphicsLayer {
            translationY = dy
            // Elevación baja → sombra más corta/local (antes 6f se veía muy ancha).
            shadowElevation = if (lifting) 2.5f else 0f
            shape = liftShape
            clip = lifting
            ambientShadowColor = androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.10f)
            spotShadowColor = androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.14f)
        }
        .then(
            if (lifting) Modifier
                .clip(liftShape)
                .background(androidx.compose.material3.MaterialTheme.colorScheme.surface)
            else Modifier
        )
        .onSizeChanged { heights[index] = it.height; sizePx = it }
        .onGloballyPositioned { c ->
            val p = c.positionInRoot().y
            top = p; bottom = p + c.size.height; onBounds(top, bottom)
        }) { content(handle) }
}

/** Accessible move actions for a row: label to explicit neighbouring index. Pure and testable. */
internal fun moveActionTargets(index: Int, count: Int): List<Pair<String, Int>> = buildList {
    if (index > 0 && index < count) add("Mover arriba" to index - 1)
    if (index in 0 until count - 1) add("Mover abajo" to index + 1)
}

/** Índice destino de un arrastre vertical (regla del punto medio sobre alturas reales). Pura y testeable. */
internal fun dragTargetIndex(from: Int, dy: Float, heights: List<Int>): Int {
    var target = from
    if (dy > 0) {
        var travelled = 0f
        for (j in from + 1 until heights.size) {
            if (dy >= travelled + heights[j] / 2f) target = j else break
            travelled += heights[j]
        }
    } else if (dy < 0) {
        var travelled = 0f
        for (j in from - 1 downTo 0) {
            if (-dy >= travelled + heights[j] / 2f) target = j else break
            travelled += heights[j]
        }
    }
    return target
}


/** Soltar un ítem: fuera de todo bloque = inválido (no cambia nada); mismo bloque = reorden por índice;
 *  otro bloque = moveItem con conversión (REST a fuerza o id sin resolver => rechazado sin quitar). */
internal fun handleItemDrop(
    blocks: org.json.JSONArray, geo: EditorGeometry, b: Int, itemId: String, itemIndex: Int,
    arr: org.json.JSONArray, centerY: Float, sameBlockTarget: Int,
    nameFor: (String) -> String, resolve: (org.json.JSONObject) -> String?, onChanged: () -> Unit
) {
    val tb = EditorBlockOps.dropBlockIndex(centerY, geo.blockBounds(blocks.length())) ?: return
    if (tb == b) {
        if (sameBlockTarget != itemIndex && EditorBlockOps.reorder(arr, itemIndex, sameBlockTarget)) onChanged()
        return
    }
    val before = EditorBlockOps.dropBeforeId(centerY, (geo.items[tb] ?: emptyMap<String, Pair<Float, Float>>()).toList())
    if (EditorBlockOps.moveItem(blocks, b, itemId, tb, before, nameFor, resolve)) onChanged()
}


/** Deslizar para quitar (OGSwipeDeleteButton de Apple). El estado va ligado al id para no reutilizarse con otra fila. */
@Composable
internal fun SwipeRemove(id: String, tag: String, onRemove: () -> Unit, content: @Composable () -> Unit) {
    androidx.compose.runtime.key(id) {
        val current by androidx.compose.runtime.rememberUpdatedState(onRemove)
        val st = androidx.compose.material3.rememberSwipeToDismissBoxState(confirmValueChange = { v ->
            if (v == androidx.compose.material3.SwipeToDismissBoxValue.EndToStart) { current(); true } else false })
        androidx.compose.material3.SwipeToDismissBox(state = st, enableDismissFromStartToEnd = false,
            modifier = Modifier.testTag(tag),
            backgroundContent = { Text("Quitar", color = MaterialTheme.colorScheme.error,
                modifier = Modifier.fillMaxWidth().padding(16.dp)) }) {
            // Fondo opaco: sin él el "Quitar" rojo trasluce entre los huecos
            // de la fila en reposo (visto en captura de CI 25/10).
            androidx.compose.material3.Surface { content() }
        }
    }
}
