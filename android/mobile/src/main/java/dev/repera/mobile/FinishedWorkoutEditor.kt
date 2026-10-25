package dev.repera.mobile

import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.ui.zIndex
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.foundation.layout.padding
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
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
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
    // Borrador del CONTENIDO: copia JSON con ids; solo se escribe al Guardar.
    val blocks = remember(workout.id) {
        workout.editableBlocksJson?.let { runCatching { org.json.JSONArray(it) }.getOrNull() }
    }
    var contentVersion by remember(workout.id) { mutableIntStateOf(0) }
    var contentDirty by remember(workout.id) { mutableStateOf(false) }

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
        if (blocks != null) {
            Text("Contenido", style = MaterialTheme.typography.titleMedium)
            key(contentVersion) {
                FinishedContentEditor(blocks, exerciseCatalog, onEdited = { contentDirty = true }) { contentDirty = true; contentVersion++ }
            }
        }
        OutlinedTextField(value = notes, onValueChange = { notes = it },
            label = { Text("Notas: cómo te sentiste, molestias…") }, minLines = 2, maxLines = 5,
            modifier = Modifier.fillMaxWidth().testTag("edit_notes"))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(enabled = !busy, modifier = Modifier.testTag("edit_save"), onClick = {
                onSave(WorkoutRepository.FinishedWorkoutEdit(
                    title = title, startedAtIso = startIso, finishedAtIso = endIso,
                    notes = notes, pinEdited = pinEdited, pin = pin,
                    blocksJson = if (contentDirty) blocks?.toString() else null))
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

/** Editor de bloques de un entreno terminado: reordenar, quitar, añadir
 *  ejercicio y editar series (reps / kg / RIR). Los bloques WOD se muestran sin
 *  edición (Android no tiene editor de movimientos). Opera sobre el borrador. */
@Composable
private fun FinishedContentEditor(
    blocks: org.json.JSONArray,
    catalog: List<ExerciseEntry>,
    onEdited: () -> Unit,
    onChanged: () -> Unit
) {
    val nameById = remember(catalog) { catalog.associate { it.id to it.name } }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (b in 0 until blocks.length()) {
            val block = blocks.getJSONObject(b)
            var title by remember(block.optString("id")) { mutableStateOf(block.optString("title")) }
            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                OutlinedTextField(value = title, singleLine = true, label = { Text("Bloque ${b + 1}") },
                    modifier = Modifier.weight(1f).testTag("block_title_$b"),
                    onValueChange = { title = it; block.put("title", it); onEdited() })
                TextButton(enabled = b > 0, modifier = Modifier.testTag("block_up_$b"), onClick = {
                    EditorBlockOps.moveBlock(blocks, b, b - 1); onChanged() }) { Text("↑") }
                TextButton(enabled = b < blocks.length() - 1, modifier = Modifier.testTag("block_down_$b"), onClick = {
                    EditorBlockOps.moveBlock(blocks, b, b + 1); onChanged() }) { Text("↓") }
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
                WodMovementsEditor(blocks, b, nameById, catalog, onEdited, onChanged)
                continue
            }
            val items = block.optJSONArray("exercises") ?: org.json.JSONArray().also { block.put("exercises", it) }
            val exHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                DragReorderItem(i, exHeights, items.length(), { f, t -> EditorBlockOps.reorder(items, f, t); onChanged() }) { handle ->
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Text("⠿", modifier = handle.testTag("ex_drag_${b}_$i").padding(8.dp))
                    Text(item.optString("exerciseId").let { id ->
                        if (id.startsWith(EditorBlockOps.PENDING_PREFIX)) id.removePrefix(EditorBlockOps.PENDING_PREFIX) + " (nuevo, se crea al guardar)"
                        else nameById[id] ?: "Ejercicio" },
                        style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                    TextButton(enabled = i > 0, modifier = Modifier.testTag("ex_up_${b}_$i"), onClick = {
                        swap(items, i, i - 1); onChanged() }) { Text("↑") }
                    TextButton(enabled = i < items.length() - 1, modifier = Modifier.testTag("ex_down_${b}_$i"), onClick = {
                        swap(items, i, i + 1); onChanged() }) { Text("↓") }
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
                val sets = item.optJSONArray("plannedSets") ?: org.json.JSONArray().also { item.put("plannedSets", it) }
                for (s in 0 until sets.length()) {
                    val set = sets.getJSONObject(s)
                    var reps by remember { mutableStateOf(set.optInt("targetReps").toString()) }
                    var kg by remember { mutableStateOf(
                        if (set.has("targetWeightKg") && !set.isNull("targetWeightKg"))
                            set.getDouble("targetWeightKg").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() }
                        else "") }
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        Text("Serie ${s + 1}", modifier = Modifier.width(64.dp))
                        OutlinedTextField(value = reps, label = { Text("Reps") }, singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_reps_${b}_${i}_$s"),
                            onValueChange = { v ->
                                reps = v.filter { it.isDigit() }.take(4)
                                set.put("targetReps", reps.toIntOrNull() ?: 0)
                                onEdited()
                            })
                        OutlinedTextField(value = kg, label = { Text("Kg") }, singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_kg_${b}_${i}_$s"),
                            onValueChange = { v ->
                                kg = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                                val parsed = kg.replace(',', '.').toDoubleOrNull()
                                if (parsed != null) set.put("targetWeightKg", parsed) else set.remove("targetWeightKg")
                                onEdited()
                            })
                        var rir by remember { mutableStateOf(
                            if (set.has("targetRir") && !set.isNull("targetRir"))
                                set.getDouble("targetRir").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() }
                            else "") }
                        OutlinedTextField(value = rir, label = { Text("RIR") }, singleLine = true,
                            modifier = Modifier.weight(1f).testTag("set_rir_${b}_${i}_$s"),
                            onValueChange = { v ->
                                rir = v.filter { it.isDigit() || it == '.' || it == ',' }.take(4)
                                val parsed = rir.replace(',', '.').toDoubleOrNull()
                                if (parsed != null && parsed in 0.0..10.0) set.put("targetRir", parsed) else set.remove("targetRir")
                                onEdited()
                            })
                        TextButton(modifier = Modifier.testTag("set_remove_${b}_${i}_$s"),
                            onClick = { sets.remove(s); onChanged() }) { Text("×") }
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
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(modifier = Modifier.testTag("block_add_strength"), onClick = {
                blocks.put(EditorBlockOps.newBlock("strength", blocks.length() + 1)); onChanged() }) { Text("Añadir bloque de fuerza") }
            TextButton(modifier = Modifier.testTag("block_add_wod"), onClick = {
                blocks.put(EditorBlockOps.newBlock("wod", blocks.length() + 1, "amrap")); onChanged() }) { Text("Añadir bloque WOD") }
        }
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
    onEdited: () -> Unit, onChanged: () -> Unit
) {
    val block = blocks.getJSONObject(b)
    val moves = block.optJSONArray("movements") ?: org.json.JSONArray().also { block.put("movements", it) }
    val mvHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
    for (i in 0 until moves.length()) {
        val m = moves.getJSONObject(i)
        val id = m.optString("id")
        DragReorderItem(i, mvHeights, moves.length(), { f, t -> EditorBlockOps.reorder(moves, f, t); onChanged() }) { handle ->
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Text("⠿", modifier = handle.testTag("mv_drag_${b}_$i").padding(8.dp))
            Text(if (m.optBoolean("isRest")) "REST" else m.optString("name"),
                style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
            TextButton(enabled = i > 0, modifier = Modifier.testTag("mv_up_${b}_$i"), onClick = {
                EditorBlockOps.moveItem(blocks, b, id, b, moves.getJSONObject(i - 1).optString("id"), { "" }, { null }); onChanged() }) { Text("↑") }
            TextButton(enabled = i < moves.length() - 1, modifier = Modifier.testTag("mv_down_${b}_$i"), onClick = {
                val next = if (i + 2 < moves.length()) moves.getJSONObject(i + 2).optString("id") else null
                EditorBlockOps.moveItem(blocks, b, id, b, next, { "" }, { null }); onChanged() }) { Text("↓") }
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
        val machine = m.has("calories") && !m.isNull("calories") || m.has("distanceMeters") && !m.isNull("distanceMeters") && !m.has("reps")
        val sets = m.optJSONArray("explicitPlannedSets")?.takeIf { it.length() > 0 }
            ?: CompletedWorkoutEditing.derivedSetsFor(block, m).also { m.put("explicitPlannedSets", it) }
        for (s in 0 until sets.length()) {
            val set = sets.getJSONObject(s)
            var reps by remember(id, set.optString("id")) { mutableStateOf(set.optInt("targetReps").toString()) }
            var kg by remember(id, set.optString("id")) { mutableStateOf(
                if (set.has("targetWeightKg") && !set.isNull("targetWeightKg")) set.getDouble("targetWeightKg").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() } else "") }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Text("Serie ${s + 1}", modifier = Modifier.width(64.dp))
                OutlinedTextField(value = reps, singleLine = true,
                    label = { Text(if (m.has("calories") && !m.isNull("calories")) "Cal" else if (machine) "m" else "Reps") },
                    modifier = Modifier.weight(1f).testTag("mv_set_reps_${b}_${i}_$s"),
                    onValueChange = { v -> reps = v.filter { it.isDigit() }.take(4)
                        set.put("targetReps", (reps.toIntOrNull() ?: 1).coerceAtLeast(1))
                        EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                if (!machine) OutlinedTextField(value = kg, singleLine = true, label = { Text("Kg") },
                    modifier = Modifier.weight(1f).testTag("mv_set_kg_${b}_${i}_$s"),
                    onValueChange = { v -> kg = v.filter { it.isDigit() || it == '.' || it == ',' }.take(7)
                        val parsed = kg.replace(',', '.').toDoubleOrNull()
                        if (parsed != null) set.put("targetWeightKg", parsed) else set.remove("targetWeightKg")
                        EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                if (!machine) {
                    var rir by remember(id, set.optString("id")) { mutableStateOf(
                        if (set.has("targetRir") && !set.isNull("targetRir")) set.getDouble("targetRir").let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() } else "") }
                    OutlinedTextField(value = rir, singleLine = true, label = { Text("RIR") },
                        modifier = Modifier.weight(1f).testTag("mv_set_rir_${b}_${i}_$s"),
                        onValueChange = { v -> rir = v.filter { it.isDigit() || it == '.' || it == ',' }.take(4)
                            val p = rir.replace(',', '.').toDoubleOrNull()
                            if (p != null && p in 0.0..10.0) set.put("targetRir", p) else set.remove("targetRir")
                            EditorBlockOps.writeSetsToMovement(m, sets, machine); onEdited() })
                }
                TextButton(enabled = sets.length() > 1, modifier = Modifier.testTag("mv_set_remove_${b}_${i}_$s"),
                    onClick = { sets.remove(s); EditorBlockOps.writeSetsToMovement(m, sets, machine); onChanged() }) { Text("×") }
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
                    val p = male.replace(',', '.').toDoubleOrNull()
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
                    val p = female.replace(',', '.').toDoubleOrNull()
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
    onReorder: (Int, Int) -> Unit, content: @Composable (Modifier) -> Unit
) {
    var dy by remember { mutableStateOf(0f) }
    val handle = Modifier.pointerInput(index, count) {
        detectDragGesturesAfterLongPress(
            onDragStart = {},
            onDrag = { change, amount -> change.consume(); dy += amount.y },
            onDragEnd = {
                val target = dragTargetIndex(index, dy, (0 until count).map { heights[it] ?: 0 })
                dy = 0f
                if (target != index) onReorder(index, target)
            },
            onDragCancel = { dy = 0f })
    }
    Column(Modifier
        .zIndex(if (dy != 0f) 1f else 0f)
        .graphicsLayer { translationY = dy }
        .onSizeChanged { heights[index] = it.height }) { content(handle) }
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
