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
import androidx.compose.runtime.DisposableEffect
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
import androidx.activity.compose.BackHandler

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
    overview: StateOverview? = null,
    /** Arranque del reloj de bloque libre tras el sheet (paridad iOS). */
    onLaunchManualClock: (ManualBlockTimerConfig) -> Unit = {},
    loadGuideProvider: (String, Int, Double?) -> LoadGuide? = { _, _, _ -> null },
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
    var showReview by remember(workout.id) { mutableStateOf(false) }
    val nameById = remember(catalog) { catalog.associate { it.id to it.name } }
    val hasMoreExercises = workout.index + 1 < workout.total
    val inlineTitle = workout.title.ifBlank { "Entreno" }

    if (showReview) {
        ActiveWorkoutReviewScreen(
            workout = workout,
            catalog = catalog,
            busy = busy,
            onBack = { showReview = false },
            onSave = onFinish,
            onDiscard = onDiscard
        )
        return
    }

    val navSig = workout.navigationEntries.joinToString("|") {
        "${it.blockId}:${it.index}:${it.name}:${it.completed}"
    }
    val playBlocks = remember(workout.id, navSig) {
        mutableStateListOf<BlockDraftUi>().apply {
            val entry = activeEditorDraft()
            if (entry != null && entry.blocks.isNotEmpty()) {
                entry.blocks.forEach { add(BlockDraftUi(it)) }
            } else {
                add(
                    BlockDraftUi(
                        RoutineBlockInfo(
                            title = workout.wod?.title?.takeIf { it.isNotBlank() } ?: "Bloque",
                            format = workout.wod?.format.orEmpty()
                        )
                    )
                )
            }
        }
    }
    fun flushPlayPlan() {
        val entry = activeEditorDraft() ?: return
        val drafts = mutableListOf<RoutineBlockDraft>()
        for (block in playBlocks) {
            drafts.add(block.toDraft() ?: return)
        }
        onApplyActivePlan(workout.id, entry.id, drafts) { }
    }
    fun beginPlayReorder() {
        playReorderBlocks = playBlocks
        playReorderError = null
        showPlayReorder = true
    }
    fun commitPlayReorder() {
        if (playBlocks.any { it.toDraft() == null }) {
            playReorderError = "Revisa los campos numéricos del plan antes de reordenar."
            return
        }
        flushPlayPlan()
    }
    DisposableEffect(workout.id) {
        onDispose { flushPlayPlan() }
    }
    val indexesByBlockId = remember(workout.navigationEntries) {
        linkedMapOf<String, List<Int>>().also { map ->
            workout.navigationEntries.forEach { e ->
                val id = e.blockId.ifBlank { "ex-${e.index}" }
                map[id] = (map[id].orEmpty() + e.index)
            }
        }
    }
    val currentBlockId = workout.navigationEntries
        .firstOrNull { it.index == workout.index }
        ?.blockId
        ?.ifBlank { null }
    val configRounds = (workout.wod?.rounds
        ?: workout.pendingSets.size.takeIf { it > 0 }
        ?: 3).coerceAtLeast(1)
    if (showBlockTimer) {
        val setsLabel = workout.pendingSets.size.takeIf { it > 0 }?.let { "$it series" }
        val repsLabel = workout.prescribedQuantity?.let { "$it reps" }
        BlockTimerConfigSheet(
            rounds = configRounds,
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
                onLaunchManualClock(
                    ManualBlockTimerConfig(
                        workSeconds = work,
                        restSeconds = rest,
                        rounds = configRounds
                    )
                )
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
    var notesDraft by remember(workout.id, workout.notes) {
        mutableStateOf(workout.notes.orEmpty())
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
                onFinish = { showReview = true }
            )
        }
        // Meta como Crear/Editar: Lugar → Favorito → Notas (sin menú intermedio).
        item {
            val chosenPin = pin?.takeIf { it.hasChosenPlace }
            ReperaCard(
                modifier = Modifier.fillMaxWidth(),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                    WorkoutPlacePickerRow(
                        pin = chosenPin,
                        accountId = accountId,
                        onPinChange = onPinChange,
                        modifier = if (chosenPin == null) {
                            Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        } else {
                            Modifier.fillMaxWidth()
                        }
                    )
                    Column(
                        Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "Favorito",
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.weight(1f)
                            )
                            Switch(
                                checked = workout.isFavorite,
                                onCheckedChange = { on ->
                                    if (on && !workout.isFavorite) onSaveFavorite()
                                },
                                enabled = !busy && !workout.isFavorite,
                                colors = reperaSwitchColors(),
                                modifier = Modifier.testTag("play_favorite_switch")
                            )
                        }
                        WorkoutMetaNotesField(
                            value = notesDraft,
                            onValueChange = {
                                notesDraft = it
                                onUpdateNotes(it)
                            },
                            enabled = !busy
                        )
                    }
                }
            }
        }
        if (clockMinimized && timer != null) {
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
        // Misma card que Crear/Editar + timer a la izquierda de ⋯.
        itemsIndexed(playBlocks, key = { i, b -> b.blockId ?: "play-block-$i" }) { bi, block ->
            val sectionTitle = block.title.ifBlank { "Bloque ${bi + 1}" }
            val blockKey = block.blockId?.takeIf { it.isNotBlank() }
            val blockIndexes = when {
                blockKey != null -> indexesByBlockId[blockKey].orEmpty()
                playBlocks.size == 1 -> workout.navigationEntries.map { it.index }
                else -> emptyList()
            }
            val isCurrent = when {
                blockIndexes.isNotEmpty() -> blockIndexes.contains(workout.index)
                currentBlockId != null && blockKey != null -> currentBlockId == blockKey
                playBlocks.size == 1 -> true
                else -> bi == 0 && workout.index == 0
            }
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                ReperaSectionTitle(sectionTitle)
                BlockEditorCard(
                    block = block,
                    nameById = nameById,
                    exercises = catalog,
                    loadGuideProvider = loadGuideProvider,
                    onRemove = {
                        if (playBlocks.size > 1) {
                            playBlocks.removeAt(bi)
                            flushPlayPlan()
                        }
                    },
                    onOpenReorder = { beginPlayReorder() },
                    onOpenExercise = { /* ficha vía catálogo en editar; Play usa logging */ },
                    effortUnit = effortUnit,
                    onTimer = {
                        blockIndexes.firstOrNull()?.let { ix ->
                            if (ix != workout.index) onSelectExercise(ix)
                        }
                        flushPlayPlan()
                        openBlockClockOrConfig()
                    },
                    trailingContent = if (isCurrent) {
                        {
                            if (workout.wod != null) WodScoreCard(
                                active = workout, busy = busy, timer = timer,
                                onTimerAction = onTimerAction, onTimerTick = onTimerTick,
                                onSave = onWodScore, onMovement = onWodMovement,
                                onCompleteBlock = onCompleteWodBlock,
                                onReviseMovement = onReviseWodMovement,
                                onDeleteMovement = onDeleteWodMovement,
                                onFinish = onFinish, onDiscard = onDiscard,
                                onOpenClock = onOpenClock,
                                effortUnit = effortUnit,
                                embedded = true
                            )
                            else ActiveWorkoutCard(
                                effortUnit = effortUnit, weightUnit = weightUnit,
                                active = workout, busy = busy, onLogSet = onLogSet,
                                onLogDropSet = onLogDropSet,
                                onLogRestPauseSet = onLogRestPauseSet,
                                onReviseSet = onReviseSet, onDeleteSet = onDeleteSet,
                                onNext = onNext, onFinish = onFinish, onDiscard = onDiscard,
                                embedded = true
                            )
                        }
                    } else null
                )
            }
        }
        item {
            PlaySessionPlanFooter(
                busy = busy,
                workout = workout,
                playBlocks = playBlocks,
                onFlushPlan = { flushPlayPlan() },
                importableRoutines = importableRoutines,
                overview = overview,
                catalog = catalog
            )
        }
    }
}

/** Acciones de plan en Play (iOS WorkoutView al final del scroll). */
@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun PlaySessionPlanFooter(
    busy: Boolean,
    workout: ActiveWorkout,
    playBlocks: SnapshotStateList<BlockDraftUi>,
    onFlushPlan: () -> Unit,
    importableRoutines: List<RoutineEntry>,
    overview: StateOverview?,
    catalog: List<ExerciseEntry>
) {
    var showWods by remember { mutableStateOf(false) }
    var showFavorites by remember { mutableStateOf(false) }
    var showBoardScanner by remember { mutableStateOf(false) }
    var showExercisePicker by remember { mutableStateOf(false) }
    var showFreeMove by remember { mutableStateOf(false) }
    val favorites = importableRoutines.filter {
        it.isFavorite && it.scheduledDate == null && it.blocks.isNotEmpty()
    }

    fun mutateBlocks(transform: (SnapshotStateList<BlockDraftUi>) -> Unit) {
        transform(playBlocks)
        onFlushPlan()
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
            exerciseCatalog = catalog,
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
        }
        // ✓ siempre visible → resumen con Guardar / Descartar.
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

/** Resumen pre-guardado (paridad Live REVIEW / historial Apple): datos + Guardar / Descartar. */
@Composable
private fun ActiveWorkoutReviewScreen(
    workout: ActiveWorkout,
    catalog: List<ExerciseEntry>,
    busy: Boolean,
    onBack: () -> Unit,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
) {
    BackHandler(onBack = onBack)
    val context = androidx.compose.ui.platform.LocalContext.current
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    LazyColumn(
        Modifier.fillMaxSize().testTag("active_workout_review"),
        contentPadding = reperaScrollContentPadding(extraBottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ReperaToolbarGlassIconButton(
                    icon = Icons.Outlined.Close,
                    contentDescription = "Volver al entreno",
                    onClick = onBack,
                    enabled = !busy
                )
                Spacer(Modifier.weight(1f))
            }
        }
        item {
            Text(
                workout.title.ifBlank { "Entreno" },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                "Resumen del entreno",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        item {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                WorkoutSummaryTile(
                    title = "Ejercicios",
                    value = "${workout.total}",
                    icon = Icons.Outlined.List,
                    modifier = Modifier.weight(1f),
                    iconTint = brandGreen
                )
                WorkoutSummaryTile(
                    title = "Hechos",
                    value = "${workout.navigationEntries.count { it.completed }}",
                    icon = Icons.Outlined.Check,
                    modifier = Modifier.weight(1f),
                    iconTint = Color(0xFF0A84FF)
                )
            }
        }
        item {
            ReperaSectionTitle("Ejercicios")
            ReperaInsetGroupedList {
                workout.navigationEntries.forEachIndexed { index, entry ->
                    if (index > 0) {
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                        )
                    }
                    val resolved = remember(entry.name, catalog) {
                        catalog.firstOrNull { it.name.equals(entry.name, ignoreCase = true) }
                            ?: resolveWodExercise(entry.name, catalog, aliases)
                    }
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        WodExerciseThumbnail(resolved, aliases, size = 44.dp)
                        Column(Modifier.weight(1f)) {
                            Text(
                                entry.name.ifBlank { "Ejercicio" },
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                if (entry.completed) "Registrado" else "Pendiente",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
        item {
            Button(
                onClick = onSave,
                enabled = !busy,
                colors = reperaPrimaryButtonColors(),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("active_review_save")
            ) { Text("Guardar", fontWeight = FontWeight.Bold) }
            TextButton(
                onClick = onDiscard,
                enabled = !busy,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("active_review_discard")
            ) {
                Text("Descartar", color = MaterialTheme.colorScheme.error)
            }
        }
    }
}
