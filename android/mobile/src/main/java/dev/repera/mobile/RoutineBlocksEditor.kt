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
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.Saver
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
    onTitleSuggested: (String) -> Unit = {},
    /** Modo sesión de Apple: interruptor «Favorito» y botón «Empezar». onFavoriteChosen se llama justo antes de onReplace. */
    sessionMode: Boolean = false,
    onFavoriteChosen: (Boolean) -> Unit = {},
    saveStatus:String? = null,
    editableTitle:Boolean = false,
    accountId:String = ""
) {
    val scopeKey=remember(accountId,routine.id) {org.json.JSONArray(listOf(accountId,routine.id)).toString()}
    val textSaver=remember(scopeKey) {Saver<String,String>(save={saveScopedEditorValue(scopeKey,it)},restore={restoreScopedEditorValue(scopeKey,it)})}
    val nullableTextSaver=remember(scopeKey) {Saver<String?,String>(save={saveScopedEditorValue(scopeKey,it)},restore={restoreScopedEditorValue(scopeKey,it)})}
    val favoriteSaver=remember(scopeKey) {Saver<Boolean,String>(save={saveScopedEditorValue(scopeKey,it.toString())},restore={restoreScopedEditorValue(scopeKey,it)?.toBooleanStrictOrNull()})}
    val blocksSaver=remember(scopeKey) {Saver<androidx.compose.runtime.snapshots.SnapshotStateList<BlockDraftUi>,String>(
        save={saveScopedEditorValue(scopeKey,saveRoutineEditorBlocks(it))},
        restore={restoreScopedEditorValue(scopeKey,it)?.let(::restoreRoutineEditorBlocksOrNull)})}
    var draftTitle by rememberSaveable(accountId,routine.id,stateSaver=textSaver) {mutableStateOf(routine.title)}
    var asFavorite by rememberSaveable(accountId,routine.id,stateSaver=favoriteSaver) { mutableStateOf(false) }
    var suggestedTitle by rememberSaveable(accountId,routine.id,stateSaver=nullableTextSaver) { mutableStateOf<String?>(null) }
    val nameById = remember(exercises) { exercises.associate { it.id to it.name } }
    val blocks = rememberSaveable(accountId,routine.id,saver=blocksSaver) {
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
            // Apple 040227d5 (corte): Volver NEUTRO a la izquierda; la
            // confirmación (Guardar/Empezar) mantiene el verde de acento.
            TextButton(onClick = onBack, enabled = !busy,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.onSurface)) { Text("Volver") }
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
                if(editableTitle) {
                    if(draftTitle.trim().isBlank()) {error="Escribe un título válido";return@TextButton}
                    onTitleSuggested(draftTitle.trim())
                } else suggestedTitle?.let(onTitleSuggested)
                if (sessionMode) onFavoriteChosen(asFavorite)
                onReplace(drafts)
            }, enabled = !busy) { Text(if (sessionMode) "Empezar" else "Guardar") }
        }
        Text("Contenido de «" + routine.title + "»",
            style = MaterialTheme.typography.titleLarge)
        if(editableTitle) OutlinedTextField(value=draftTitle,onValueChange={draftTitle=it},enabled=!busy,
            label={Text("Nombre de la rutina")},modifier=Modifier.testTag("new_template_title"))
        if (sessionMode) Row(verticalAlignment = Alignment.CenterVertically) {
            androidx.compose.material3.Switch(checked = asFavorite, onCheckedChange = { asFavorite = it },
                modifier = Modifier.testTag("session_favorite_switch"))
            Text("  Favorito")
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        saveStatus?.let {Text(it,color=MaterialTheme.colorScheme.error,modifier=Modifier.testTag("routine_save_status"))}

        val blockHeights = remember { androidx.compose.runtime.mutableStateMapOf<Int, Int>() }
        blocks.forEachIndexed { index, block ->
            DragReorderItem(index, blockHeights, blocks.size,
                onDrop = { _, t -> if (t != index) { val moved = blocks.removeAt(index); blocks.add(t, moved) } },
                onMoveTo = { t -> if (t != index && t in blocks.indices) { val moved = blocks.removeAt(index); blocks.add(t, moved) } },
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

internal class EntryUi(val exerciseId: String, name: String, quantity: Int,
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
    var detailsOpen by mutableStateOf(false)
    val rawMovementInputs=androidx.compose.runtime.mutableStateMapOf<String,String>()
    val invalidMovementInputs=androidx.compose.runtime.mutableStateMapOf<String,Boolean>()
    fun movementText(key:String):String = rawMovementInputs[key] ?: sourceJson?.let {raw ->
        val o=JSONObject(raw)
        if(o.has(key) && !o.isNull(key)) {
            val v=o.get(key)
            if(v is Number) dev.repera.domain.ReperaNumberFormat.decimal(v.toDouble()) else v.toString()
        } else ""
    }.orEmpty()
    fun durationText(index:Int,hold:Boolean):String = rawMovementInputs["duration:$index"] ?: (plannedSets[index].targetDurationSeconds ?: if(hold) 30 else 60).toString()
    fun setDurationText(index:Int,text:String) {
        val key="duration:$index";rawMovementInputs[key]=text
        val seconds=text.toIntOrNull()?.takeIf {it in 1..3600}
        invalidMovementInputs[key]=seconds==null
        if(seconds!=null) {
            val previous=plannedSets[index];val updated=previous.copy(targetDurationSeconds=seconds)
            rawSetInputs[index]?.takeIf {it.first==previous}?.let {rawSetInputs[index]=updated to it.second}
            plannedSets[index]=updated
        }
    }
    fun restText():String = rawMovementInputs["restSeconds"] ?: sourceJson?.let {JSONObject(it).optInt("restSeconds",60).toString()} ?: "60"
    fun setRestText(text:String) {
        rawMovementInputs["restSeconds"]=text
        val seconds=text.toIntOrNull()?.takeIf {it in 15..300}
        invalidMovementInputs["restSeconds"]=seconds==null
        if(seconds!=null) sourceJson=JSONObject(sourceJson!!).put("restSeconds",seconds).toString()
    }
    fun setMovementText(key:String,text:String,numeric:Boolean) {
        rawMovementInputs[key]=text
        val number=if(numeric && text.isNotBlank()) dev.repera.domain.ReperaNumberFormat.parse(text)?.takeIf {it.isFinite() && it>=0} else null
        val invalid=numeric && text.isNotBlank() && number==null
        invalidMovementInputs[key]=invalid
        if(invalid) return
        val o=sourceJson?.let(::JSONObject) ?: JSONObject()
            .put("id",itemId ?: java.util.UUID.randomUUID().toString()).put("exerciseId",exerciseId).put("name",name).put("isRest",false)
        if(numeric) {if(number==null) o.remove(key) else o.put(key,number)}
        else {if(text.isEmpty()) o.remove(key) else o.put(key,text)}
        sourceJson=o.toString()
    }
    var setsExpanded by mutableStateOf(false)
    val invalidSetInputs=androidx.compose.runtime.mutableStateMapOf<Int,Boolean>()
    val rawSetInputs=androidx.compose.runtime.mutableStateMapOf<Int,Pair<PlannedSetDraft,Triple<String,String,String>>>()
    /** Valores iniciales de los campos uniformes: si no se tocan, las series
     *  originales (ids, RIR, no uniformes) se escriben tal cual. */
    var initialUniform = Triple(quantity.toString(), sets.toString(), weightKg?.toString() ?: "")
    var hadPlanned = planned != null
    val untouchedUniform: Boolean
        get() = hadPlanned && Triple(quantity, sets, weight) == initialUniform
}

internal class BlockDraftUi(info: RoutineBlockInfo? = null) {
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
            if(entry.invalidSetInputs.values.any {it} || entry.invalidMovementInputs.values.any {it}) return null
            val base = RoutineDraftEntry(
                itemId = entry.itemId, sourceJson = entry.sourceJson, quantityUnit = entry.unit,
                exerciseId = entry.exerciseId,
                quantity = entry.quantity.toIntOrNull() ?: return null,
                sets = entry.sets.toIntOrNull() ?: return null,
                weightKg = if (entry.weight.isBlank()) null
                    else dev.repera.domain.ReperaNumberFormat.parse(entry.weight) ?: return null
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

/** Raw editor state, not a validated RoutineBlockDraft: incomplete numbers must survive. */
internal fun saveRoutineEditorBlocks(blocks:List<BlockDraftUi>):String = org.json.JSONArray().apply {
    blocks.forEach {b ->put(JSONObject().apply {
        put("blockId",b.blockId);put("source",b.sourceJson)
        put("title",b.title);put("format",b.format);put("cap",b.timeCap);put("rounds",b.rounds)
        put("interval",b.interval);put("work",b.work);put("rest",b.rest);put("ladder",b.ladder)
        put("entries",org.json.JSONArray().apply {b.entries.forEach {e ->put(JSONObject().apply {
            put("exerciseId",e.exerciseId);put("name",e.name);put("itemId",e.itemId);put("source",e.sourceJson)
            put("unit",e.unit);put("quantity",e.quantity);put("sets",e.sets);put("weight",e.weight)
            put("detailsOpen",e.detailsOpen)
            put("rawMovement",JSONObject().apply {e.rawMovementInputs.forEach {(key,value) ->put(key,value)}})
            put("invalidMovement",org.json.JSONArray(e.invalidMovementInputs.filterValues {it}.keys.toList()))
            put("expanded",e.setsExpanded);put("hadPlanned",e.hadPlanned)
            put("invalidSets",org.json.JSONArray(e.invalidSetInputs.filterValues {it}.keys.toList()))
            put("rawSets",org.json.JSONArray().apply {e.rawSetInputs.filter {(index,row) ->e.plannedSets.getOrNull(index)==row.first}.forEach {(index,row) ->
                put(JSONObject().put("index",index).put("reps",row.second.first).put("kg",row.second.second).put("rir",row.second.third))
            }})
            put("initial",org.json.JSONArray(listOf(e.initialUniform.first,e.initialUniform.second,e.initialUniform.third)))
            put("planned",org.json.JSONArray().apply {e.plannedSets.forEach {p ->put(JSONObject()
                .put("targetReps",p.targetReps).put("targetWeightKg",p.targetWeightKg)
                .put("targetRir",p.targetRir).put("id",p.id).put("duration",p.targetDurationSeconds).put("source",p.sourceJson))}})
        })}})
    })}
}.toString()

internal fun restoreRoutineEditorBlocks(raw:String):androidx.compose.runtime.snapshots.SnapshotStateList<BlockDraftUi> {
    val array=org.json.JSONArray(raw)
    fun JSONObject.nullable(key:String):String?=if(has(key) && !isNull(key)) getString(key) else null
    return mutableStateListOf<BlockDraftUi>().apply {
        for(i in 0 until array.length()) {
            val o=array.getJSONObject(i)
            val b=BlockDraftUi(RoutineBlockInfo(title=o.getString("title"),format=o.getString("format"),
                id=o.nullable("blockId"),sourceJson=o.nullable("source")))
            b.timeCap=o.getString("cap");b.rounds=o.getString("rounds");b.interval=o.getString("interval")
            b.work=o.getString("work");b.rest=o.getString("rest");b.ladder=o.getString("ladder")
            val entries=o.getJSONArray("entries")
            for(j in 0 until entries.length()) {
                val e=entries.getJSONObject(j)
                val entry=EntryUi(e.getString("exerciseId"),e.getString("name"),0,1,null,
                    emptyList(),e.nullable("itemId"),e.nullable("source"))
                val planned=e.getJSONArray("planned")
                for(k in 0 until planned.length()) {
                    val p=planned.getJSONObject(k)
                    entry.plannedSets.add(PlannedSetDraft(p.getInt("targetReps"),
                        if(p.has("targetWeightKg")) p.getDouble("targetWeightKg") else null,
                        if(p.has("targetRir")) p.getDouble("targetRir") else null,p.nullable("id"),if(p.has("duration")) p.getInt("duration") else null,p.nullable("source")))
                }
                e.optJSONArray("invalidSets")?.let {invalid ->for(k in 0 until invalid.length()) entry.invalidSetInputs[invalid.getInt(k)]=true}
                e.optJSONArray("rawSets")?.let {rows ->for(k in 0 until rows.length()) {
                    val row=rows.getJSONObject(k);val index=row.getInt("index")
                    entry.plannedSets.getOrNull(index)?.let {ps ->entry.rawSetInputs[index]=ps to Triple(row.getString("reps"),row.getString("kg"),row.getString("rir"))}
                }}
                entry.detailsOpen=e.optBoolean("detailsOpen")
                e.optJSONObject("rawMovement")?.let {raw ->raw.keys().forEach {key ->entry.rawMovementInputs[key]=raw.getString(key)}}
                e.optJSONArray("invalidMovement")?.let {invalid ->for(k in 0 until invalid.length()) entry.invalidMovementInputs[invalid.getString(k)]=true}
                entry.quantity=e.getString("quantity");entry.sets=e.getString("sets");entry.weight=e.getString("weight")
                entry.unit=e.nullable("unit");entry.setsExpanded=e.getBoolean("expanded");entry.hadPlanned=e.getBoolean("hadPlanned")
                val initial=e.getJSONArray("initial")
                entry.initialUniform=Triple(initial.getString(0),initial.getString(1),initial.getString(2))
                b.entries.add(entry)
            }
            add(b)
        }
    }
}
internal fun saveScopedEditorValue(scope:String,value:String?):String = JSONObject().put("scope",scope).put("value",value).toString()
internal fun restoreScopedEditorValue(scope:String,raw:String):String? {
    // Fail closed: malformed or foreign saved data yields null (fresh state) instead of crashing the restore.
    return runCatching {
        val o=JSONObject(raw)
        if(o.getString("scope")==scope && o.has("value") && !o.isNull("value")) o.getString("value") else null
    }.getOrNull()
}
internal fun restoreRoutineEditorBlocksOrNull(raw:String):androidx.compose.runtime.snapshots.SnapshotStateList<BlockDraftUi>? =
    runCatching {restoreRoutineEditorBlocks(raw)}.getOrNull()

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
            // FlowRow: con chunked(4) el último chip de la fila quedaba estrangulado
            // ("EMOM / Every X'" se envolvía letra a letra, visto en captura de CI).
            @androidx.compose.runtime.Composable
            fun chips() {
                blockFormats.forEach { wire ->
                    FilterChip(
                        selected = block.format == wire,
                        onClick = { block.format = wire },
                        label = { Text(formatLabel(wire), maxLines = 1, softWrap = false) }
                    )
                }
            }
            androidx.compose.foundation.layout.FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()) { chips() }
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
                    onMoveTo = { t -> if (t != index && t in block.entries.indices) { val moved = block.entries.removeAt(index); block.entries.add(t, moved) } },
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
                    // Fondo opaco: el "Quitar" rojo traslucía en reposo (captura CI 25/10).
                    androidx.compose.material3.Surface {
                    EntryEditorRow(
                        entry = entry,
                        resolvedName = entry.name.ifBlank {
                            nameById[entry.exerciseId] ?: "Ejercicio" },
                        isStrength = block.format == "strength",
                        mobility=exercises.firstOrNull {it.id==entry.exerciseId}?.sportTag=="Movilidad",
                        mobilityHold=exercises.firstOrNull {it.id==entry.exerciseId}?.mobilityHold==true,
                        // Apple 63824a81 + f7109bd7: el selector de unidad se
                        // ofrece a supportsRepsOrMeters (Repeticiones/Metros,
                        // con o sin kg) ademas del cardio Calorias/Metros.
                        weightedRepsOrMeters = exercises.firstOrNull { it.id == entry.exerciseId }?.let { ex ->
                            dev.repera.domain.ExerciseInput.supportsRepsOrMeters(ex.name) } == true,
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
    mobility:Boolean=false,mobilityHold:Boolean=false,
    loadGuideProvider: (String, Int, Double?) -> LoadGuide?,
    onRemove: () -> Unit,
    handle: Modifier = Modifier,
    moveTargets: List<Pair<Int, String>> = emptyList(),
    onMove: (Int) -> Unit = {},
    unitChoices: Boolean = false,
    weightedRepsOrMeters: Boolean = false,
    onUp: (() -> Unit)? = null,
    onDown: (() -> Unit)? = null
) {
    val isRest = entry.sourceJson?.let { runCatching { JSONObject(it).optBoolean("isRest") }.getOrDefault(false) } == true
    // Apple 4c9a5d10: la etiqueta de cantidad de un recorrido (reps/m) es el
    // shortLabel de la unidad elegida, no «Reps»/«Cantidad» fijo.
    fun shortUnitLabel(u:String?):String = when(u) {"meters"->"m";"calories"->"cal";else->"reps"}
    val entryUnit:String? = if (weightedRepsOrMeters)
        entry.unit ?: entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?.optString("quantityUnit")?.takeIf { it == "reps" || it == "meters" || it == "calories" }
            ?: dev.repera.domain.ExerciseInput.defaultQuantityUnit(entry.name, null)
    else null
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
            OutlinedTextField(value = entry.restText(), singleLine = true, label = { Text("Segundos de descanso") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth().testTag("plan_rest_seconds"),
                onValueChange = {entry.setRestText(it)})
            return@Column
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = entry.quantity,
                onValueChange = { entry.quantity = it },
                label = { Text(if (isStrength) "Reps"
                    else if (weightedRepsOrMeters) shortUnitLabel(entryUnit) else "Cantidad") },
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
        if (unitChoices || weightedRepsOrMeters) {
            // Picker "Unidad" (Apple 63824a81/f7109bd7): Repeticiones/Metros
            // para supportsRepsOrMeters; Calorias/Metros para cardio.
            val src = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            val current = entry.unit ?: src?.optString("quantityUnit")?.takeIf { it == "calories" || it == "meters" || it == "reps" }
                ?: if (weightedRepsOrMeters) dev.repera.domain.ExerciseInput.defaultQuantityUnit(entry.name, null)
                else if (src?.has("distanceMeters") == true && !src.isNull("distanceMeters")) "meters" else "calories"
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (weightedRepsOrMeters) {
                    androidx.compose.material3.FilterChip(selected = current == "reps", onClick = { entry.unit = "reps" },
                        label = { Text("Repeticiones") }, modifier = Modifier.testTag("plan_unit_reps"))
                } else {
                    androidx.compose.material3.FilterChip(selected = current == "calories", onClick = { entry.unit = "calories" },
                        label = { Text("Calorías") }, modifier = Modifier.testTag("plan_unit_calories"))
                }
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
                        entry.plannedSets.clear();entry.invalidSetInputs.clear();entry.rawSetInputs.clear()
                            entry.rawMovementInputs.keys.filter {it.startsWith("duration:")}.forEach {entry.rawMovementInputs.remove(it);entry.invalidMovementInputs.remove(it)}
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
                            entry.plannedSets.clear();entry.invalidSetInputs.clear();entry.rawSetInputs.clear()
                            entry.rawMovementInputs.keys.filter {it.startsWith("duration:")}.forEach {entry.rawMovementInputs.remove(it);entry.invalidMovementInputs.remove(it)}
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
                    Text(if (weightedRepsOrMeters) shortUnitLabel(entryUnit) else "Reps",
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.weight(1f))
                    Text("RIR", style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier.weight(1f))
                    Spacer(Modifier.weight(0.4f))
                }
                entry.plannedSets.forEachIndexed { index, ps ->
                    if(mobility) OutlinedTextField(value=entry.durationText(index,mobilityHold),
                        onValueChange={entry.setDurationText(index,it)},singleLine=true,
                        label={Text("Duración serie ${index+1} (segundos)")},
                        keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Number),
                        modifier=Modifier.fillMaxWidth().testTag("plan_set_duration_$index"))

                    val current=entry.rawSetInputs[index]?.takeIf {it.first==ps}?.second
                        ?: Triple(ps.targetReps.toString(),ps.targetWeightKg?.toString() ?: "",ps.targetRir?.toString() ?: "")
                    var repsText=current.first
                    var kgText=current.second
                    var rirText=current.third
                    fun commit() {
                        val parsed=parsePlannedSetText(repsText,kgText,rirText,ps.id)
                        entry.invalidSetInputs[index]=parsed==null
                        val updated=parsed?.copy(targetDurationSeconds=ps.targetDurationSeconds,sourceJson=ps.sourceJson)
                        if(updated!=null) entry.plannedSets[index] = updated
                        entry.rawSetInputs[index]=(updated ?: ps) to Triple(repsText,kgText,rirText)
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
                            onClick = {
                                entry.plannedSets.removeAt(index)
                                val shifted=entry.invalidSetInputs.filterKeys {it!=index}.mapKeys {if(it.key>index) it.key-1 else it.key}
                                entry.invalidSetInputs.clear();entry.invalidSetInputs.putAll(shifted)
                                val rawShifted=entry.rawSetInputs.filterKeys {it!=index}.mapKeys {if(it.key>index) it.key-1 else it.key}
                                entry.rawSetInputs.clear();entry.rawSetInputs.putAll(rawShifted)
                                fun shiftedKey(key:String):String? {
                                    if(!key.startsWith("duration:")) return key
                                    val n=key.substringAfter(':').toInt();return if(n==index) null else "duration:${if(n>index) n-1 else n}"
                                }
                                val rawDurations=entry.rawMovementInputs.toMap().mapNotNull {(k,v) ->shiftedKey(k)?.let {it to v}}.toMap()
                                val invalidDurations=entry.invalidMovementInputs.toMap().mapNotNull {(k,v) ->shiftedKey(k)?.let {it to v}}.toMap()
                                entry.rawMovementInputs.clear();entry.rawMovementInputs.putAll(rawDurations)
                                entry.invalidMovementInputs.clear();entry.invalidMovementInputs.putAll(invalidDurations)

                            },
                            enabled = entry.plannedSets.size > 1,
                            modifier = Modifier.weight(0.4f)) { Text("✕") }
                    }
                }
                TextButton(onClick = {
                    val last = entry.plannedSets.lastOrNull()
                    entry.plannedSets.add(PlannedSetDraft(
                        targetReps = last?.targetReps ?: 8,
                        targetWeightKg = last?.targetWeightKg,
                        targetRir = last?.targetRir,targetDurationSeconds=last?.targetDurationSeconds))
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
    TextButton(modifier = Modifier.testTag("plan_wod_details"), onClick = { entry.detailsOpen = !entry.detailsOpen }) {
        Text(if (entry.detailsOpen) "Cerrar detalles" else "Detalles del movimiento")
    }
    if (!entry.detailsOpen) return
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(value = entry.movementText("weightMaleKg"), singleLine = true, label = { Text("Peso H (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.weight(1f).testTag("plan_wod_male"),
            onValueChange = { entry.setMovementText("weightMaleKg", it, true) })
        OutlinedTextField(value = entry.movementText("weightFemaleKg"), singleLine = true, label = { Text("Peso M (kg)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.weight(1f).testTag("plan_wod_female"),
            onValueChange = { entry.setMovementText("weightFemaleKg", it, true) })
    }
    OutlinedTextField(value = entry.movementText("scaleAlternative"), singleLine = true, label = { Text("Escala alternativa") },
        modifier = Modifier.fillMaxWidth().testTag("plan_wod_scale"),
        onValueChange = { entry.setMovementText("scaleAlternative", it, false) })
    OutlinedTextField(value = entry.movementText("notes"), singleLine = true, label = { Text("Notas") },
        modifier = Modifier.fillMaxWidth().testTag("plan_wod_notes"),
        onValueChange = { entry.setMovementText("notes", it, false) })
}

/** Mover una entrada a otro bloque (Apple applyReorder): misma clase o conversión fuerza↔WOD con la regla de Apple. */
internal object PlanEntryMoves {
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
        if(src.toDraft()==null) return "Corrige los campos del bloque antes de convertir un movimiento"
        if (srcStrength) {
            val sets = if (entry.setsExpanded || entry.untouchedUniform) entry.plannedSets.toList()
            else (1..(entry.sets.toIntOrNull() ?: 1).coerceIn(1, 30)).map {
                PlannedSetDraft(entry.quantity.toIntOrNull() ?: 8, dev.repera.domain.ReperaNumberFormat.parse(entry.weight)) }
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
