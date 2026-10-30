package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
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
        val rounds = (workout.wod?.rounds
            ?: workout.pendingSets.size.takeIf { it > 0 }
            ?: 3).coerceAtLeast(1)
        val setsLabel = workout.pendingSets.size.takeIf { it > 0 }?.let { "$it series" }
        val repsLabel = workout.prescribedQuantity?.let { "$it reps" }
        BlockTimerConfigSheet(
            rounds = rounds,
            initialWorkSeconds = blockWorkOverride,
            initialRestSeconds = blockRestOverride,
            exerciseName = workout.exerciseName,
            setsRepsSummary = listOfNotNull(setsLabel, repsLabel).joinToString(" · ")
                .ifBlank { null },
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
    val playGroups = remember(workout.id, workout.navigationEntries) {
        playBlockGroups(workout)
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
            ReperaFullscreenDialog(
                onDismissRequest = {
                    commitPlayReorder()
                    showPlayReorder = false
                    playReorderBlocks = null
                }
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
        contentPadding=reperaScrollContentPadding(extraBottom = 16.dp),
        verticalArrangement=Arrangement.spacedBy(12.dp)) {
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
                showExerciseNav = false,
                showBlockTimerInToolbar = false
            )
        }
        // Bloques como crear/editar: timer ○ · ⋯ ○ en cabecera (WorkoutView iOS).
        if (playGroups.isEmpty()) {
            item {
                if (workout.wod != null) WodScoreCard(
                    active = workout, busy = busy, timer = timer,
                    onTimerAction = onTimerAction, onTimerTick = onTimerTick, onSave = onWodScore,
                    onMovement = onWodMovement, onCompleteBlock = onCompleteWodBlock,
                    onReviseMovement = onReviseWodMovement, onDeleteMovement = onDeleteWodMovement,
                    onFinish = onFinish, onDiscard = onDiscard, onOpenClock = onOpenClock,
                    effortUnit = effortUnit
                )
                else ActiveWorkoutCard(
                    effortUnit = effortUnit, weightUnit = weightUnit, active = workout, busy = busy,
                    onLogSet = onLogSet, onLogDropSet = onLogDropSet,
                    onLogRestPauseSet = onLogRestPauseSet, onReviseSet = onReviseSet,
                    onDeleteSet = onDeleteSet, onNext = onNext, onFinish = onFinish,
                    onDiscard = onDiscard
                )
            }
        } else {
            itemsIndexed(playGroups, key = { _, g -> g.blockId }) { gi, group ->
                val entries = group.indexes.mapNotNull { ix ->
                    workout.navigationEntries.firstOrNull { it.index == ix }
                }
                val lines = entries.map { e ->
                    buildString {
                        append(e.name.ifBlank { "Ejercicio" })
                        if (e.completed) append(" · hecho")
                    }
                }
                val isCurrent = group.indexes.contains(workout.index)
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    PlayBlockHeaderCard(
                        title = group.title.ifBlank { "Bloque ${gi + 1}" },
                        subtitle = if (group.kind == "wod")
                            workout.wod?.format?.takeIf { it.isNotBlank() }?.let {
                                BlockFormatCatalog.title(it)
                            } else null,
                        exerciseLines = lines,
                        current = isCurrent,
                        busy = busy,
                        onTimer = {
                            if (group.indexes.isNotEmpty() &&
                                !group.indexes.contains(workout.index)
                            ) {
                                onSelectExercise(group.indexes.first())
                            }
                            openBlockClockOrConfig()
                        },
                        onReorder = { beginPlayReorder() },
                        onSelectExercise = onSelectExercise,
                        exerciseIndexes = group.indexes
                    )
                    if (isCurrent) {
                        if (workout.wod != null) WodScoreCard(
                            active = workout, busy = busy, timer = timer,
                            onTimerAction = onTimerAction, onTimerTick = onTimerTick,
                            onSave = onWodScore, onMovement = onWodMovement,
                            onCompleteBlock = onCompleteWodBlock,
                            onReviseMovement = onReviseWodMovement,
                            onDeleteMovement = onDeleteWodMovement,
                            onFinish = onFinish, onDiscard = onDiscard, onOpenClock = onOpenClock,
                            effortUnit = effortUnit
                        )
                        else ActiveWorkoutCard(
                            effortUnit = effortUnit, weightUnit = weightUnit,
                            active = workout, busy = busy, onLogSet = onLogSet,
                            onLogDropSet = onLogDropSet, onLogRestPauseSet = onLogRestPauseSet,
                            onReviseSet = onReviseSet, onDeleteSet = onDeleteSet,
                            onNext = onNext, onFinish = onFinish, onDiscard = onDiscard
                        )
                    }
                }
            }
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
@OptIn(ExperimentalMaterial3Api::class)
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
        ReperaModalBottomSheet(onDismissRequest = { showBoardScanner = false }) {
            BoardScanScreen(
                busy = busy,
                overview = overview,
                asSheet = true,
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
        FavoriteCatalogPickerSheet(
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
        WodCatalogPickerSheet(
            onPick = { t ->
                mutateBlocks { blocks ->
                    blocks.add(BlockDraftUi(EditorBlockOps.templateToBlockInfo(t, catalog)))
                }
                showWods = false
            },
            onDismiss = { showWods = false }
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
