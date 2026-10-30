package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.ui.platform.testTag
import org.json.JSONObject
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material.icons.outlined.KeyboardArrowUp
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.PauseCircle
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import dev.repera.domain.WodFormat
import dev.repera.domain.WorkoutLocationPin
import java.time.LocalDate
import java.time.LocalTime
import java.util.Locale

/** Editor de contenido de rutina: bloques (secciones), formatos y movimientos.
 *  Multi-bloque: buy-in / trabajo / cash-out se componen como bloques
 *  separados, igual que en iOS. */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
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
    /** DayPlus / one-off: título «Crear entreno», meta (nombre, fecha, hora, favorito) y lugar. */
    oneOffEditor: Boolean = false,
    scheduledDayIso: String? = null,
    pageTitle: String? = null,
    showPlaceSection: Boolean = true,
    onOneOffMeta: (
        dayIso: String?,
        timeMinutes: Int?,
        isFavorite: Boolean,
        locationPin: WorkoutLocationPin?
    ) -> Unit = { _, _, _, _ -> },
    accountId:String = "",
    /** Preferencia de visualización RIR/RPE; el almacenamiento sigue en RIR. */
    effortUnit:String = "rir",
    /** Abrir ficha del ejercicio (miniatura / título). */
    onOpenExercise: (String) -> Unit = {}
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
    var oneOffFavorite by rememberSaveable(accountId,routine.id,stateSaver=favoriteSaver) {
        mutableStateOf(routine.isFavorite)
    }
    var scheduledClock by rememberSaveable(accountId, routine.id, stateSaver = nullableTextSaver) {
        mutableStateOf(
            routine.timeMinutes?.let { m ->
                "%02d:%02d".format(m / 60, m % 60)
            } ?: if (oneOffEditor) "18:00" else null
        )
    }
    var metaDayIso by rememberSaveable(accountId, routine.id, stateSaver = nullableTextSaver) {
        mutableStateOf(scheduledDayIso)
    }
    var draftPin by remember(accountId, routine.id) { mutableStateOf(routine.locationPin) }
    var suggestedTitle by rememberSaveable(accountId,routine.id,stateSaver=nullableTextSaver) { mutableStateOf<String?>(null) }
    val nameById = remember(exercises) { exercises.associate { it.id to it.name } }
    val blocks = rememberSaveable(accountId,routine.id,saver=blocksSaver) {
        mutableStateListOf<BlockDraftUi>().apply {
            if (routine.blocks.isEmpty()) add(BlockDraftUi())
            else routine.blocks.forEach { add(BlockDraftUi(it)) }
        }
    }
    var error by remember(routine.id) { mutableStateOf<String?>(null) }
    var showReorder by remember { mutableStateOf(false) }
    var showBoardScanner by remember { mutableStateOf(false) }

    if (showBoardScanner) {
        // Modal ajustado (paridad BoardScanSourceSheet / DayPlus escanear).
        ReperaModalBottomSheet(onDismissRequest = { showBoardScanner = false }) {
            BoardScanScreen(
                busy = busy,
                overview = null,
                catalogOverride = exercises,
                asSheet = true,
                onConfirm = { _, _, _ -> },
                onBack = { showBoardScanner = false },
                onImportBlocks = { imported ->
                    imported.forEach { blocks.add(scannedRoutineBlockDraft(it)) }
                    showBoardScanner = false
                }
            )
        }
    }

    if (showReorder) {
        ReperaFullscreenDialog(onDismissRequest = { showReorder = false }) {
            PlanReorderFullscreen(
                blocks = blocks,
                nameById = nameById,
                exercises = exercises,
                onDone = { showReorder = false },
                onMoveMessage = { msg -> if (msg != null) error = msg }
            )
        }
    }

    val scrollState = rememberScrollState()
    val geo = remember(routine.id) { EditorGeometry() }
    ProvideScrollDragAutoScroll(scrollState) {
    Column(
        modifier = Modifier
            .verticalScroll(scrollState)
            .padding(reperaScrollContentPadding(extraBottom = 16.dp)),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        val confirmLabel = if (sessionMode) "Empezar" else "Guardar"
        val canConfirm = !busy && (!editableTitle || draftTitle.trim().isNotBlank())
        fun persistAndSave() {
            val drafts = mutableListOf<RoutineBlockDraft>()
            error = null
            for (block in blocks) {
                val parsed = block.toDraft() ?: run {
                    error = "Revisa los campos numéricos de «" +
                        block.title.ifBlank { "bloque" } + "»"
                    return
                }
                drafts.add(parsed)
            }
            val parsedClock = scheduledClock?.trim()?.takeIf { it.isNotEmpty() }
                ?.let { runCatching { LocalTime.parse(it) }.getOrNull() }
            if (oneOffEditor && scheduledClock?.isNotBlank() == true && parsedClock == null) {
                error = "Hora no válida"
                return
            }
            val timeMinutes = parsedClock?.let { it.hour * 60 + it.minute }
            if (editableTitle && !oneOffEditor) {
                if (draftTitle.trim().isBlank()) {
                    error = "Escribe un título válido"
                    return
                }
                onTitleSuggested(draftTitle.trim())
            } else if (oneOffEditor) {
                if (draftTitle.trim().isBlank()) {
                    error = "Escribe un título válido"
                    return
                }
                onTitleSuggested(draftTitle.trim())
                onOneOffMeta(metaDayIso, timeMinutes, oneOffFavorite, draftPin)
            } else if (sessionMode) {
                onTitleSuggested(draftTitle.trim().ifBlank { "Mi entreno" })
            } else suggestedTitle?.let(onTitleSuggested)
            if (sessionMode) onFavoriteChosen(asFavorite)
            onReplace(drafts)
        }
        DayEditorTopBar(
            onBack = onBack,
            onConfirm = { persistAndSave() },
            confirmEnabled = canConfirm,
            confirmContentDescription = confirmLabel,
            busy = busy
        )
        val headerTitle = pageTitle ?: when {
            oneOffEditor -> "Crear entreno"
            sessionMode -> "Crear entreno"
            editableTitle -> draftTitle.ifBlank { "Nueva rutina" }
            else -> routine.title
        }
        ReperaPageHeader(title = headerTitle)
        if (oneOffEditor || sessionMode) {
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(
                    Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // R5 P2 fila 11: nombre y fecha en filas separadas (iOS),
                    // nombre en regular 17, no negrita con fecha como subtítulo.
                    BasicTextField(
                        value = draftTitle,
                        onValueChange = { draftTitle = it },
                        enabled = !busy,
                        textStyle = MaterialTheme.typography.bodyLarge.copy(
                            fontWeight = FontWeight.Normal,
                            color = MaterialTheme.colorScheme.onSurface
                        ),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().testTag("workout_meta_title")
                    )
                    if (oneOffEditor) {
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                        )
                        var plannedDurationMin by remember(routine.id) {
                            mutableStateOf(45)
                        }
                        WorkoutDateTimeDurationRow(
                            dayIso = metaDayIso,
                            clock = scheduledClock ?: "18:00",
                            durationMinutes = plannedDurationMin,
                            onDayIso = { metaDayIso = it },
                            onClock = { scheduledClock = it },
                            onDurationMinutes = { plannedDurationMin = it.coerceIn(1, 600) }
                        )
                        Row(
                            Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "Favorito",
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.weight(1f)
                            )
                            androidx.compose.material3.Switch(
                                checked = oneOffFavorite,
                                onCheckedChange = { oneOffFavorite = it },
                                colors = reperaSwitchColors(),
                                modifier = Modifier.testTag("workout_favorite_switch")
                            )
                        }
                    } else {
                        metaDayIso?.let { iso ->
                            val dayLabel = runCatching {
                                LocalDate.parse(iso).format(reperaPlanDayFormatter)
                                    .replaceFirstChar {
                                        if (it.isLowerCase()) it.titlecase(Locale("es", "ES"))
                                        else it.toString()
                                    }
                            }.getOrDefault(iso)
                            HorizontalDivider(
                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                            )
                            Text(
                                dayLabel,
                                color = MaterialTheme.colorScheme.onSurface,
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp)
                                    .testTag("workout_meta_date")
                            )
                        }
                    }
                    if (sessionMode) {
                        Row(
                            Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "Favorito",
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.weight(1f)
                            )
                            androidx.compose.material3.Switch(
                                checked = asFavorite,
                                onCheckedChange = { asFavorite = it },
                                colors = reperaSwitchColors(),
                                modifier = Modifier.testTag("session_favorite_switch")
                            )
                        }
                    }
                }
            }
        } else if (editableTitle) {
            OutlinedTextField(
                value = draftTitle, onValueChange = { draftTitle = it }, enabled = !busy,
                label = { Text("Nombre de la rutina") },
                modifier = Modifier.testTag("new_template_title")
            )
        }
        if (showPlaceSection && !sessionMode) {
            ReperaSectionTitle("Lugar")
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                if (draftPin != null) {
                    WorkoutPlacePickerRow(
                        pin = draftPin,
                        accountId = accountId,
                        onPinChange = { draftPin = it }
                    )
                } else {
                    WorkoutPlacePickerRow(
                        pin = null,
                        accountId = accountId,
                        onPinChange = { draftPin = it },
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                    )
                }
            }
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        saveStatus?.let {Text(it,color=MaterialTheme.colorScheme.error,modifier=Modifier.testTag("routine_save_status"))}

        blocks.forEachIndexed { index, block ->
            val sectionTitle = block.title.ifBlank { "Bloque ${index + 1}" }
            ReperaSectionTitle(sectionTitle)
            BlockEditorCard(
                block = block,
                nameById = nameById,
                exercises = exercises,
                loadGuideProvider = loadGuideProvider,
                // iOS permite Eliminar bloque aunque quede uno (R4 #20 / P2 #17).
                onRemove = { blocks.removeAt(index) },
                onOpenReorder = if (blocks.isNotEmpty()) ({ showReorder = true }) else null,
                onOpenExercise = onOpenExercise,
                effortUnit = effortUnit
            )
        }
        var showWods by remember { mutableStateOf(false) }
        var showRoutines by remember { mutableStateOf(false) }
        var showFavorites by remember { mutableStateOf(false) }
        val favorites = importableRoutines.filter { it.id != routine.id && it.isFavorite && it.blocks.isNotEmpty() }
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                PlanEditorActionRow(
                    icon = Icons.Outlined.ViewAgenda,
                    label = "Añadir bloque",
                    modifier = Modifier.testTag("plan_add_block_row"),
                    onClick = {
                        val n = blocks.size + 1
                        blocks.add(BlockDraftUi(RoutineBlockInfo(title = "Bloque $n", format = "")))
                    },
                    enabled = !busy
                )
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                PlanEditorActionRow(
                    icon = Icons.Outlined.List,
                    label = "Elegir WOD",
                    modifier = Modifier.testTag("plan_pick_wod"),
                    onClick = { showWods = true },
                    enabled = !busy
                )
                if (favorites.isNotEmpty()) {
                    HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    PlanEditorActionRow(
                        icon = Icons.Outlined.Star,
                        label = "Añadir favorito",
                        modifier = Modifier.testTag("plan_add_favorite"),
                        onClick = { showFavorites = true },
                        enabled = !busy
                    )
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                PlanEditorActionRow(
                    icon = Icons.Outlined.AddCircle,
                    label = "Escanear pizarra",
                    modifier = Modifier.testTag("plan_scan_board"),
                    onClick = { showBoardScanner = true },
                    enabled = !busy
                )
            }
        }
        if (showFavorites) {
            FavoriteCatalogPickerSheet(
                favorites = favorites,
                onPick = { src ->
                    src.blocks.forEach { blocks.add(BlockDraftUi(EditorBlockOps.duplicateBlockInfo(it))) }
                    showFavorites = false
                },
                onDismiss = { showFavorites = false }
            )
        }
        val importable = importableRoutines.filter { it.id != routine.id && it.blocks.isNotEmpty() }
        if (importable.isNotEmpty() && showRoutines) androidx.compose.material3.AlertDialog(
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
            WodCatalogPickerSheet(
                onPick = { t ->
                    val info = EditorBlockOps.templateToBlockInfo(t, exercises)
                    blocks.add(BlockDraftUi(info)); error = null
                    val cur = routine.title.trim()
                    if (suggestedTitle == null &&
                        (cur.isEmpty() || cur == "Entreno" || cur == "Nuevo entreno")
                    ) {
                        suggestedTitle = t.name
                    }
                    showWods = false
                },
                onDismiss = { showWods = false }
            )
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
    // R8 P1-2: tabla SERIE/ANTERIOR/REPS/RIR visible como iOS (no oculta).
    var setsExpanded by mutableStateOf(true)
    val invalidSetInputs=androidx.compose.runtime.mutableStateMapOf<Int,Boolean>()
    val rawSetInputs=androidx.compose.runtime.mutableStateMapOf<Int,Pair<PlannedSetDraft,Triple<String,String,String>>>()
    /** Valores iniciales de los campos uniformes: si no se tocan, las series
     *  originales (ids, RIR, no uniformes) se escriben tal cual. */
    var initialUniform = Triple(quantity.toString(), sets.toString(), weightKg?.toString() ?: "")
    var hadPlanned = planned != null
    val untouchedUniform: Boolean
        get() = hadPlanned && Triple(quantity, sets, weight) == initialUniform
}

/** Bloques de OCR al editor actual. Se conserva el JSON de cada movimiento (pesos M/H,
 * escala, notas, repScheme, REST) y NO se crea una nueva sesión. */
internal fun scannedRoutineBlockDraft(block: dev.repera.domain.RoutineBlock): BlockDraftUi {
    val draft = BlockDraftUi()
    draft.title = block.title
    draft.format = block.wodFormat?.raw ?: if (block.kind == dev.repera.domain.RoutineBlockKind.STRENGTH) "" else "amrap"
    draft.timeCap = (block.timeCapMinutes ?: 12).toString()
    draft.rounds = (block.rounds ?: 1).toString()
    draft.interval = (block.emomIntervalSeconds ?: 60).toString()
    draft.work = (block.workSeconds ?: 20).toString()
    draft.rest = (block.restSeconds ?: 10).toString()
    draft.roundRest = block.restBetweenRoundsSeconds?.toString() ?: ""
    if (block.kind == dev.repera.domain.RoutineBlockKind.STRENGTH) {
        block.exercises.forEach { item ->
            val sets = item.plannedSets.map { PlannedSetDraft(
                targetReps = it.targetReps, targetWeightKg = it.targetWeightKg,
                targetRir = it.targetRir, id = it.id,
                targetDurationSeconds = it.targetDurationSeconds
            ) }
            draft.entries.add(EntryUi(
                item.exerciseId, item.exerciseId, sets.firstOrNull()?.targetReps ?: 8,
                sets.size.coerceAtLeast(1), sets.firstOrNull()?.targetWeightKg,
                sets, item.id
            ))
        }
    } else {
        block.movements.forEach { move ->
            draft.entries.add(EntryUi(
                move.exerciseId ?: "", move.name,
                move.reps ?: move.calories ?: move.distanceMeters ?: 10,
                1, move.weightMaleKg, null, move.id,
                BoardScanImport.wireMovement(move).toString()
            ))
        }
    }
    return draft
}

internal class BlockDraftUi(info: RoutineBlockInfo? = null) {
    val blockId: String? = info?.id
    val sourceJson: String? = info?.sourceJson
    var title by mutableStateOf(info?.title ?: "")
    var format by mutableStateOf(info?.format ?: "")
    var timeCap by mutableStateOf((info?.timeCapMinutes ?: 12).toString())
    var rounds by mutableStateOf((info?.rounds ?: 1).toString())
    var interval by mutableStateOf((info?.emomIntervalSeconds ?: 60).toString())
    var work by mutableStateOf((info?.workSeconds ?: 20).toString())
    var rest by mutableStateOf((info?.restSeconds ?: 10).toString())
    /** For Time «Entre rondas» (iOS restBetweenRoundsSeconds). */
    var roundRest by mutableStateOf(
        info?.sourceJson?.let {
            runCatching { JSONObject(it).optInt("restBetweenRoundsSeconds") }
                .getOrNull()?.takeIf { s ->
                    JSONObject(info.sourceJson!!).has("restBetweenRoundsSeconds")
                }?.toString()
        } ?: ""
    )
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
        val between = roundRest.trim().takeIf { it.isNotEmpty() }?.toIntOrNull()
        if (roundRest.isNotBlank() && between == null) return null
        val scheme = if (format == "ladder" && ladder.isNotBlank()) {
            ladder.split("-", ",", " ").filter { it.isNotBlank() }
                .map { it.toIntOrNull() ?: return null }
        } else null
        val parsed = entries.map { entry ->
            if(entry.invalidSetInputs.values.any {it} || entry.invalidMovementInputs.values.any {it}) return null
            // Movimiento libre / REST: quantity/sets pueden ir en sourceJson.
            val isSourceOnly = entry.exerciseId.isBlank() && entry.sourceJson != null
            val base = RoutineDraftEntry(
                itemId = entry.itemId, sourceJson = entry.sourceJson, quantityUnit = entry.unit,
                exerciseId = entry.exerciseId,
                quantity = if (isSourceOnly) (entry.quantity.toIntOrNull() ?: 1)
                    else entry.quantity.toIntOrNull() ?: return null,
                sets = if (isSourceOnly) (entry.sets.toIntOrNull() ?: 1)
                    else entry.sets.toIntOrNull() ?: return null,
                weightKg = if (entry.weight.isBlank()) null
                    else dev.repera.domain.ReperaNumberFormat.parse(entry.weight) ?: return null
            )
            if ((format.isBlank() || format == "strength") && (entry.setsExpanded || entry.untouchedUniform))
                base.copy(plannedSets = entry.plannedSets.toList())
            else base
        }
        return RoutineBlockDraft(
            blockId = blockId, sourceJson = sourceJson,
            title = title.trim(), format = format, entries = parsed,
            timeCapMinutes = cap, rounds = rds, emomIntervalSeconds = intv,
            workSeconds = wk, restSeconds = rst, ladderScheme = scheme,
            restBetweenRoundsSeconds = between
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
    onOpenReorder: (() -> Unit)? = null,
    onOpenExercise: (String) -> Unit = {},
    effortUnit: String = "rir"
) {
    val isStrengthLike = block.format.isBlank() || block.format == "strength"
    var showExercisePicker by remember { mutableStateOf(false) }
    var showFreeMove by remember { mutableStateOf(false) }
    var showFormats by remember { mutableStateOf(false) }
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                BasicTextField(
                    value = block.title,
                    onValueChange = { block.title = it },
                    textStyle = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    ),
                    singleLine = true,
                    modifier = Modifier.weight(1f).testTag("plan_block_title")
                )
                var blockMenu by remember { mutableStateOf(false) }
                Box {
                    Surface(
                        onClick = { blockMenu = true },
                        shape = CircleShape,
                        color = Color.Transparent,
                        border = BorderStroke(
                            1.dp,
                            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.85f)
                        ),
                        modifier = Modifier
                            .size(34.dp)
                            .testTag("plan_block_menu")
                    ) {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Icon(
                                Icons.Outlined.MoreHoriz,
                                contentDescription = "Opciones del bloque",
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                    DropdownMenu(expanded = blockMenu, onDismissRequest = { blockMenu = false }) {
                        onOpenReorder?.let {
                            DropdownMenuItem(
                                text = { Text("Reordenar") },
                                modifier = Modifier.testTag("plan_reorder_open"),
                                onClick = { blockMenu = false; it() }
                            )
                        }
                        DropdownMenuItem(
                            text = { Text("Añadir ejercicio") },
                            modifier = Modifier.testTag("plan_block_add_exercise"),
                            onClick = { blockMenu = false; showExercisePicker = true }
                        )
                        onRemove?.let { remove ->
                            DropdownMenuItem(
                                text = { Text("Eliminar bloque", color = MaterialTheme.colorScheme.error) },
                                onClick = { blockMenu = false; remove() }
                            )
                        }
                    }
                }
            }
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable { showFormats = true }
                    .padding(vertical = 6.dp)
                    .testTag("plan_block_format"),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Formato", style = MaterialTheme.typography.bodyLarge)
                Spacer(Modifier.weight(1f))
                Text(
                    BlockFormatCatalog.title(block.format),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Icon(
                    Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (showFormats) {
                BlockFormatPickerSheet(
                    current = block.format,
                    onPick = { block.format = it; showFormats = false },
                    onDismiss = { showFormats = false }
                )
            }
            // Campos alineados con iOS fieldsForFormat (PlanView).
            when (block.format) {
                "amrap", "afap", "chipper", "buyInCashOut", "maxEffort" ->
                    NumberRow(block, "TIEMPO" to "timeCap")
                "forTime" ->
                    NumberRow(block, "Rondas" to "rounds", "TIEMPO" to "timeCap",
                        "Rondas (s)" to "roundRest")
                "roundsForQuality", "partner" ->
                    NumberRow(block, "Rondas" to "rounds", "TIEMPO" to "timeCap")
                "emom", "circuit" ->
                    NumberRow(block, "TIEMPO" to "timeCap", "Intervalo (s)" to "interval")
                "deathBy" ->
                    NumberRow(block, "Rondas" to "rounds", "Intervalo (s)" to "interval")
                "tabata" ->
                    NumberRow(block, "Trabajo (s)" to "work", "Descanso (s)" to "rest",
                        "Rondas" to "rounds")
                "ladder" -> {
                    NumberRow(block, "TIEMPO" to "timeCap")
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
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
                androidx.compose.runtime.key(entry) {
                    val ex = exercises.firstOrNull { it.id == entry.exerciseId }
                    EntryEditorRow(
                        entry = entry,
                        resolvedName = entry.name.ifBlank {
                            nameById[entry.exerciseId] ?: "Ejercicio"
                        },
                        isStrength = isStrengthLike,
                        mobility = ex?.sportTag == "Movilidad",
                        mobilityHold = ex?.mobilityHold == true,
                        weightedRepsOrMeters = ex?.let {
                            dev.repera.domain.ExerciseInput.supportsRepsOrMeters(it.name)
                        } == true,
                        unitChoices = ex?.let {
                            dev.repera.domain.AppleCardioUnits.allowsCalorieOrDistanceToggle(
                                it.name, it.equipment
                            )
                        } == true,
                        loadGuideProvider = loadGuideProvider,
                        onRemove = { block.entries.remove(entry) },
                        onOpenReorder = onOpenReorder,
                        onOpenDetail = entry.exerciseId.takeIf { it.isNotBlank() }?.let { id ->
                            { onOpenExercise(id) }
                        },
                        exerciseEntry = ex,
                        effortUnit = effortUnit
                    )
                }
            }
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
            WorkoutWODInsertActions(
                onExercise = { showExercisePicker = true },
                onRest = {
                    // Descanso siempre como entrada DENTRO del bloque (no bloque aparte).
                    val rest = EditorBlockOps.restMovement()
                    block.entries.add(
                        EntryUi(
                            "", "REST", 1, 1, null, null,
                            rest.getString("id"), rest.toString()
                        )
                    )
                },
                onFreeMovement = { showFreeMove = true }
            )
            if (showFreeMove) {
                FreeMovementDialog(
                    onDismiss = { showFreeMove = false },
                    onCreate = { name, reps, male, female ->
                        val move = EditorBlockOps.freeMovement(name, reps, male, female)
                        block.entries.add(
                            EntryUi(
                                "", name, reps, 1, male, null,
                                move.getString("id"), move.toString()
                            )
                        )
                        showFreeMove = false
                    }
                )
            }
            if (showExercisePicker) {
                ExercisePickerSheet(
                    exercises = exercises,
                    excluded = block.entries.map { it.exerciseId }.filter { it.isNotBlank() }.toSet(),
                    onPick = {
                        block.entries.add(EntryUi(it.id, it.name, 8, 3, null))
                        showExercisePicker = false
                    },
                    onDismiss = { showExercisePicker = false }
                )
            }
        }
    }
}

@Composable
internal fun WorkoutWODInsertActions(
    onExercise: () -> Unit,
    onRest: () -> Unit,
    onFreeMovement: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
        WorkoutInlineAddButton(
            label = "Ejercicio",
            icon = Icons.Outlined.AddCircle,
            onClick = onExercise,
            modifier = Modifier.testTag("plan_add_exercise")
        )
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(9.dp)
        ) {
            WorkoutInlineAddButton(
                label = "Descanso",
                icon = Icons.Outlined.PauseCircle,
                onClick = onRest,
                modifier = Modifier.weight(1f).testTag("plan_add_rest")
            )
            WorkoutInlineAddButton(
                label = "Movimiento libre",
                icon = Icons.Outlined.AddCircle,
                onClick = onFreeMovement,
                modifier = Modifier.weight(1f).testTag("plan_add_free_move")
            )
        }
    }
}

@Composable
internal fun WorkoutInlineAddButton(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Fondo negro y contenido verde tanto en modo día como noche.
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Black,
            contentColor = brandGreen
        ),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp))
            Text(label, fontWeight = FontWeight.SemiBold, maxLines = 1)
        }
    }
}

@Composable
internal fun PlanEditorActionRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Row(
        modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurface)
        Text(label, style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f))
        Icon(
            Icons.AutoMirrored.Outlined.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
internal fun FreeMovementDialog(
    onDismiss: () -> Unit,
    onCreate: (name: String, reps: Int, maleKg: Double?, femaleKg: Double?) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var reps by remember { mutableStateOf("10") }
    var male by remember { mutableStateOf("") }
    var female by remember { mutableStateOf("") }
    val trimmed = name.trim()
    val repsN = reps.toIntOrNull()
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Nuevo movimiento") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = name, onValueChange = { name = it },
                    label = { Text("Nombre") }, singleLine = true,
                    modifier = Modifier.fillMaxWidth().testTag("free_move_name")
                )
                OutlinedTextField(
                    value = reps, onValueChange = { reps = it },
                    label = { Text("Repeticiones") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth().testTag("free_move_reps")
                )
                OutlinedTextField(
                    value = male, onValueChange = { male = it },
                    label = { Text("Carga masculina · kg") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = female, onValueChange = { female = it },
                    label = { Text("Carga femenina · kg") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                enabled = trimmed.isNotEmpty() && repsN != null && repsN > 0,
                onClick = {
                    onCreate(
                        trimmed,
                        repsN!!,
                        male.takeIf { it.isNotBlank() }
                            ?.let { dev.repera.domain.ReperaNumberFormat.parse(it) },
                        female.takeIf { it.isNotBlank() }
                            ?.let { dev.repera.domain.ReperaNumberFormat.parse(it) }
                    )
                }
            ) { Text("Añadir") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } }
    )
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
                "roundRest" -> block.roundRest to { v: String -> block.roundRest = v }
                else -> block.rest to { v: String -> block.rest = v }
            }
            // iOS OGFormatNumberField: título TIEMPO + unidad «min» al lado del valor.
            val unit = when (key) {
                "timeCap" -> "min"
                else -> null
            }
            ReperaNumericField(
                value = value,
                onValueChange = setter,
                label = if (unit != null) "$label ($unit)" else label,
                allowsDecimal = false,
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
    mobility: Boolean = false,
    mobilityHold: Boolean = false,
    loadGuideProvider: (String, Int, Double?) -> LoadGuide?,
    onRemove: () -> Unit,
    unitChoices: Boolean = false,
    weightedRepsOrMeters: Boolean = false,
    onOpenReorder: (() -> Unit)? = null,
    onOpenDetail: (() -> Unit)? = null,
    exerciseEntry: ExerciseEntry? = null,
    effortUnit: String = "rir"
) {
    val isRest = entry.sourceJson?.let {
        runCatching { JSONObject(it).optBoolean("isRest") }.getOrDefault(false)
    } == true
    fun shortUnitLabel(u: String?): String = when (u) {
        "meters" -> "m"
        "calories" -> "cal"
        else -> "reps"
    }
    val entryUnit: String? = if (weightedRepsOrMeters)
        entry.unit ?: entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?.optString("quantityUnit")?.takeIf { it == "reps" || it == "meters" || it == "calories" }
            ?: dev.repera.domain.ExerciseInput.defaultQuantityUnit(entry.name, null)
    else null
    // Series siempre visibles (sin «Cerrar series»).
    entry.setsExpanded = true
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            val openDetail = onOpenDetail
            Row(
                Modifier
                    .weight(1f)
                    .then(
                        if (openDetail != null) Modifier.clickable(onClick = openDetail)
                        else Modifier
                    ),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (exerciseEntry != null) {
                    ExerciseListThumb(
                        name = exerciseEntry.name,
                        sportTag = exerciseEntry.sportTag,
                        aliases = emptyMap()
                    )
                } else if (!isRest) {
                    ExerciseListThumb(
                        name = resolvedName,
                        sportTag = null,
                        aliases = emptyMap()
                    )
                }
                Text(
                    if (isRest) "Descanso" else resolvedName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 2
                )
            }
            var entryMenu by remember { mutableStateOf(false) }
            Box {
                Surface(
                    onClick = { entryMenu = true },
                    shape = CircleShape,
                    color = Color.Transparent,
                    border = BorderStroke(
                        1.dp,
                        MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.85f)
                    ),
                    modifier = Modifier.size(34.dp).testTag("plan_entry_menu")
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Outlined.MoreHoriz,
                            contentDescription = "Opciones del ejercicio",
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
                DropdownMenu(expanded = entryMenu, onDismissRequest = { entryMenu = false }) {
                    onOpenReorder?.let {
                        DropdownMenuItem(
                            text = { Text("Reordenar") },
                            onClick = { entryMenu = false; it() }
                        )
                    }
                    DropdownMenuItem(
                        text = {
                            Text("Eliminar", color = MaterialTheme.colorScheme.error)
                        },
                        onClick = { entryMenu = false; onRemove() }
                    )
                }
            }
        }
        if (isRest) {
            ReperaNumericField(
                value = entry.restText(),
                onValueChange = { entry.setRestText(it) },
                label = "Segundos de descanso",
                allowsDecimal = false,
                testTag = "plan_rest_seconds"
            )
            return@Column
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ReperaNumericField(
                value = entry.quantity,
                onValueChange = { entry.quantity = it },
                label = if (isStrength) "Reps"
                    else if (weightedRepsOrMeters) shortUnitLabel(entryUnit)
                    else "Cantidad",
                allowsDecimal = false,
                modifier = Modifier.weight(1f)
            )
            if (isStrength) {
                ReperaNumericField(
                    value = entry.sets,
                    onValueChange = { entry.sets = it },
                    label = "Series",
                    allowsDecimal = false,
                    modifier = Modifier.weight(1f)
                )
                ReperaNumericField(
                    value = entry.weight,
                    onValueChange = { entry.weight = it },
                    label = "Peso kg",
                    allowsDecimal = true,
                    modifier = Modifier.weight(1f)
                )
            }
        }
        if (unitChoices || weightedRepsOrMeters) {
            val src = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
            val current = entry.unit
                ?: src?.optString("quantityUnit")?.takeIf {
                    it == "calories" || it == "meters" || it == "reps"
                }
                ?: if (weightedRepsOrMeters)
                    dev.repera.domain.ExerciseInput.defaultQuantityUnit(entry.name, null)
                else if (src?.has("distanceMeters") == true && !src.isNull("distanceMeters"))
                    "meters"
                else "calories"
            val options = if (weightedRepsOrMeters) {
                listOf("Repeticiones", "Metros")
            } else {
                listOf("Calorías", "Metros")
            }
            val selectedLabel = when (current) {
                "reps" -> "Repeticiones"
                "calories" -> "Calorías"
                else -> "Metros"
            }
            ReperaTopicSegmentedPicker(
                options = options,
                selected = selectedLabel,
                onSelected = { label ->
                    entry.unit = when (label) {
                        "Repeticiones" -> "reps"
                        "Calorías" -> "calories"
                        else -> "meters"
                    }
                },
                optionTestTag = { _, label ->
                    when (label) {
                        "Repeticiones" -> "plan_unit_reps"
                        "Calorías" -> "plan_unit_calories"
                        else -> "plan_unit_meters"
                    }
                }
            )
        }
        if (!isStrength) {
            WodMovementDetails(entry)
            entry.plannedSets.forEachIndexed { idx, set ->
                ReperaSwipeDeleteRow(
                    canDelete = entry.plannedSets.size > 1,
                    onDelete = {
                        entry.plannedSets.removeAt(idx)
                        syncWodPlannedSets(entry)
                    }
                ) {
                    Row(
                        Modifier.padding(vertical = 2.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        ReperaNumericField(
                            value = set.targetReps.toString(),
                            onValueChange = { v ->
                                val reps = v.filter { it.isDigit() }.toIntOrNull()?.coerceIn(1, 10000)
                                    ?: return@ReperaNumericField
                                entry.plannedSets[idx] = set.copy(targetReps = reps)
                                syncWodPlannedSets(entry)
                            },
                            label = "Reps",
                            allowsDecimal = false,
                            modifier = Modifier.weight(1f),
                            testTag = "plan_wod_set_reps_$idx"
                        )
                        ReperaNumericField(
                            value = set.targetWeightKg?.let {
                                if (it % 1.0 == 0.0) it.toInt().toString() else it.toString()
                            } ?: "",
                            onValueChange = { v ->
                                val parsed = if (v.isBlank()) null
                                else dev.repera.domain.ReperaNumberFormat.parse(v)
                                entry.plannedSets[idx] = set.copy(targetWeightKg = parsed)
                                syncWodPlannedSets(entry)
                            },
                            label = "Kg",
                            allowsDecimal = true,
                            modifier = Modifier.weight(1f),
                            testTag = "plan_wod_set_kg_$idx"
                        )
                    }
                }
            }
            OutlinedButton(
                enabled = entry.plannedSets.size < 20,
                onClick = {
                    val last = entry.plannedSets.lastOrNull()
                    entry.plannedSets.add(
                        PlannedSetDraft(
                            targetReps = last?.targetReps ?: (entry.quantity.toIntOrNull() ?: 8),
                            targetWeightKg = last?.targetWeightKg
                        )
                    )
                    syncWodPlannedSets(entry)
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = brandGreen),
                border = BorderStroke(1.dp, brandGreen)
            ) { Text("Añadir serie", modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center) }
        }
        if (isStrength) {
            val reference = entry.plannedSets.firstOrNull()
            val guide = remember(
                entry.exerciseId, reference?.targetReps, reference?.targetRir
            ) {
                loadGuideProvider(
                    entry.exerciseId,
                    reference?.targetReps ?: 8,
                    reference?.targetRir
                )
            }
            val hspuDeficit = dev.repera.domain.ExerciseInput.mode(
                entry.name, null, null, null
            ) == dev.repera.domain.ExerciseInputMode.HSPU_DEFICIT
            Row(
                Modifier.padding(top = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("SERIE", style = MaterialTheme.typography.labelSmall, modifier = Modifier.width(36.dp))
                Text("ANTERIOR", style = MaterialTheme.typography.labelSmall, modifier = Modifier.weight(0.9f))
                Text(
                    if (hspuDeficit) "DÉFICIT" else "KG",
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.weight(0.9f)
                )
                Text(
                    if (weightedRepsOrMeters) shortUnitLabel(entryUnit) else "REPS",
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.weight(0.9f)
                )
                Text(
                    dev.repera.domain.Effort.displayName(effortUnit).uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.weight(0.7f)
                )
            }
            val previousSessionSets = guide?.lastSession?.sets.orEmpty()
            entry.plannedSets.forEachIndexed { index, ps ->
                if (mobility) {
                    OutlinedTextField(
                        value = entry.durationText(index, mobilityHold),
                        onValueChange = { entry.setDurationText(index, it) },
                        singleLine = true,
                        label = { Text("Duración serie ${index + 1} (segundos)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth().testTag("plan_set_duration_$index")
                    )
                }
                val storedRirText = ps.targetRir?.let {
                    val display = dev.repera.domain.Effort.fromRIR(it, effortUnit)
                    if (display % 1.0 == 0.0) display.toInt().toString() else display.toString()
                } ?: ""
                val current = entry.rawSetInputs[index]?.takeIf { it.first == ps }?.second
                    ?: Triple(ps.targetReps.toString(), ps.targetWeightKg?.toString() ?: "", storedRirText)
                var repsText = current.first
                var kgText = current.second
                var rirText = current.third
                fun commit() {
                    val displayRir = rirText.takeIf { it.isNotBlank() }?.let {
                        dev.repera.domain.ReperaNumberFormat.parse(it)
                    }
                    val canonicalRir = displayRir?.let {
                        dev.repera.domain.Effort.toRIR(it, effortUnit)
                    }
                    val rirForParse = canonicalRir?.let {
                        if (it % 1.0 == 0.0) it.toInt().toString() else it.toString()
                    } ?: ""
                    val parsed = parsePlannedSetText(repsText, kgText, rirForParse, ps.id)
                    entry.invalidSetInputs[index] = parsed == null && rirText.isNotBlank()
                    val updated = parsed?.copy(
                        targetDurationSeconds = ps.targetDurationSeconds,
                        sourceJson = ps.sourceJson
                    )
                    if (updated != null) entry.plannedSets[index] = updated
                    entry.rawSetInputs[index] = (updated ?: ps) to Triple(repsText, kgText, rirText)
                }
                val previousLabel = previousSessionSets.getOrNull(index)?.let { prev ->
                    val kg = prev.weightKg?.let {
                        "${dev.repera.domain.ReperaNumberFormat.decimal(it)}×"
                    } ?: ""
                    "$kg${prev.reps}"
                } ?: "—"
                fun removeSetAt(index: Int) {
                    entry.plannedSets.removeAt(index)
                    val shifted = entry.invalidSetInputs.filterKeys { it != index }
                        .mapKeys { if (it.key > index) it.key - 1 else it.key }
                    entry.invalidSetInputs.clear(); entry.invalidSetInputs.putAll(shifted)
                    val rawShifted = entry.rawSetInputs.filterKeys { it != index }
                        .mapKeys { if (it.key > index) it.key - 1 else it.key }
                    entry.rawSetInputs.clear(); entry.rawSetInputs.putAll(rawShifted)
                    fun shiftedKey(key: String): String? {
                        if (!key.startsWith("duration:")) return key
                        val n = key.substringAfter(':').toInt()
                        return if (n == index) null else "duration:${if (n > index) n - 1 else n}"
                    }
                    val rawDurations = entry.rawMovementInputs.toMap()
                        .mapNotNull { (k, v) -> shiftedKey(k)?.let { it to v } }.toMap()
                    val invalidDurations = entry.invalidMovementInputs.toMap()
                        .mapNotNull { (k, v) -> shiftedKey(k)?.let { it to v } }.toMap()
                    entry.rawMovementInputs.clear(); entry.rawMovementInputs.putAll(rawDurations)
                    entry.invalidMovementInputs.clear(); entry.invalidMovementInputs.putAll(invalidDurations)
                }
                ReperaSwipeDeleteRow(
                    canDelete = entry.plannedSets.size > 1,
                    onDelete = { removeSetAt(index) }
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            "${index + 1}",
                            style = MaterialTheme.typography.labelLarge,
                            modifier = Modifier.width(36.dp)
                        )
                        Text(
                            previousLabel,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.weight(0.9f)
                        )
                        ReperaNumericField(
                            value = kgText,
                            onValueChange = { kgText = it; commit() },
                            label = "",
                            allowsDecimal = true,
                            modifier = Modifier.weight(0.9f)
                        )
                        ReperaNumericField(
                            value = repsText,
                            onValueChange = { repsText = it; commit() },
                            label = "",
                            allowsDecimal = false,
                            modifier = Modifier.weight(0.9f)
                        )
                        ReperaNumericField(
                            value = rirText,
                            onValueChange = { rirText = it; commit() },
                            label = "",
                            allowsDecimal = true,
                            modifier = Modifier.weight(0.7f)
                        )
                    }
                }
            }
            OutlinedButton(
                onClick = {
                    val last = entry.plannedSets.lastOrNull()
                    entry.plannedSets.add(
                        PlannedSetDraft(
                            targetReps = last?.targetReps ?: 8,
                            targetWeightKg = last?.targetWeightKg,
                            targetRir = last?.targetRir,
                            targetDurationSeconds = last?.targetDurationSeconds
                        )
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = brandGreen),
                border = BorderStroke(1.dp, brandGreen)
            ) {
                Text(
                    "Añadir serie",
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        }
    }
}

/** Escribe series WOD del plan en sourceJson (explicitPlannedSets + reps/repScheme). */
private fun syncWodPlannedSets(entry: EntryUi) {
    val o = entry.sourceJson?.let { runCatching { JSONObject(it) }.getOrNull() }
        ?: JSONObject().put("id", entry.itemId ?: java.util.UUID.randomUUID().toString())
            .put("exerciseId", entry.exerciseId).put("name", entry.name).put("isRest", false)
    val machine = o.has("calories") && !o.isNull("calories") ||
        o.has("distanceMeters") && !o.isNull("distanceMeters") && !o.has("reps")
    EditorBlockOps.writeSetsToMovement(o, EditorBlockOps.draftSetsToJson(entry.plannedSets), machine)
    entry.sourceJson = o.toString()
    entry.quantity = (entry.plannedSets.firstOrNull()?.targetReps ?: 10).toString()
    entry.sets = entry.plannedSets.size.toString()
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
