package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.ui.platform.testTag
import org.json.JSONObject
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import dev.repera.domain.WodFormat

/** Editor de contenido de rutina: bloques (secciones), formatos y movimientos.
 *  Multi-bloque: buy-in / trabajo / cash-out se componen como bloques
 *  separados, igual que en iOS. */
@Composable
fun RoutineBlocksEditorScreen(
    routine: RoutineEntry,
    exercises: List<ExerciseEntry>,
    busy: Boolean,
    onReplace: (List<RoutineBlockDraft>) -> Unit,
    onBack: () -> Unit,
    loadGuideProvider: (exerciseId: String, targetReps: Int, targetRir: Double?) ->
        LoadGuide? = { _, _, _ -> null },
    importableRoutines: List<RoutineEntry> = emptyList(),
    /** Como DayEditorView: al elegir una plantilla con título vacío/«Entreno»/«Nuevo entreno», el título pasa a ser el de la
     *  plantilla. Se notifica justo antes de onReplace (Guardar); nada se persiste antes. */
    onTitleSuggested: (String) -> Unit = {}
) {
    var suggestedTitle by remember(routine.id) { mutableStateOf<String?>(null) }
    val nameById = remember(exercises) { exercises.associate { it.id to it.name } }
    val blocks = remember(routine.id) {
        mutableStateListOf<BlockDraftUi>().apply {
            if (routine.blocks.isEmpty()) add(BlockDraftUi())
            else routine.blocks.forEach { add(BlockDraftUi(it)) }
        }
    }
    var error by remember(routine.id) { mutableStateOf<String?>(null) }

    val scrollState = rememberScrollState()
    val geo = remember(routine.id) { EditorGeometry() }
    ProvideScrollDragAutoScroll(scrollState) {
    Column(modifier = Modifier.verticalScroll(scrollState).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack, enabled = !busy) { Text("Volver") }
            Spacer(Modifier.weight(1f))
            TextButton(onClick = {
                val drafts = mutableListOf<RoutineBlockDraft>()
                error = null
                for (block in blocks) {
                    val parsed = block.toDraft() ?: run {
                        error = "Revisa los campos numéricos de «" +
                            block.title.ifBlank { "bloque" } + "»"
                        return@TextButton
                    }
                    drafts.add(parsed)
                }
                suggestedTitle?.let(onTitleSuggested)
                onReplace(drafts)
            }, enabled = !busy) { Text("Guardar") }
        }
        Text("Contenido de «" + routine.title + "»",
            style = MaterialTheme.typography.titleLarge)
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

        val blockHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
        blocks.forEachIndexed { index, block ->
            DragReorderItem(index, blockHeights, blocks.size,
                onDrop = { _, t -> if (t != index) { val moved = blocks.removeAt(index); blocks.add(t, moved) } },
                onBounds = { top, bottom -> geo.blocks[index] = top to bottom }) { handle ->
                BlockEditorCard(
                    block = block,
                    nameById = nameById,
                    exercises = exercises,
                    loadGuideProvider = loadGuideProvider,
                    onRemove = if (blocks.size > 1) ({ blocks.removeAt(index) }) else null,
                    onBlockUp = if (index > 0) ({ val m = blocks.removeAt(index); blocks.add(index - 1, m) }) else null,
                    onBlockDown = if (index < blocks.size - 1) ({ val m = blocks.removeAt(index); blocks.add(index + 1, m) }) else null,
                    handle = handle,
                    moveTargets = blocks.mapIndexedNotNull { ti, tb ->
                        if (ti == index) null else ti to tb.title.ifBlank { "Bloque ${ti + 1}" } },
                    onMoveEntry = { entryIndex, targetIndex ->
                        error = PlanEntryMoves.move(blocks, index, entryIndex, targetIndex, nameById, exercises)
                    },
                    onEntryBounds = { ei, top, bottom -> geo.items.getOrPut(index) { mutableMapOf() }[ei.toString()] = top to bottom },
                    onEntryDrop = { ei, centerY, sameTarget ->
                        // Soltar fuera de todo bloque = inválido: no cambia nada. Otro bloque = misma conversión que "Mover".
                        val tb = EditorBlockOps.dropBlockIndex(centerY, geo.blockBounds(blocks.size))
                        if (tb != null) {
                            if (tb == index) {
                                if (sameTarget != ei) { val moved = block.entries.removeAt(ei); block.entries.add(sameTarget, moved) }
                            } else {
                                val n = blocks[tb].entries.size
                                val before = EditorBlockOps.dropBeforeId(centerY,
                                    (geo.items[tb] ?: emptyMap<String, Pair<Float, Float>>()).filterKeys { (it.toIntOrNull() ?: Int.MAX_VALUE) < n }.toList())
                                error = PlanEntryMoves.move(blocks, index, ei, tb, nameById, exercises, before?.toIntOrNull())
                            }
                        }
                    }
                )
            }
        }
        TextButton(onClick = { blocks.add(BlockDraftUi()) }, enabled = !busy) {
            Text("Añadir bloque")
        }
        // Equivalente de «Elegir WOD» y «Añadir rutina» de DayEditorView (Apple).
        var showWods by remember { mutableStateOf(false) }
        var showRoutines by remember { mutableStateOf(false) }
        TextButton(modifier = Modifier.testTag("plan_pick_wod"), onClick = { showWods = true }, enabled = !busy) { Text("Elegir WOD") }
        val importable = importableRoutines.filter { it.id != routine.id && it.blocks.isNotEmpty() }
        if (importable.isNotEmpty())
            TextButton(modifier = Modifier.testTag("plan_add_routine"), onClick = { showRoutines = true }, enabled = !busy) { Text("Añadir rutina") }
        if (showRoutines) androidx.compose.material3.AlertDialog(
            onDismissRequest = { showRoutines = false },
            confirmButton = { TextButton(onClick = { showRoutines = false }) { Text("Cancelar") } },
            title = { Text("Añadir rutina") },
            text = { Column(Modifier.verticalScroll(rememberScrollState())) {
                Text("Se copian los bloques; el título y el día de esta rutina no cambian.", style = MaterialTheme.typography.bodySmall)
                importable.forEach { src ->
                    TextButton(modifier = Modifier.testTag("plan_import_${src.id}"), onClick = {
                        src.blocks.forEach { blocks.add(BlockDraftUi(EditorBlockOps.duplicateBlockInfo(it))) }
                        showRoutines = false
                    }) { Text(src.title + " · " + src.blocks.size + " bloques") }
                } } })
        if (showWods) {
            var query by remember { mutableStateOf("") }
            androidx.compose.material3.AlertDialog(
                onDismissRequest = { showWods = false },
                confirmButton = { TextButton(onClick = { showWods = false }) { Text("Cancelar") } },
                title = { Text("Elegir WOD") },
                text = { Column {
                    OutlinedTextField(value = query, onValueChange = { query = it }, singleLine = true,
                        label = { Text("Buscar") }, modifier = Modifier.fillMaxWidth().testTag("plan_wod_search"))
                    androidx.compose.foundation.lazy.LazyColumn(Modifier.heightIn(max = 360.dp)) {
                        items(dev.repera.domain.CatalogWods.search(query).size) { i ->
                            val t = dev.repera.domain.CatalogWods.search(query)[i]
                            TextButton(modifier = Modifier.testTag("plan_wod_pick_${t.id}"), onClick = {
                                val info = EditorBlockOps.templateToBlockInfo(t, exercises)
                                blocks.add(BlockDraftUi(info)); error = null
                                val cur = routine.title.trim()
                                if (suggestedTitle == null && (cur.isEmpty() || cur == "Entreno" || cur == "Nuevo entreno"))
                                    suggestedTitle = t.name
                                showWods = false
                            }) { Text(t.name + " · " + t.formatLabel) }
                        } } } })
        }
    }
    }
}

private val blockFormats = listOf(
    "strength", "amrap", "forTime", "emom", "tabata", "circuit", "chipper",
    "afap", "ladder", "deathBy", "partner", "roundsForQuality", "maxEffort",
    "buyInCashOut"
)

private fun formatLabel(wire: String): String = when (wire) {
    "strength" -> "Fuerza"
    else -> WodFormat.fromWire(wire)?.displayName ?: wire
}

private class EntryUi(val exerciseId: String, name: String, quantity: Int,
                      sets: Int, weightKg: Double?,
                      planned: List<PlannedSetDraft>? = null,
                      val itemId: String? = null, sourceJson: String? = null) {
    var sourceJson by mutableStateOf(sourceJson)
    /** Unidad de cardio elegida (null = sin tocar). */
    var unit by mutableStateOf<String?>(null)
    var name by mutableStateOf(name)
    var quantity by mutableStateOf(quantity.toString())
    var sets by mutableStateOf(sets.toString())
    var weight by mutableStateOf(weightKg?.toString() ?: "")
    /** Editor por serie (fuerza, paridad PlannedSet iOS). Se inicializa con
     *  las series existentes (targetRir incluido si la rutina lo trae) y al
     *  guardar sustituye a quantity/sets/weight uniformes. */
    val plannedSets = mutableStateListOf<PlannedSetDraft>().apply {
        val base = planned ?: (1..sets.coerceIn(1, 30)).map {
            PlannedSetDraft(targetReps = quantity, targetWeightKg = weightKg)
        }
        addAll(base)
    }
    var setsExpanded by mutableStateOf(false)
    /** Valores iniciales de los campos uniformes: si no se tocan, las series
     *  originales (ids, RIR, no uniformes) se escriben tal cual. */
    val initialUniform = Triple(quantity.toString(), sets.toString(), weightKg?.toString() ?: "")
    val hadPlanned = planned != null
    val untouchedUniform: Boolean
        get() = hadPlanned && Triple(quantity, sets, weight) == initialUniform
}

private class BlockDraftUi(info: RoutineBlockInfo? = null) {
    val blockId: String? = info?.id
    val sourceJson: String? = info?.sourceJson
    var title by mutableStateOf(info?.title ?: "")
    var format by mutableStateOf(info?.format ?: "strength")
    var timeCap by mutableStateOf((info?.timeCapMinutes ?: 12).toString())
    var rounds by mutableStateOf((info?.rounds ?: 1).toString())
    var interval by mutableStateOf((info?.emomIntervalSeconds ?: 60).toString())
    var work by mutableStateOf((info?.workSeconds ?: 20).toString())
    var rest by mutableStateOf((info?.restSeconds ?: 10).toString())
    var ladder by mutableStateOf(info?.ladderScheme?.joinToString("-") ?: "")
    val entries = mutableStateListOf<EntryUi>().apply {
        info?.entries?.forEach {
            add(EntryUi(it.exerciseId, it.name, it.quantity, it.sets, it.weightKg,
                it.plannedSets, it.id, it.sourceJson))
        }
    }

    fun toDraft(): RoutineBlockDraft? {
        val cap = timeCap.toIntOrNull() ?: return null
        val rds = rounds.toIntOrNull() ?: return null
        val intv = interval.toIntOrNull() ?: return null
        val wk = work.toIntOrNull() ?: return null
        val rst = rest.toIntOrNull() ?: return null
        val scheme = if (format == "ladder" && ladder.isNotBlank()) {
            ladder.split("-", ",", " ").filter { it.isNotBlank() }
                .map { it.toIntOrNull() ?: return null }
        } else null
        val parsed = entries.map { entry ->
            val base = RoutineDraftEntry(
                itemId = entry.itemId, sourceJson = entry.sourceJson, quantityUnit = entry.unit,
                exerciseId = entry.exerciseId,
                quantity = entry.quantity.toIntOrNull() ?: return null,
                sets = entry.sets.toIntOrNull() ?: return null,
                weightKg = if (entry.weight.isBlank()) null
                    else entry.weight.replace(',', '.').toDoubleOrNull() ?: return null
            )
            if (format == "strength" && (entry.setsExpanded || entry.untouchedUniform))
                base.copy(plannedSets = entry.plannedSets.toList())
            else base
        }
        return RoutineBlockDraft(
            blockId = blockId, sourceJson = sourceJson,
            title = title.trim(), format = format, entries = parsed,
            timeCapMinutes = cap, rounds = rds, emomIntervalSeconds = intv,
            workSeconds = wk, restSeconds = rst, ladderScheme = scheme
        )
    }
}

@Composable
private fun BlockEditorCard(
    block: BlockDraftUi,
    nameById: Map<String, String>,
    exercises: List<ExerciseEntry>,
    loadGuideProvider: (String, Int, Double?) -> LoadGuide?,
    onRemove: (() -> Unit)?,
    handle: Modifier = Modifier,
    moveTargets: List<Pair<Int, String>> = emptyList(),
    onMoveEntry: (Int, Int) -> Unit = { _, _ -> },
    onEntryBounds: (Int, Float, Float) -> Unit = { _, _, _ -> },
    onEntryDrop: (entryIndex: Int, centerY: Float, sameBlockTarget: Int) -> Unit = { _, _, _ -> },
    onBlockUp: (() -> Unit)? = null,
    onBlockDown: (() -> Unit)? = null
) {
    val entryHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("⠿", modifier = handle.testTag("plan_block_drag").padding(8.dp))
                OutlinedTextField(
                    value = block.title,
                    onValueChange = { block.title = it },
                    label = { Text("Título del bloque") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                TextButton(enabled = onBlockUp != null, modifier = Modifier.testTag("plan_block_up"), onClick = { onBlockUp?.invoke() }) { Text("↑") }
                TextButton(enabled = onBlockDown != null, modifier = Modifier.testTag("plan_block_down"), onClick = { onBlockDown?.invoke() }) { Text("↓") }
                onRemove?.let {
                    TextButton(onClick = it) { Text("Quitar") }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    blockFormats.chunked(4).forEach { rowFormats ->
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            rowFormats.forEach { wire ->
                                FilterChip(
                                    selected = block.format == wire,
                                    onClick = { block.format = wire },
                                    label = { Text(formatLabel(wire)) }
                                )
                            }
                        }
                    }
                }
            }
            when (block.format) {
                "amrap", "afap", "chipper", "buyInCashOut", "maxEffort" ->
                    NumberRow(block, "Minutos (cap)" to "timeCap")
                "forTime", "roundsForQuality", "partner" ->
                    NumberRow(block, "Minutos (cap)" to "timeCap", "Rondas" to "rounds")
                "emom", "deathBy" ->
                    NumberRow(block, "Rondas" to "rounds", "Intervalo (s)" to "interval")
                "tabata" ->
                    NumberRow(block, "Rondas" to "rounds", "Trabajo (s)" to "work",
                        "Descanso (s)" to "rest")
                "circuit" ->
                    NumberRow(block, "Minutos (cap)" to "timeCap", "Rondas" to "rounds",
                        "Descanso (s)" to "rest")
                "ladder" -> {
                    NumberRow(block, "Minutos (cap)" to "timeCap")
                    OutlinedTextField(
                        value = block.ladder,
                        onValueChange = { block.ladder = it },
                        label = { Text("Esquema (21-15-9)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
            block.entries.forEachIndexed { index, entry ->
              androidx.compose.runtime.key(entry) {
                DragReorderItem(index, entryHeights, block.entries.size,
                    onDrop = { cy, t -> onEntryDrop(index, cy, t) },
                    onBounds = { top, bottom -> onEntryBounds(index, top, bottom) }) { entryHandle ->
                  // Deslizar para quitar (OGSwipeDeleteButton de Apple); el arrastre sigue siendo por pulsación larga.
                  val swipe = androidx.compose.material3.rememberSwipeToDismissBoxState(
                      confirmValueChange = { v ->
                          if (v == androidx.compose.material3.SwipeToDismissBoxValue.EndToStart) {
                              block.entries.remove(entry); true } else false })
                  androidx.compose.material3.SwipeToDismissBox(state = swipe, enableDismissFromStartToEnd = false,
                      modifier = Modifier.testTag("plan_entry_swipe"),
                      backgroundContent = { Text("Quitar", color = MaterialTheme.colorScheme.error,
                          modifier = Modifier.fillMaxWidth().padding(16.dp)) }) {
                    EntryEditorRow(
                        entry = entry,
                        resolvedName = entry.name.ifBlank {
                            nameById[entry.exerciseId] ?: "Ejercicio" },
                        isStrength = block.format == "strength",
                        unitChoices = exercises.firstOrNull { it.id == entry.exerciseId }?.let { ex ->
                            dev.repera.domain.AppleCardioUnits.allowsCalorieOrDistanceToggle(ex.name, ex.equipment) } == true,
                        loadGuideProvider = loadGuideProvider,
                        onRemove = { block.entries.remove(entry) },
                        handle = entryHandle,
                        moveTargets = moveTargets,
                        onMove = { target -> onMoveEntry(index, target) },
                        onUp = if (index > 0) ({ val m = block.entries.removeAt(index); block.entries.add(index - 1, m) }) else null,
                        onDown = if (index < block.entries.size - 1) ({ val m = block.entries.removeAt(index); block.entries.add(index + 1, m) }) else null
                    )
                  }
                }
              }
            }
            if (block.format != "strength") {
                TextButton(modifier = Modifier.testTag("plan_add_rest"), onClick = {
                    val rest = EditorBlockOps.restMovement()
                    block.entries.add(EntryUi("", "REST", 1, 1, null, null, rest.getString("id"), rest.toString()))
                }) { Text("Añadir REST") }
            }
            AddExerciseRow(exercises = exercises,
                excluded = block.entries.map { it.exerciseId }.toSet()) { chosen ->
                block.entries.add(EntryUi(chosen.id, chosen.name, 10, 3, null))
            }
        }
    }
}

@Composable
private fun NumberRow(block: BlockDraftUi, vararg fields: Pair<String, String>) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        fields.forEach { (label, key) ->
            val (value, setter) = when (key) {
                "timeCap" -> block.timeCap to { v: String -> block.timeCap = v }
                "rounds" -> block.rounds to { v: String -> block.rounds = v }
                "interval" -> block.interval to { v: String -> block.interval = v }
                "work" -> block.work to { v: String -> block.work = v }
                else -> block.rest to { v: String -> block.rest = v }
            }
            OutlinedTextField(
                value = value, onValueChange = setter,
                label = { Text(label) }, singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun EntryEditorRow(
    entry: EntryUi,
    resolvedName: String,
    isStrength: Boolean,
    loadGuideProvider: (String, Int, Double?) -> LoadGuide?,
    onRemove: () -> Unit,
    handle: Modifier = Modifier,
    moveTargets: List<Pair<Int, String>> = emptyList(),
    onMove: (Int) -> Unit = {},
    unitChoices: Boolean = false,
    onUp: (() -> Unit)? = null,
    onDown: (() -> Unit)? = null
) {
    val isRest = entry.sourceJson?.let { runCatching { JSONObject(it).optBoolean("isRest") }.getOrDefault(false) } == true
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("⠿", modifier = handle.testTag("plan_entry_drag").padding(8.dp))
            Text(resolvedName, style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.weight(1f))
            var moving by remember { mutableStateOf(false) }
            if (moveTargets.isNotEmpty() && !(isRest && moveTargets.all { false })) {
                TextButton(modifier = Modifier.testTag("plan_entry_move"), onClick = { moving = true }) { Text("Mover") }
                DropdownMenu(expanded = moving, onDismissRequest = { moving = false }) {
                    moveTargets.forEach { (ti, title) ->
                        DropdownMenuItem(text = { Text(title) }, modifier = Modifier.testTag("plan_entry_move_to_$ti"),
                            onClick = { moving = false; onMove(ti) })
                    }
                }
            }
            TextButton(enabled = onUp != null, modifier = Modifier.testTag("plan_entry_up"), onClick = { onUp?.invoke() }) { Text("↑") }
            TextButton(enabled = onDown != null, modifier = Modifier.testTag("plan_entry_down"), onClick = { onDown?.invoke() }) { Text("↓") }
            TextButton(onClick = onRemove) { Text("Quitar") }
        }
        if (isRest) {
            var secs by remember(entry.itemId) { mutableStateOf(
                runCatching { JSONObject(entry.sourceJson!!).optInt("restSeconds", 60).toString() }.getOrDefault("60")) }
            OutlinedTextField(value = secs, singleLine = true, label = { Text("Segundos de descanso") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth().testTag("plan_rest_seconds"),
                onValueChange = { v ->
                    secs = v.filter { it.isDigit() }.take(3)
                    entry.sourceJson = JSONObject(entry.sourceJson!!)
                        .put("restSeconds", (secs.toIntOrNull() ?: 60).coerceIn(15, 300)).toString()
                })
            return@Column
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = entry.quantity,
                onValueChange = { entry.quantity = it },
                label = { Text(if (isStrength) "Reps" else "Cantidad") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.weight(1f)
            )
            if (isStrength) {
                OutlinedTextField(
                    value = entry.sets,
                    onValueChange = { entry.sets = it },
                    label = { Text("Series") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = entry.weight,
                    onValueChange = { entry.weight = it },
                    label = { Text("Peso kg (opc.)") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.weight(1f)
                )
            }
        }
        if (unitChoices) {
            // Picker "Unidad de cardio" (Apple): segmentado Calorías / Metros.
            val src = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            val current = entry.unit ?: src?.optString("quantityUnit")?.takeIf { it == "calories" || it == "meters" }
                ?: if (src?.has("distanceMeters") == true && !src.isNull("distanceMeters")) "meters" else "calories"
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                androidx.compose.material3.FilterChip(selected = current == "calories", onClick = { entry.unit = "calories" },
                    label = { Text("Calorías") }, modifier = Modifier.testTag("plan_unit_calories"))
                androidx.compose.material3.FilterChip(selected = current == "meters", onClick = { entry.unit = "meters" },
                    label = { Text("Metros") }, modifier = Modifier.testTag("plan_unit_meters"))
            }
        }
        if (!isStrength) WodMovementDetails(entry)
        if (isStrength) {
            TextButton(onClick = { entry.setsExpanded = !entry.setsExpanded }) {
                Text(if (entry.setsExpanded) "Cerrar series"
                    else "Editar series una a una")
            }
            if (entry.setsExpanded) {
                // Port de RoutineExerciseEditor (PlanView iOS): guía de carga
                // + filas KG/Reps/RIR por serie. El RIR ausente se muestra
                // vacío; la guía lo etiqueta «asumido», nunca confirmado.
                val reference = entry.plannedSets.firstOrNull()
                val guide = remember(entry.exerciseId, reference?.targetReps,
                    reference?.targetRir) {
                    loadGuideProvider(entry.exerciseId,
                        reference?.targetReps ?: 8, reference?.targetRir)
                }
                if (guide != null) {
                    Text("Referencia", style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    LoadGuideSection(guide) { kg ->
                        val last = guide.lastSession
                        val scaled = last?.let {
                            ExerciseLoadGuide.scaledPlannedSets(kg, it.sets,
                                guide.incrementKg, guide.effectiveRir)
                        }
                        entry.plannedSets.clear()
                        if (scaled != null) {
                            entry.plannedSets.addAll(scaled)
                        } else {
                            // Sin sesión previa: fijar el kg en las series
                            // actuales (bucle final de applySuggestedLoad iOS).
                            entry.plannedSets.addAll(guide.let { g ->
                                (1..(entry.sets.toIntOrNull() ?: 3).coerceIn(1, 30))
                                    .map { PlannedSetDraft(
                                        targetReps = g.targetReps,
                                        targetWeightKg = kg,
                                        targetRir = reference?.targetRir
                                            ?: g.effectiveRir) }
                            })
                        }
                    }
                    if (guide.lastSession != null) {
                        TextButton(onClick = {
                            entry.plannedSets.clear()
                            entry.plannedSets.addAll(
                                ExerciseLoadGuide.copyLastSession(
                                    guide.lastSession.sets))
                        }) { Text("Copiar última sesión") }
                    }
                    Text("Aplicar escala la última sesión al kg sugerido (misma progresión, reps y RIR).",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("KG", style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.weight(1f))
                    Text("Reps", style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.weight(1f))
                    Text("RIR", style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.weight(1f))
                    Spacer(Modifier.weight(0.4f))
                }
                entry.plannedSets.forEachIndexed { index, ps ->
                    var kgText by remember(entry.exerciseId, index, ps) {
                        mutableStateOf(ps.targetWeightKg?.toString() ?: "")
                    }
                    var repsText by remember(entry.exerciseId, index, ps) {
                        mutableStateOf(ps.targetReps.toString())
                    }
                    var rirText by remember(entry.exerciseId, index, ps) {
                        mutableStateOf(ps.targetRir?.toString() ?: "")
                    }
                    fun commit() {
                        val reps = repsText.toIntOrNull() ?: return
                        val kg = kgText.takeIf { it.isNotBlank() }
                            ?.replace(',', '.')?.toDoubleOrNull()
                        val rir = rirText.takeIf { it.isNotBlank() }
                            ?.replace(',', '.')?.toDoubleOrNull()
                        entry.plannedSets[index] = PlannedSetDraft(reps, kg, rir, ps.id)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        OutlinedTextField(
                            value = kgText,
                            onValueChange = { kgText = it; commit() },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Decimal),
                            modifier = Modifier.weight(1f))
                        OutlinedTextField(
                            value = repsText,
                            onValueChange = { repsText = it; commit() },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Number),
                            modifier = Modifier.weight(1f))
                        OutlinedTextField(
                            value = rirText,
                            onValueChange = { rirText = it; commit() },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Decimal),
                            modifier = Modifier.weight(1f))
                        TextButton(
                            onClick = { entry.plannedSets.removeAt(index) },
                            enabled = entry.plannedSets.size > 1,
                            modifier = Modifier.weight(0.4f)) { Text("✕") }
                    }
                }
                TextButton(onClick = {
                    val last = entry.plannedSets.lastOrNull()
                    entry.plannedSets.add(PlannedSetDraft(
                        targetReps = last?.targetReps ?: 8,
                        targetWeightKg = last?.targetWeightKg,
                        targetRir = last?.targetRir))
                }) { Text("+ Añadir serie") }
            }
        }
    }
}

@Composable
private fun AddExerciseRow(
    exercises: List<ExerciseEntry>,
    excluded: Set<String>,
    onAdd: (ExerciseEntry) -> Unit
) {
    var query by remember { mutableStateOf("") }
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        OutlinedTextField(
            value = query, onValueChange = { query = it },
            label = { Text("Añadir ejercicio") }, singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        if (query.isNotBlank()) {
            val matches = exercises.filter {
                it.id !in excluded && it.name.contains(query, ignoreCase = true)
            }.take(6)
            matches.forEach { match ->
                TextButton(onClick = { onAdd(match); query = "" }) {
                    Text("+ " + match.name)
                }
            }
            if (matches.isEmpty()) {
                Text("Sin coincidencias", style = MaterialTheme.typography.bodySmall)
            }
        }
        Spacer(Modifier.height(2.dp))
    }
}


/** Campos WOD del movimiento que el borrador simple no modelaba (Apple WODMovementEditor): Peso H/M,
 *  escala alternativa y notas. Editan el JSON original del movimiento (ids y demás campos intactos). */
@Composable
private fun WodMovementDetails(entry: EntryUi) {
    var open by remember(entry.itemId) { mutableStateOf(false) }
    TextButton(modifier = Modifier.testTag("plan_wod_details"), onClick = { open = !open }) {
        Text(if (open) "Cerrar detalles" else "Detalles del movimiento")
    }
    if (!open) return
    fun json(): JSONObject = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
        ?: JSONObject().put("id", entry.itemId ?: java.util.UUID.randomUUID().toString())
            .put("exerciseId", entry.exerciseId).put("name", entry.name).put("isRest", false)
    fun num(key: String): String = json().let { if (it.has(key) && !it.isNull(key)) it.getDouble(key).toString() else "" }
    var male by remember(entry.itemId) { mutableStateOf(num("weightMaleKg")) }
    var female by remember(entry.itemId) { mutableStateOf(num("weightFemaleKg")) }
    var scale by remember(entry.itemId) { mutableStateOf(json().optString("scaleAlternative")) }
    var notes by remember(entry.itemId) { mutableStateOf(json().optString("notes")) }
    fun write(key: String, text: String, numeric: Boolean) {
        val o = json()
        val v = if (numeric) text.replace(',', '.').toDoubleOrNull() else text.ifEmpty { null }
        if (v == null) o.remove(key) else o.put(key, v)
        entry.sourceJson = o.toString()
    }
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(value = male, singleLine = true, label = { Text("Peso H (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.weight(1f).testTag("plan_wod_male"),
            onValueChange = { male = it; write("weightMaleKg", it, true) })
        OutlinedTextField(value = female, singleLine = true, label = { Text("Peso M (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.weight(1f).testTag("plan_wod_female"),
            onValueChange = { female = it; write("weightFemaleKg", it, true) })
    }
    OutlinedTextField(value = scale, singleLine = true, label = { Text("Escala alternativa") },
        modifier = Modifier.fillMaxWidth().testTag("plan_wod_scale"),
        onValueChange = { scale = it; write("scaleAlternative", it, false) })
    OutlinedTextField(value = notes, singleLine = true, label = { Text("Notas") },
        modifier = Modifier.fillMaxWidth().testTag("plan_wod_notes"),
        onValueChange = { notes = it; write("notes", it, false) })
}

/** Mover una entrada a otro bloque (Apple applyReorder): misma clase o conversión fuerza↔WOD con la regla de Apple. */
private object PlanEntryMoves {
    /** Devuelve un aviso/error para mostrar (null si todo bien y sin pérdidas). El borrador no cambia si rechaza. */
    fun move(
        blocks: MutableList<BlockDraftUi>, from: Int, entryIndex: Int, to: Int,
        nameById: Map<String, String>, exercises: List<ExerciseEntry>, beforeIndex: Int? = null
    ): String? {
        val src = blocks.getOrNull(from) ?: return null
        val dst = blocks.getOrNull(to) ?: return null
        val entry = src.entries.getOrNull(entryIndex) ?: return null
        val srcStrength = src.format == "strength"; val dstStrength = dst.format == "strength"
        if (srcStrength == dstStrength) {
            if (dstStrength && dst.entries.any { it.exerciseId == entry.exerciseId })
                return "«" + (nameById[entry.exerciseId] ?: "Ejercicio") + "» ya está en ese bloque de fuerza"
            src.entries.removeAt(entryIndex); dst.entries.add((beforeIndex ?: dst.entries.size).coerceIn(0, dst.entries.size), entry); return null
        }
        if (srcStrength) {
            val sets = if (entry.setsExpanded || entry.untouchedUniform) entry.plannedSets.toList()
            else (1..(entry.sets.toIntOrNull() ?: 1).coerceIn(1, 30)).map {
                PlannedSetDraft(entry.quantity.toIntOrNull() ?: 8, entry.weight.replace(',', '.').toDoubleOrNull()) }
            val unit = entry.unit ?: entry.sourceJson?.let { runCatching { JSONObject(it).optString("quantityUnit") }.getOrNull() }.orEmpty()
            val mv = EditorBlockOps.planStrengthToMovement(entry.itemId, entry.exerciseId,
                nameById[entry.exerciseId] ?: entry.name.ifBlank { "Ejercicio" }, sets, unit)
            src.entries.removeAt(entryIndex)
            dst.entries.add((beforeIndex ?: dst.entries.size).coerceIn(0, dst.entries.size), EntryUi(entry.exerciseId, mv.getString("name"), mv.optInt("reps", 8), 1, null, null,
                mv.getString("id"), mv.toString()))
            return null
        }
        val source = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?: JSONObject().put("id", entry.itemId ?: java.util.UUID.randomUUID().toString()).put("name", entry.name)
                .put("reps", entry.quantity.toIntOrNull() ?: 10)
        if (source.optBoolean("isRest")) return "El descanso (REST) no se puede pasar a un bloque de fuerza"
        val catalogId = entry.exerciseId.takeIf { id -> id.isNotBlank() && exercises.any { it.id == id } }
            ?: exercises.firstOrNull { foldForSearch(it.name) == foldForSearch(source.optString("name")) }?.id
            ?: (EditorBlockOps.PENDING_PREFIX + source.optString("name").trim().ifBlank { return "El movimiento no tiene nombre" })
        if (dst.entries.any { it.exerciseId == catalogId }) return "«" + source.optString("name") + "» ya está en ese bloque de fuerza"
        val (item, lost) = EditorBlockOps.planMovementToStrength(source, catalogId)
        val planned = EditorBlockOps.jsonToDraftSets(item.getJSONArray("plannedSets"))
        src.entries.removeAt(entryIndex)
        dst.entries.add((beforeIndex ?: dst.entries.size).coerceIn(0, dst.entries.size), EntryUi(catalogId, if (catalogId.startsWith(EditorBlockOps.PENDING_PREFIX)) source.optString("name").trim() else "", planned.first().targetReps, planned.size, planned.first().targetWeightKg,
            planned, item.getString("id"), item.toString()))
        val created = if (catalogId.startsWith(EditorBlockOps.PENDING_PREFIX))
            "«" + source.optString("name").trim() + "» se creará como ejercicio personalizado al guardar. " else ""
        return if (lost.isEmpty()) created.trim().ifEmpty { null }
        else created + "Al pasar a fuerza se descartan: " + lost.joinToString(", ") + " (como en Apple)"
    }
}
