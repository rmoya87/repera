package dev.repera.mobile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.List
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.ViewAgenda
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material3.*
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.activity.compose.BackHandler
import androidx.compose.material3.SnackbarHostState
import kotlinx.coroutines.launch

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
    onReviseSet:(String,Int,Double?,String?,Int?,Int?)->Unit,
    onDeleteSet:(String)->Unit,
    onRestoreDeletedSet:(WorkoutSetSummary,Int)->Unit={ _,_->},
    onRemovePendingSet:(String)->Unit={},
    onRestorePendingSet:(PendingSetSummary,Int)->Unit={ _,_->},
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
    /** Finalizar desde el dock: congela el reloj y oculta la franja (conserva Formato). */
    onFinishMinimizedClock: () -> Unit = {},
    /**
     * Tras cambiar Formato en Play (p. ej. libre → Tabata): invalidar reloj
     * stale y persistir el plan para que el temporizador use la nueva modalidad.
     */
    onBlockFormatChanged: () -> Unit = {},
    /** Config del reloj de bloque libre; hace falta para la barra minimizada sin WOD. */
    manualClockConfig: ManualBlockTimerConfig? = null,
    /** Prescripción al abrir Tabata/EMOM/… (dock + reloj sin depender de wod). */
    launchClockConfig: BlockClockLaunchConfig? = null,
    /** R8 M1: acciones de plan al final del scroll (paridad iOS WorkoutView). */
    importableRoutines: List<RoutineEntry> = emptyList(),
    overview: StateOverview? = null,
    /** Arranque del reloj de bloque libre tras el sheet (paridad iOS). */
    onLaunchManualClock: (ManualBlockTimerConfig) -> Unit = {},
    /** Abre el reloj con prescripción del bloque (Tabata/EMOM/…), sin esperar flush. */
    onLaunchBlockClock: (BlockClockLaunchConfig) -> Unit = {},
    loadGuideProvider: (String, Int, Double?) -> LoadGuide? = { _, _, _ -> null },
    onWodMeasuredScore: (Double, String) -> Unit = { _, _ -> },
    onWodPhaseOutcome: (String, Int, Int?, Int) -> Unit = { _, _, _, _ -> },
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
    var showFinishSummary by remember(workout.id) { mutableStateOf(false) }
    var showPlayWods by remember { mutableStateOf(false) }
    var showPlayFavorites by remember { mutableStateOf(false) }
    var showPlayBoardScanner by remember { mutableStateOf(false) }
    var confirmCancelWorkout by remember { mutableStateOf(false) }
    val nameById = remember(catalog) { catalog.associate { it.id to it.name } }
    val hasMoreExercises = workout.index + 1 < workout.total
    val inlineTitle = workout.title.ifBlank { "Entreno" }

    val completedSets = workout.sessionLiveSetCount
    val totalSets = workout.sessionPlannedSetCount
    val volumeKg = workout.sessionLiveVolumeKg
    val elapsedSeconds = workout.sessionStartedAtEpochMillis?.let { started ->
        ((System.currentTimeMillis() - started) / 1000).toInt().coerceAtLeast(0)
    } ?: 0
    WorkoutFinishSummarySheet(
        visible = showFinishSummary,
        title = inlineTitle,
        elapsedSeconds = elapsedSeconds,
        completedSets = completedSets,
        totalSets = totalSets,
        volumeKg = volumeKg,
        warning = null,
        onDismiss = { showFinishSummary = false },
        onSave = {
            showFinishSummary = false
            onFinish()
        },
        onKeepTraining = { showFinishSummary = false }
    )

    val context = LocalContext.current
    // Sin `completed`: marcar series no debe recrear todos los BlockDraftUi.
    // Clave solo por sesión: un navSig strength→wod no debe pisar Formato EMOM
    // en memoria con un draft aún vacío (flush async / busy).
    val navSig = workout.navigationEntries.joinToString("|") {
        "${it.blockId}:${it.index}:${it.name}"
    }
    fun blockFormatKey(block: BlockDraftUi): String =
        block.blockId?.takeIf { it.isNotBlank() } ?: block.listKey

    fun applyFormatSnapshot(block: BlockDraftUi, snap: PlayBlockFormatSnapshot) {
        block.format = snap.format
        block.work = snap.workSeconds.toString()
        block.rest = snap.restSeconds.toString()
        block.rounds = snap.rounds.toString()
        block.interval = snap.intervalSeconds.toString()
        block.timeCap = snap.timeCapMinutes.toString()
    }

    fun snapshotFromBlock(block: BlockDraftUi): PlayBlockFormatSnapshot =
        PlayBlockFormatSnapshot(
            format = block.format,
            workSeconds = block.work.toIntOrNull() ?: 20,
            restSeconds = block.rest.toIntOrNull() ?: 10,
            rounds = block.rounds.toIntOrNull() ?: 8,
            intervalSeconds = block.interval.toIntOrNull() ?: 60,
            timeCapMinutes = block.timeCap.toIntOrNull() ?: 12,
        )

    fun persistFormatOverride(block: BlockDraftUi) {
        PlayBlockFormatStore.save(
            context, accountId, workout.id, blockFormatKey(block),
            snapshotFromBlock(block),
        )
    }

    val playBlocks = remember(workout.id) {
        mutableStateListOf<BlockDraftUi>().apply {
            val entry = activeEditorDraft()
            if (entry != null && entry.blocks.isNotEmpty()) {
                entry.blocks.forEach { info ->
                    val draft = BlockDraftUi(info)
                    // Preferir Formato guardado en Play (sobrevive al remount del reloj).
                    val key = draft.blockId?.takeIf { it.isNotBlank() } ?: draft.listKey
                    PlayBlockFormatStore.read(context, accountId, workout.id, key)
                        ?.let { applyFormatSnapshot(draft, it) }
                    add(draft)
                }
            } else {
                val draft = BlockDraftUi(
                    RoutineBlockInfo(
                        title = workout.wod?.title?.takeIf { it.isNotBlank() } ?: "Bloque",
                        format = workout.wod?.format.orEmpty()
                    )
                )
                PlayBlockFormatStore.read(context, accountId, workout.id, draft.listKey)
                    ?.let { applyFormatSnapshot(draft, it) }
                add(draft)
            }
        }
    }
    // Tras apply: fusionar draft → UI sin borrar un Formato más nuevo (store/memoria).
    LaunchedEffect(workout.id, navSig, workout.wod?.format) {
        val entry = activeEditorDraft() ?: return@LaunchedEffect
        if (entry.blocks.isEmpty()) return@LaunchedEffect
        var needsFlush = false
        entry.blocks.forEachIndexed { index, info ->
            val existing = playBlocks.getOrNull(index)
            if (existing == null) {
                val draft = BlockDraftUi(info)
                PlayBlockFormatStore.read(context, accountId, workout.id, blockFormatKey(draft))
                    ?.let { applyFormatSnapshot(draft, it) }
                playBlocks.add(draft)
                return@forEachIndexed
            }
            val key = blockFormatKey(existing)
            val stored = PlayBlockFormatStore.read(context, accountId, workout.id, key)
            val draftFormat = info.format
            val memFormat = existing.format
            when {
                stored != null &&
                    (draftFormat.isBlank() || draftFormat == "strength" ||
                        !draftFormat.equals(stored.format, ignoreCase = true)) -> {
                    // Sesión aún sin Formato: reaplicar store (p. ej. tras Finalizar reloj).
                    applyFormatSnapshot(existing, stored)
                    needsFlush = true
                }
                memFormat.isNotBlank() && memFormat != "strength" &&
                    (draftFormat.isBlank() || draftFormat == "strength") -> {
                    persistFormatOverride(existing)
                    needsFlush = true
                }
                draftFormat.isNotBlank() && draftFormat != "strength" &&
                    draftFormat != memFormat -> {
                    existing.format = draftFormat
                    if (info.timeCapMinutes > 0) existing.timeCap = info.timeCapMinutes.toString()
                    if (info.rounds > 0) existing.rounds = info.rounds.toString()
                    if (info.workSeconds > 0) existing.work = info.workSeconds.toString()
                    if (info.restSeconds >= 0 && draftFormat.equals("tabata", ignoreCase = true)) {
                        existing.rest = info.restSeconds.toString()
                    }
                    if (info.emomIntervalSeconds > 0) {
                        existing.interval = info.emomIntervalSeconds.toString()
                    }
                }
            }
        }
        while (playBlocks.size > entry.blocks.size) {
            playBlocks.removeAt(playBlocks.lastIndex)
        }
        // Una sola re-aplicación por montaje / cambio de plan vacío.
        if (needsFlush) {
            playBlocks.forEach { it.ensurePlayDraftable() }
            val drafts = playBlocks.mapNotNull { it.toDraft() }
            val editor = activeEditorDraft()
            if (editor != null && drafts.size == playBlocks.size) {
                onApplyActivePlan(workout.id, editor.id, drafts) { }
            }
        }
    }
    /** Evita flush en onDispose al navegar a reloj (carrera con busy / Formato). */
    var suppressDisposeFlush by remember(workout.id) { mutableStateOf(false) }
    fun flushPlayPlan() {
        val entry = activeEditorDraft() ?: return
        playBlocks.forEach { it.ensurePlayDraftable() }
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
        onDispose {
            if (!suppressDisposeFlush) flushPlayPlan()
        }
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
                suppressDisposeFlush = true
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
    /**
     * iOS `requestBlockClockStart`: Tabata/EMOM/AMRAP/… van al reloj con la
     * prescripción del bloque. Solo fuerza/libre sin duración pide el sheet.
     * Abre al instante con [BlockClockLaunchConfig] (no espera flush/`busy`).
     */
    fun openBlockClockOrConfig(blockUi: BlockDraftUi) {
        val format = blockUi.format.takeIf { it.isNotBlank() }
            ?: workout.wod?.format.orEmpty()
        val freeFormat = format.isBlank() || format.equals("strength", ignoreCase = true)
        // Tabata/EMOM/…: siempre seed + launch del draft (nunca sheet libre).
        if (!freeFormat) {
            when (format.lowercase()) {
                "tabata" -> {
                    if (blockUi.work.toIntOrNull() == null ||
                        (blockUi.work.toIntOrNull() ?: 0) <= 0
                    ) blockUi.work = "20"
                    if (blockUi.rest.toIntOrNull() == null) blockUi.rest = "10"
                    if (blockUi.rounds.toIntOrNull() == null ||
                        (blockUi.rounds.toIntOrNull() ?: 0) <= 0
                    ) blockUi.rounds = "8"
                }
                "emom", "amrap" -> {
                    if (blockUi.timeCap.isBlank()) blockUi.timeCap = "12"
                }
                "forTime" -> {
                    if (blockUi.rounds.toIntOrNull() == null ||
                        blockUi.rounds.toIntOrNull() == 1
                    ) blockUi.rounds = "4"
                    if (blockUi.timeCap.isBlank()) blockUi.timeCap = "12"
                }
            }
            val stations = blockUi.entries.count {
                val rest = it.sourceJson?.let { raw ->
                    runCatching { org.json.JSONObject(raw).optBoolean("isRest") }.getOrDefault(false)
                } == true
                !rest && it.exerciseId.isNotBlank()
            }.coerceAtLeast(1)
            val launch = BlockClockLaunchConfig.fromBlockDraft(blockUi, stations = stations)
            suppressDisposeFlush = true
            blockUi.ensurePlayDraftable()
            persistFormatOverride(blockUi)
            onLaunchBlockClock(launch)
            flushPlayPlan()
            return
        }
        val interval = workout.wod?.intervalSeconds ?: 0
        val hasExplicitInterval = interval > 0 &&
            (interval != 60 || format.equals("strength", ignoreCase = true))
        val hasPrescribedDuration =
            (workout.wod?.timeCapMinutes ?: 0) > 0 ||
                hasExplicitInterval ||
                (workout.wod?.workSeconds ?: 0) > 0
        if (!hasPrescribedDuration) {
            showBlockTimer = true
            return
        }
        val stations = blockUi.entries.count {
            val rest = it.sourceJson?.let { raw ->
                runCatching { org.json.JSONObject(raw).optBoolean("isRest") }.getOrDefault(false)
            } == true
            !rest && it.exerciseId.isNotBlank()
        }.coerceAtLeast(1)
        val launch = BlockClockLaunchConfig.fromBlockDraft(blockUi, stations = stations)
        suppressDisposeFlush = true
        onLaunchBlockClock(launch)
        flushPlayPlan()
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
    val snackbarHostState = remember { SnackbarHostState() }
    val snackbarScope = rememberCoroutineScope()
    fun offerUndo(message: String, undo: () -> Unit) {
        snackbarScope.launch {
            showWorkoutUndoSnackbar(snackbarHostState, message, undo)
        }
    }
    val deleteSetWithUndo: (String) -> Unit = { id ->
        val idx = workout.sets.indexOfFirst { it.id == id }
        val snap = workout.sets.getOrNull(idx)
        onDeleteSet(id)
        if (snap != null && idx >= 0) {
            offerUndo("Serie ${idx + 1} eliminada") {
                onRestoreDeletedSet(snap, idx)
            }
        }
    }
    val removePendingWithUndo: (String) -> Unit = { id ->
        val idx = workout.pendingSets.indexOfFirst { it.id == id }
        val snap = workout.pendingSets.getOrNull(idx)
        onRemovePendingSet(id)
        if (snap != null && idx >= 0) {
            val label = workout.sets.size + idx + 1
            offerUndo("Serie $label eliminada") {
                onRestorePendingSet(snap, idx)
            }
        }
    }
    Box(Modifier.fillMaxSize()) {
    CompositionLocalProvider(LocalRemovePendingSet provides removePendingWithUndo) {
    LazyColumn(Modifier.fillMaxSize().testTag("active_workout_screen"),
        contentPadding=reperaScrollContentPadding(extraBottom = 96.dp),
        verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {
            ActiveWorkoutToolbar(
                title = inlineTitle,
                busy = busy,
                index = workout.index,
                total = workout.total,
                hasMoreExercises = hasMoreExercises,
                onClose = onBack,
                onPrevious = { onSelectExercise(workout.index - 1) },
                onNext = { onSelectExercise(workout.index + 1) },
                onFinish = { showFinishSummary = true },
                showExerciseNav = false,
                showFinishInToolbar = false,
                onEditPlan = onEditPlan,
                onAddBlock = {
                    val n = playBlocks.size + 1
                    playBlocks.add(BlockDraftUi(RoutineBlockInfo(title = "Bloque $n", format = "")))
                    flushPlayPlan()
                },
                onPickWod = { showPlayWods = true },
                onScanBoard = { showPlayBoardScanner = true },
                onReorderStructure = { beginPlayReorder() },
                onToggleFavorite = {
                    if (!workout.isFavorite) onSaveFavorite()
                },
                isFavorite = workout.isFavorite,
                onCancelWorkout = { confirmCancelWorkout = true },
                startedLabel = workout.sets.firstOrNull()?.let { "En curso" }
            )
        }
        item {
            WorkoutPlayProgressHeader(
                completedSets = completedSets,
                totalSets = totalSets,
                volumeKg = volumeKg,
                elapsedSeconds = elapsedSeconds,
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }
        // Cabecera de bloque + entradas Lazy + logging del actual (fuera del card).
        playBlocks.forEachIndexed { bi, block ->
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
            val selectedLocal = blockIndexes.indexOf(workout.index).takeIf { it >= 0 }
            item(key = "play-block-${block.blockId ?: bi}") {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (playBlocks.size > 1) {
                        ReperaSectionTitle(block.title.ifBlank { "Bloque ${bi + 1}" })
                    }
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
                        onOpenExercise = { },
                        effortUnit = effortUnit,
                        playCompactEntries = true,
                        includeEntries = true,
                        includeFooterActions = true,
                        selectedEntryIndex = selectedLocal,
                        onSelectEntryIndex = { ei ->
                            blockIndexes.getOrNull(ei)?.let { onSelectExercise(it) }
                        },
                        onFormatChanged = {
                            // Libre → EMOM/Tabata/…: store local + flush encolado + invalidar reloj.
                            block.ensurePlayDraftable()
                            persistFormatOverride(block)
                            flushPlayPlan()
                            onBlockFormatChanged()
                        },
                        onTimer = {
                            openBlockClockOrConfig(block)
                            blockIndexes.firstOrNull()?.let { ix ->
                                if (ix != workout.index) onSelectExercise(ix)
                            }
                        },
                        trailingContent = if (isCurrent) {
                            {
                                if (workout.wod != null) WodScoreCard(
                                    active = workout, busy = busy, timer = timer,
                                    onTimerAction = onTimerAction, onTimerTick = onTimerTick,
                                    onSave = onWodScore,
                                    onMeasuredScore = onWodMeasuredScore,
                                    onPhaseOutcome = onWodPhaseOutcome,
                                    onMovement = onWodMovement,
                                    onCompleteBlock = onCompleteWodBlock,
                                    onReviseMovement = onReviseWodMovement,
                                    onDeleteMovement = onDeleteWodMovement,
                                    onFinish = onFinish, onDiscard = onDiscard,
                                    onOpenClock = onOpenClock,
                                    effortUnit = effortUnit,
                                    embedded = true,
                                    loadGuideProvider = loadGuideProvider,
                                )
                                else ActiveWorkoutCard(
                                    effortUnit = effortUnit, weightUnit = weightUnit,
                                    active = workout, busy = busy, onLogSet = onLogSet,
                                    onLogDropSet = onLogDropSet,
                                    onLogRestPauseSet = onLogRestPauseSet,
                                    onReviseSet = onReviseSet, onDeleteSet = deleteSetWithUndo,
                                    onNext = onNext, onFinish = onFinish, onDiscard = onDiscard,
                                    embedded = true,
                                    loadGuideProvider = loadGuideProvider,
                                )
                            }
                        } else null,
                        onOfferUndo = { message, undo ->
                            flushPlayPlan()
                            offerUndo(message) {
                                undo()
                                flushPlayPlan()
                            }
                        },
                    )
                }
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
                catalog = catalog,
                showWods = showPlayWods,
                onShowWodsChange = { showPlayWods = it },
                showFavorites = showPlayFavorites,
                onShowFavoritesChange = { showPlayFavorites = it },
                showBoardScanner = showPlayBoardScanner,
                onShowBoardScannerChange = { showPlayBoardScanner = it },
                showSessionPlanActions = false,
            )
        }
        item(key = "play-notes") {
            ReperaCard(
                modifier = Modifier.fillMaxWidth(),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
            ) {
                Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                    Text(
                        "Notas del entreno",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
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
        item(key = "play-finish-cta") {
            Button(
                onClick = { showFinishSummary = true },
                enabled = !busy,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
                    .height(52.dp)
                    .testTag("play_finish_button"),
                shape = CircleShape,
                colors = ButtonDefaults.buttonColors(
                    containerColor = brandGreen,
                    contentColor = Color.Black
                )
            ) {
                Text("Terminar entreno", fontWeight = FontWeight.SemiBold)
            }
        }
    }
    }
        val showMinimizedClock = clockMinimized && timer != null &&
            (workout.wod != null || manualClockConfig != null || launchClockConfig != null)
        val reduceMotion = remember(context) { reperaReduceMotion(context) }
        val dockEase = CubicBezierEasing(0.23f, 1f, 0.32f, 1f)
        val dockFade = tween<Float>(
            durationMillis = if (reduceMotion) 100 else 200,
            easing = dockEase
        )
        val dockSlide = tween<IntOffset>(
            durationMillis = if (reduceMotion) 1 else 220,
            easing = dockEase
        )
        AnimatedVisibility(
            visible = showMinimizedClock,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(
                    start = 12.dp,
                    end = 12.dp,
                    bottom = LocalReperaTabBarInset.current + 12.dp
                ),
            enter = fadeIn(dockFade) + slideInVertically(
                animationSpec = dockSlide,
                initialOffsetY = { full -> if (reduceMotion) 0 else full / 2 }
            ),
            exit = fadeOut(dockFade) + slideOutVertically(
                animationSpec = dockSlide,
                targetOffsetY = { full -> if (reduceMotion) 0 else full / 2 }
            )
        ) {
            MinimizedWodClockBar(
                active = workout,
                timer = timer,
                busy = busy,
                onExpand = {
                    suppressDisposeFlush = true
                    onExpandClock()
                },
                onTimerAction = onTimerAction,
                onTimerTick = onTimerTick,
                onFinish = onFinishMinimizedClock,
                manualConfig = manualClockConfig,
                launchConfig = launchClockConfig,
            )
        }
        WorkoutUndoSnackbarHost(
            snackbarHostState,
            Modifier.align(Alignment.BottomCenter).padding(
                start = 16.dp,
                end = 16.dp,
                bottom = if (showMinimizedClock) LocalReperaTabBarInset.current + 88.dp else 16.dp
            )
        )
        if (confirmCancelWorkout) {
            ReperaConfirmSheet(
                title = "Cancelar entreno",
                message = "Se descartará la sesión en curso. Esta acción no se puede deshacer.",
                confirmTitle = "Cancelar entreno",
                onConfirm = {
                    confirmCancelWorkout = false
                    onDiscard()
                },
                onCancel = { confirmCancelWorkout = false },
                confirmDestructive = true
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
    catalog: List<ExerciseEntry>,
    showWods: Boolean = false,
    onShowWodsChange: (Boolean) -> Unit = {},
    showFavorites: Boolean = false,
    onShowFavoritesChange: (Boolean) -> Unit = {},
    showBoardScanner: Boolean = false,
    onShowBoardScannerChange: (Boolean) -> Unit = {},
    /** Si false, las acciones de sesión viven solo en el menú ⋮ (paridad iOS). */
    showSessionPlanActions: Boolean = true,
) {
    val favorites = importableRoutines.filter {
        it.isFavorite && it.scheduledDate == null && it.blocks.isNotEmpty()
    }

    fun mutateBlocks(transform: (SnapshotStateList<BlockDraftUi>) -> Unit) {
        transform(playBlocks)
        onFlushPlan()
    }

    // Ejercicio / Descanso / Movimiento libre solo dentro de cada BlockEditorCard
    // (paridad iOS). Aquí: sheets del menú ⋮ y, opcional, filas de plan.
    if (showBoardScanner) {
        ReperaModalBottomSheet(onDismissRequest = { onShowBoardScannerChange(false) }) {
            BoardScanScreen(
                busy = busy,
                overview = overview,
                asSheet = true,
                onConfirm = { _, _, _ -> },
                onBack = { onShowBoardScannerChange(false) },
                onImportBlocks = { imported ->
                    mutateBlocks { list ->
                        imported.forEach { list.add(scannedRoutineBlockDraft(it)) }
                    }
                    onShowBoardScannerChange(false)
                },
                catalogOverride = catalog
            )
        }
    }

    if (showSessionPlanActions) {
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
                    icon = Icons.AutoMirrored.Outlined.List,
                    label = "Elegir WOD",
                    modifier = Modifier.testTag("play_pick_wod"),
                    onClick = { onShowWodsChange(true) },
                    enabled = !busy
                )
                if (favorites.isNotEmpty()) {
                    HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    PlanEditorActionRow(
                        icon = Icons.Outlined.Star,
                        label = "Añadir favorito",
                        modifier = Modifier.testTag("play_add_favorite"),
                        onClick = { onShowFavoritesChange(true) },
                        enabled = !busy
                    )
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                PlanEditorActionRow(
                    icon = Icons.Outlined.AddCircle,
                    label = "Escanear pizarra",
                    modifier = Modifier.testTag("play_scan_board"),
                    onClick = { onShowBoardScannerChange(true) },
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
                onShowFavoritesChange(false)
            },
            onDismiss = { onShowFavoritesChange(false) }
        )
    }
    if (showWods) {
        WodCatalogPickerSheet(
            onPick = { t ->
                mutateBlocks { blocks ->
                    blocks.add(BlockDraftUi(EditorBlockOps.templateToBlockInfo(t, catalog)))
                }
                onShowWodsChange(false)
            },
            onDismiss = { onShowWodsChange(false) }
        )
    }
}

/** Paridad `WorkoutView.workoutToolbarContents`: menú ⋮ = iOS (bloque/WOD/pizarra/reordenar/favorito/cancelar). */
@Composable
private fun ActiveWorkoutToolbar(
    title: String,
    busy: Boolean,
    index: Int,
    total: Int,
    hasMoreExercises: Boolean,
    onClose: () -> Unit,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onEditPlan: () -> Unit,
    onAddBlock: () -> Unit = {},
    onPickWod: () -> Unit = {},
    onScanBoard: () -> Unit = {},
    onReorderStructure: () -> Unit,
    onToggleFavorite: () -> Unit = {},
    isFavorite: Boolean = false,
    onCancelWorkout: () -> Unit = {},
    startedLabel: String? = null,
    showExerciseNav: Boolean = true,
    showFinishInToolbar: Boolean = true,
) {
    var structureMenuOpen by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ReperaToolbarGlassIconButton(
            icon = Icons.Outlined.KeyboardArrowDown,
            contentDescription = "Minimizar",
            onClick = onClose,
            enabled = !busy,
            modifier = Modifier.testTag("active_workout_back")
        )
        Column(Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = buildString {
                    startedLabel?.let { append(it) }
                    append(" · Ejercicio ${index + 1} de $total")
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Box {
            ReperaToolbarGlassIconButton(
                icon = Icons.Outlined.MoreVert,
                contentDescription = "Más opciones",
                onClick = { structureMenuOpen = true },
                enabled = !busy,
                modifier = Modifier.testTag("active_edit_structure")
            )
            DropdownMenu(
                expanded = structureMenuOpen,
                onDismissRequest = { structureMenuOpen = false },
            ) {
                DropdownMenuItem(
                    text = { Text("Añadir bloque") },
                    leadingIcon = { Icon(Icons.Outlined.ViewAgenda, contentDescription = null) },
                    onClick = {
                        structureMenuOpen = false
                        onAddBlock()
                    },
                )
                DropdownMenuItem(
                    text = { Text("Elegir WOD") },
                    leadingIcon = { Icon(Icons.AutoMirrored.Outlined.List, contentDescription = null) },
                    onClick = {
                        structureMenuOpen = false
                        onPickWod()
                    },
                )
                DropdownMenuItem(
                    text = { Text("Escanear pizarra") },
                    leadingIcon = { Icon(Icons.Outlined.AddCircle, contentDescription = null) },
                    onClick = {
                        structureMenuOpen = false
                        onScanBoard()
                    },
                )
                HorizontalDivider()
                DropdownMenuItem(
                    text = { Text("Reordenar") },
                    leadingIcon = { Icon(Icons.AutoMirrored.Outlined.List, contentDescription = null) },
                    onClick = {
                        structureMenuOpen = false
                        onReorderStructure()
                    },
                )
                DropdownMenuItem(
                    text = { Text(if (isFavorite) "En favoritos" else "Favorito") },
                    leadingIcon = { Icon(Icons.Outlined.Star, contentDescription = null) },
                    enabled = !isFavorite,
                    onClick = {
                        structureMenuOpen = false
                        onToggleFavorite()
                    },
                    modifier = Modifier.testTag("play_favorite_menu")
                )
                HorizontalDivider()
                DropdownMenuItem(
                    text = {
                        Text("Cancelar entreno", color = MaterialTheme.colorScheme.error)
                    },
                    leadingIcon = {
                        Icon(
                            Icons.Outlined.Close,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                    },
                    onClick = {
                        structureMenuOpen = false
                        onCancelWorkout()
                    },
                    modifier = Modifier.testTag("play_cancel_workout")
                )
            }
        }
        if (showExerciseNav && index > 0) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.KeyboardArrowLeft,
                contentDescription = "Ejercicio anterior",
                onClick = onPrevious,
                enabled = !busy,
                modifier = Modifier.testTag("active_previous")
            )
        }
        if (showExerciseNav && hasMoreExercises) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = "Ejercicio siguiente",
                onClick = onNext,
                enabled = !busy,
                modifier = Modifier.testTag("active_navigate_next")
            )
        }
        if (showFinishInToolbar) {
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
                    icon = Icons.AutoMirrored.Outlined.List,
                    modifier = Modifier.weight(1f),
                    iconTint = brandGreen
                )
                WorkoutSummaryTile(
                    title = "Hechos",
                    value = "${workout.navigationEntries.count { it.completed }}",
                    icon = Icons.Outlined.Check,
                    modifier = Modifier.weight(1f),
                    iconTint = MaterialTheme.reperaColors.blue
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
