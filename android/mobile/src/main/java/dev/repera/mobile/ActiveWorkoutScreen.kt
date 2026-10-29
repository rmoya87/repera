package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
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
    onExpandClock: () -> Unit = {}
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
    if (showPlayReorder) {
        val blocks = playReorderBlocks
        if (blocks != null) {
            ReperaModalBottomSheet(
                onDismissRequest = {
                    commitPlayReorder()
                    showPlayReorder = false
                    playReorderBlocks = null
                }
            ) {
                PlanReorderSheet(
                    blocks = blocks,
                    nameById = nameById,
                    exercises = catalog,
                    onDone = { showPlayReorder = false },
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
                onConfigureBlockTimer = { showBlockTimer = true },
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
                onFinish=onFinish,onDiscard=onDiscard,onOpenClock={ showBlockTimer = true })
            else ActiveWorkoutCard(effortUnit=effortUnit,weightUnit=weightUnit,active=workout,busy=busy,onLogSet=onLogSet,
                onLogDropSet=onLogDropSet,onLogRestPauseSet=onLogRestPauseSet,
                onReviseSet=onReviseSet,onDeleteSet=onDeleteSet,onNext=onNext,
                onFinish=onFinish,onDiscard=onDiscard)
        }
        if (pin == null) item { ReperaSectionTitle("Lugar") }
        item {
            if (pin != null) {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    WorkoutPlacePickerRow(pin = pin, accountId = accountId, onPinChange = onPinChange)
                }
            } else {
                WorkoutPlacePickerRow(pin = null, accountId = accountId, onPinChange = onPinChange)
            }
        }
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
            IconButton(
                enabled = !busy,
                onClick = onPrevious,
                modifier = Modifier.testTag("active_previous")
            ) {
                Icon(
                    Icons.AutoMirrored.Outlined.KeyboardArrowLeft,
                    contentDescription = "Ejercicio anterior",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        }
        if (hasMoreExercises) {
            IconButton(
                enabled = !busy,
                onClick = onNext,
                modifier = Modifier.testTag("active_navigate_next")
            ) {
                Icon(
                    Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                    contentDescription = "Ejercicio siguiente",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        } else {
            IconButton(
                onClick = onFinish,
                enabled = !busy,
                modifier = Modifier
                    .size(44.dp)
                    .background(MaterialTheme.colorScheme.primary, CircleShape)
                    .testTag("active_toolbar_finish")
            ) {
                Icon(
                    Icons.Outlined.Check,
                    contentDescription = "Terminar entreno",
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        }
    }
}
