package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material3.*
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

/** Dedicated workout route, not the dashboard above an off-screen active card. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ActiveWorkoutScreen(
    workout:ActiveWorkout,busy:Boolean,timer:WodTimerState?,onTimerAction:(String)->Unit,onTimerTick:()->Unit,
    onWodScore:(Int?,Int?,Int?)->Unit,onWodMovement:(Int,Int,Int,Double?)->Unit,
    onCompleteWodBlock:()->Unit,onReviseWodMovement:(String,Int,Double?)->Unit,onDeleteWodMovement:(String)->Unit,
    onLogSet:(Int,Double?,Double?,Boolean,String?,Int?,Int?,Boolean)->Unit,
    onLogDropSet:(Int,Double?,List<Pair<Int,Double?>>,Double?,Boolean)->Unit,
    onLogRestPauseSet:(List<Pair<Int,Int>>,Double?,Double?,Boolean)->Unit,
    onReviseSet:(String,Int,Double?,String?,Int?,Int?)->Unit,onDeleteSet:(String)->Unit,
    onNext:()->Unit,onFinish:()->Unit,onDiscard:()->Unit,onOpenClock:()->Unit,onBack:()->Unit,
    pin:dev.repera.domain.WorkoutLocationPin?,accountId:String,
    onPinChange:(dev.repera.domain.WorkoutLocationPin?)->Unit,
    effortUnit:String="rir",
    weightUnit:String="kg",
    onSelectExercise:(Int)->Unit = {},
    onUpdateNotes:(String)->Unit = {},
    onSaveFavorite:()->Unit = {},
    onEditPlan:()->Unit = {},
    activeEditorDraft: () -> RoutineEntry? = { null },
    onApplyActivePlan: (String, String, List<RoutineBlockDraft>, () -> Unit) -> Unit = { _, _, _, _ -> },
    catalog: List<ExerciseEntry> = emptyList(),
    onSubstituteExercise: (ExerciseEntry) -> Unit = {},
    onRemoveExercise: () -> Unit = {},
    clockMinimized: Boolean = false,
    onExpandClock: () -> Unit = {},
    /** R8 M1: acciones de plan al final del scroll (paridad iOS WorkoutView). */
    importableRoutines: List<RoutineEntry> = emptyList(),
    overview: StateOverview? = null
) {
    var showBlockTimer by remember(workout.id, workout.index) { mutableStateOf(false) }
    var blockWorkOverride by remember(workout.id, workout.index) {
        mutableStateOf(workout.wod?.workSeconds ?: 60)
    }
    var blockRestOverride by remember(workout.id, workout.index) {
        mutableStateOf(workout.wod?.restSeconds ?: workout.wod?.restBetweenRoundsSeconds ?: 0)
    }
    var showPlayReorder by remember { mutableStateOf(false) }
    var playReorderBlocks by remember { mutableStateOf<SnapshotStateList<BlockDraftUi>?>(null) }
    var playReorderError by remember { mutableStateOf<String?>(null) }
    val nameById = remember(catalog) { catalog.associate { it.id to it.name } }
    val hasMoreExercises = workout.index + 1 < workout.total
    val inlineTitle = workout.title.ifBlank { "Entreno" }

    fun beginPlayReorder() {
        val entry = activeEditorDraft() ?: return
        playReorderBlocks = mutableStateListOf<BlockDraftUi>().apply {
            entry.blocks.forEach { add(BlockDraftUi(it)) }
        }
        playReorderError = null
        showPlayReorder = playReorderBlocks != null
    }

    fun commitPlayReorder() {
        val blocks = playReorderBlocks ?: return
        val entry = activeEditorDraft() ?: return
        val drafts = mutableListOf<RoutineBlockDraft>()
        for (block in blocks) {
            drafts.add(block.toDraft() ?: run {
                playReorderError = "Revisa los campos numéricos del plan antes de reordenar."
                return
            })
        }
        onApplyActivePlan(workout.id, entry.id, drafts) { }
    }

    if (showBlockTimer) {
        val rounds = (workout.wod?.rounds ?: workout.prescribedQuantity ?: 3).coerceAtLeast(1)
        BlockTimerConfigSheet(
            rounds = rounds,
            initialWorkSeconds = blockWorkOverride,
            initialRestSeconds = blockRestOverride,
            onDismiss = { showBlockTimer = false },
            onStart = { work, rest ->
                blockWorkOverride = work
                blockRestOverride = rest
                showBlockTimer = false
                onTimerAction("start")
                onOpenClock()
            }
        )
    }
    /** iOS requestBlockClockStart: formatos con time cap / intervalo van al reloj; solo bloque libre abre el sheet. */
    fun openBlockClockOrConfig() {
        val wod = workout.wod
        val freeFormat = wod == null ||
            wod.format.isBlank() ||
            wod.format.equals("strength", ignoreCase = true)
        val hasPrescribed = (wod?.timeCapMinutes ?: 0) > 0 ||
            (wod?.intervalSeconds ?: 0) > 0 ||
            (wod?.workSeconds ?: 0) > 0
        if (!freeFormat || hasPrescribed) {
            onTimerAction("start")
            onOpenClock()
        } else {
            showBlockTimer = true
        }
    }
    if (showPlayReorder) {
        val blocks = playReorderBlocks
        if (blocks != null) {
            androidx.compose.ui.window.Dialog(
                onDismissRequest = {
                    commitPlayReorder()
                    showPlayReorder = false
                    playReorderBlocks = null
                },
                properties = androidx.compose.ui.window.DialogProperties(
                    usePlatformDefaultWidth = false
                )
            ) {
                PlanReorderFullscreen(
                    blocks = blocks,
                    nameById = nameById,
                    exercises = catalog,
                    onDone = {
                        commitPlayReorder()
                        showPlayReorder = false
                        playReorderBlocks = null
                    },
                    onMoveMessage = { msg -> if (msg != null) playReorderError = msg }
                )
            }
        }
    }
    playReorderError?.let { msg ->
        AlertDialog(
            onDismissRequest = { playReorderError = null },
            title = { Text("Reordenar") },
            text = { Text(msg) },
            confirmButton = { TextButton(onClick = { playReorderError = null }) { Text("OK") } }
        )
    }
    LazyColumn(Modifier.fillMaxSize().testTag("active_workout_screen"),
        contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {
            ActiveWorkoutToolbar(
                title = inlineTitle,
                busy = busy,
                index = workout.index,
                hasMoreExercises = hasMoreExercises,
                onClose = onBack,
                onPrevious = { onSelectExercise(workout.index - 1) },
                onNext = { onSelectExercise(workout.index + 1) },
                onFinish = onFinish
            )
        }
        if (clockMinimized && workout.wod != null && timer != null) {
            item {
                MinimizedWodClockBar(
                    active = workout,
                    timer = timer,
                    busy = busy,
                    onExpand = onExpandClock,
                    onTimerAction = onTimerAction,
                    onTimerTick = onTimerTick
                )
            }
        }
        item {
            ActiveSessionControls(
                active = workout,
                busy = busy,
                onSelect = onSelectExercise,
                onNotes = onUpdateNotes,
                onFavorite = onSaveFavorite,
                onEdit = onEditPlan,
                onReorder = { beginPlayReorder() },
                onDiscard = onDiscard,
                onConfigureBlockTimer = { openBlockClockOrConfig() },
                accountId = accountId,
                catalog = catalog,
                onSubstituteExercise = onSubstituteExercise,
                onRemoveExercise = onRemoveExercise,
                showExerciseNav = false
            )
        }
        item {
            if(workout.wod!=null) WodScoreCard(active=workout,busy=busy,timer=timer,
                onTimerAction=onTimerAction,onTimerTick=onTimerTick,onSave=onWodScore,
                onMovement=onWodMovement,onCompleteBlock=onCompleteWodBlock,
                onReviseMovement=onReviseWodMovement,onDeleteMovement=onDeleteWodMovement,
                onFinish=onFinish,onDiscard=onDiscard,onOpenClock=onOpenClock,
                effortUnit=effortUnit)
            else ActiveWorkoutCard(effortUnit=effortUnit,weightUnit=weightUnit,active=workout,busy=busy,onLogSet=onLogSet,
                onLogDropSet=onLogDropSet,onLogRestPauseSet=onLogRestPauseSet,
                onReviseSet=onReviseSet,onDeleteSet=onDeleteSet,onNext=onNext,
                onFinish=onFinish,onDiscard=onDiscard)
        }
        // R8 M1 / P1-7: botones negros + Añadir bloque / WOD / favorito / pizarra
        // (compare8/48-play-fin), antes de Lugar.
        item {
            PlaySessionPlanFooter(
                busy = busy,
                workout = workout,
                activeEditorDraft = activeEditorDraft,
                onApplyActivePlan = onApplyActivePlan,
                importableRoutines = importableRoutines,
                overview = overview,
                catalog = catalog
            )
        }
        // R5 P1-10: pin GPS anónimo no cuenta como lugar (iOS hasChosenPlace).
        val chosenPin = pin?.takeIf { it.hasChosenPlace }
        if (chosenPin == null) item { ReperaSectionTitle("Lugar") }
        item {
            if (chosenPin != null) {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    WorkoutPlacePickerRow(pin = chosenPin, accountId = accountId, onPinChange = onPinChange)
                }
            } else {
                WorkoutPlacePickerRow(pin = null, accountId = accountId, onPinChange = onPinChange)
            }
        }
    }
}

/** Acciones de plan en Play (iOS WorkoutView al final del scroll). */
@Composable
private fun PlaySessionPlanFooter(
    busy: Boolean,
    workout: ActiveWorkout,
    activeEditorDraft: () -> RoutineEntry?,
    onApplyActivePlan: (String, String, List<RoutineBlockDraft>, () -> Unit) -> Unit,
    importableRoutines: List<RoutineEntry>,
    overview: StateOverview?,
    catalog: List<ExerciseEntry>
) {
    var showWods by remember { mutableStateOf(false) }
    var showFavorites by remember { mutableStateOf(false) }
    var showBoardScanner by remember { mutableStateOf(false) }
    var showExercisePicker by remember { mutableStateOf(false) }
    var showFreeMove by remember { mutableStateOf(false) }
    val favorites = importableRoutines.filter { it.isFavorite && it.blocks.isNotEmpty() }

    fun mutateBlocks(transform: (SnapshotStateList<BlockDraftUi>) -> Unit) {
        val entry = activeEditorDraft() ?: return
        val blocks = mutableStateListOf<BlockDraftUi>().apply {
            entry.blocks.forEach { add(BlockDraftUi(it)) }
        }
        transform(blocks)
        val drafts = mutableListOf<RoutineBlockDraft>()
        for (block in blocks) {
            drafts.add(block.toDraft() ?: return)
        }
        onApplyActivePlan(workout.id, entry.id, drafts) { }
    }

    fun ensureTarget(blocks: SnapshotStateList<BlockDraftUi>): BlockDraftUi {
        if (blocks.isEmpty()) {
            blocks.add(BlockDraftUi(RoutineBlockInfo(title = "Bloque 1", format = "")))
        }
        return blocks.last()
    }

    if (showBoardScanner) {
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { showBoardScanner = false },
            properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.background)
            ) {
                BoardScanScreen(
                    busy = busy,
                    overview = overview,
                    onConfirm = { _, _, _ -> },
                    onBack = { showBoardScanner = false },
                    onImportBlocks = { imported ->
                        mutateBlocks { list ->
                            imported.forEach { list.add(scannedRoutineBlockDraft(it)) }
                        }
                        showBoardScanner = false
                    },
                    catalogOverride = catalog
                )
            }
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        WorkoutWODInsertActions(
            onExercise = { showExercisePicker = true },
            onRest = {
                mutateBlocks { blocks ->
                    val rest = EditorBlockOps.restMovement()
                    ensureTarget(blocks).entries.add(
                        EntryUi("", "REST", 1, 1, null, null, rest.getString("id"), rest.toString())
                    )
                }
            },
            onFreeMovement = { showFreeMove = true }
        )
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                PlanEditorActionRow(
                    icon = Icons.Outlined.ViewAgenda,
                    label = "Añadir bloque",
                    modifier = Modifier.testTag("play_add_block_row"),
                    onClick = {
                        mutateBlocks { blocks ->
                            val n = blocks.size + 1
                            blocks.add(BlockDraftUi(RoutineBlockInfo(title = "Bloque $n", format = "")))
                        }
                    },
                    enabled = !busy
                )
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                PlanEditorActionRow(
                    icon = Icons.Outlined.List,
                    label = "Elegir WOD",
                    modifier = Modifier.testTag("play_pick_wod"),
                    onClick = { showWods = true },
                    enabled = !busy
                )
                if (favorites.isNotEmpty()) {
                    HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    PlanEditorActionRow(
                        icon = Icons.Outlined.Star,
                        label = "Añadir favorito",
                        modifier = Modifier.testTag("play_add_favorite"),
                        onClick = { showFavorites = true },
                        enabled = !busy
                    )
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                PlanEditorActionRow(
                    icon = Icons.Outlined.AddCircle,
                    label = "Escanear pizarra",
                    modifier = Modifier.testTag("play_scan_board"),
                    onClick = { showBoardScanner = true },
                    enabled = !busy
                )
            }
        }
    }

    if (showFavorites) {
        AddFavoriteSheet(
            favorites = favorites,
            onPick = { src ->
                mutateBlocks { blocks ->
                    src.blocks.forEach { blocks.add(BlockDraftUi(EditorBlockOps.duplicateBlockInfo(it))) }
                }
                showFavorites = false
            },
            onDismiss = { showFavorites = false }
        )
    }
    if (showWods) {
        var query by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { showWods = false },
            confirmButton = { TextButton(onClick = { showWods = false }) { Text("Cancelar") } },
            title = { Text("Elegir WOD") },
            text = {
                Column {
                    OutlinedTextField(
                        value = query, onValueChange = { query = it }, singleLine = true,
                        label = { Text("Buscar") }, modifier = Modifier.fillMaxWidth()
                    )
                    androidx.compose.foundation.lazy.LazyColumn(Modifier.heightIn(max = 360.dp)) {
                        items(dev.repera.domain.CatalogWods.search(query).size) { i ->
                            val t = dev.repera.domain.CatalogWods.search(query)[i]
                            TextButton(onClick = {
                                mutateBlocks { blocks ->
                                    blocks.add(BlockDraftUi(EditorBlockOps.templateToBlockInfo(t, catalog)))
                                }
                                showWods = false
                            }) { Text(t.name + " · " + t.formatLabel) }
                        }
                    }
                }
            }
        )
    }
    if (showFreeMove) {
        FreeMovementDialog(
            onDismiss = { showFreeMove = false },
            onCreate = { name, reps, male, female ->
                val move = EditorBlockOps.freeMovement(name, reps, male, female)
                mutateBlocks { blocks ->
                    ensureTarget(blocks).entries.add(
                        EntryUi("", name, reps, 1, male, null, move.getString("id"), move.toString())
                    )
                }
                showFreeMove = false
            }
        )
    }
    if (showExercisePicker) {
        ExercisePickerSheet(
            exercises = catalog,
            excluded = emptySet(),
            onPick = { ex ->
                mutateBlocks { blocks ->
                    ensureTarget(blocks).entries.add(EntryUi(ex.id, ex.name, 8, 3, null))
                }
                showExercisePicker = false
            },
            onDismiss = { showExercisePicker = false }
        )
    }
}

/** Paridad `WorkoutView.workoutToolbarContents`: cerrar circular, título inline, chevrons y ✓ verde. */
@Composable
private fun ActiveWorkoutToolbar(
    title: String,
    busy: Boolean,
    index: Int,
    hasMoreExercises: Boolean,
    onClose: () -> Unit,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ReperaToolbarGlassIconButton(
            icon = Icons.Outlined.Close,
            contentDescription = "Cerrar",
            onClick = onClose,
            enabled = !busy,
            modifier = Modifier.testTag("active_workout_back")
        )
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onBackground,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )
        // R8 P1-13 / C3: chevrons en círculo glass (iOS), no IconButton plano.
        if (index > 0) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.KeyboardArrowLeft,
                contentDescription = "Ejercicio anterior",
                onClick = onPrevious,
                enabled = !busy,
                modifier = Modifier.testTag("active_previous")
            )
        }
        if (hasMoreExercises) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = "Ejercicio siguiente",
                onClick = onNext,
                enabled = !busy,
                modifier = Modifier.testTag("active_navigate_next")
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .testTag("active_toolbar_finish"),
                contentAlignment = Alignment.Center
            ) {
                androidx.compose.material3.Surface(
                    onClick = onFinish,
                    enabled = !busy,
                    shape = CircleShape,
                    color = brandGreen,
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Outlined.Check,
                            contentDescription = "Terminar entreno",
                            tint = Color.Black,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}
