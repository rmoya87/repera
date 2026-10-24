package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
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
        LoadGuide? = { _, _, _ -> null }
) {
    val nameById = remember(exercises) { exercises.associate { it.id to it.name } }
    val blocks = remember(routine.id) {
        mutableStateListOf<BlockDraftUi>().apply {
            if (routine.blocks.isEmpty()) add(BlockDraftUi())
            else routine.blocks.forEach { add(BlockDraftUi(it)) }
        }
    }
    var error by remember(routine.id) { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
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
                onReplace(drafts)
            }, enabled = !busy) { Text("Guardar") }
        }
        Text("Contenido de «" + routine.title + "»",
            style = MaterialTheme.typography.titleLarge)
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

        blocks.forEachIndexed { index, block ->
            BlockEditorCard(
                block = block,
                nameById = nameById,
                exercises = exercises,
                loadGuideProvider = loadGuideProvider,
                onRemove = if (blocks.size > 1) ({ blocks.removeAt(index) }) else null
            )
        }
        TextButton(onClick = { blocks.add(BlockDraftUi()) }, enabled = !busy) {
            Text("Añadir bloque")
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
                      planned: List<PlannedSetDraft>? = null) {
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
}

private class BlockDraftUi(info: RoutineBlockInfo? = null) {
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
                it.plannedSets))
        }
    }

    fun toDraft(): RoutineBlockDraft? {
        val cap = timeCap.toIntOrNull() ?: return null
        val rds = rounds.toIntOrNull() ?: return null
        val intv = interval.toIntOrNull() ?: return null
        val wk = work.toIntOrNull() ?: return null
        val rst = rest.toIntOrNull() ?: return null
        val scheme = if (format == "ladder") {
            ladder.split("-", ",", " ").filter { it.isNotBlank() }
                .map { it.toIntOrNull() ?: return null }
        } else null
        val parsed = entries.map { entry ->
            val base = RoutineDraftEntry(
                exerciseId = entry.exerciseId,
                quantity = entry.quantity.toIntOrNull() ?: return null,
                sets = entry.sets.toIntOrNull() ?: return null,
                weightKg = entry.weight.takeIf { it.isNotBlank() }
                    ?.replace(',', '.')?.toDoubleOrNull() ?: return null
            )
            if (format == "strength" && entry.setsExpanded)
                base.copy(plannedSets = entry.plannedSets.toList())
            else base
        }
        return RoutineBlockDraft(
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
    onRemove: (() -> Unit)?
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = block.title,
                    onValueChange = { block.title = it },
                    label = { Text("Título del bloque") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
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
                EntryEditorRow(
                    entry = entry,
                    resolvedName = entry.name.ifBlank {
                        nameById[entry.exerciseId] ?: "Ejercicio" },
                    isStrength = block.format == "strength",
                    loadGuideProvider = loadGuideProvider,
                    onRemove = { block.entries.removeAt(index) }
                )
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
    onRemove: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(resolvedName, style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.weight(1f))
            TextButton(onClick = onRemove) { Text("Quitar") }
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
                        entry.plannedSets[index] = PlannedSetDraft(reps, kg, rir)
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
