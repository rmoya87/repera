package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Dedicated workout route, not the dashboard above an off-screen active card. */
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
    LazyColumn(Modifier.fillMaxSize().testTag("active_workout_screen"),
        contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack, modifier = Modifier.testTag("active_workout_back")) {
                    Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
                }
                Spacer(Modifier.weight(1f))
            }
            ReperaPageHeader(
                title = workout.title.ifBlank { "Entrenamiento activo" },
                subtitle = if (workout.title.isNotBlank()) "Sesión en curso" else null
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
                onDiscard = onDiscard,
                onConfigureBlockTimer = { showBlockTimer = true },
                accountId = accountId,
                catalog = catalog,
                onSubstituteExercise = onSubstituteExercise,
                onRemoveExercise = onRemoveExercise
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
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                if (pin != null) {
                    WorkoutPlacePickerRow(pin = pin, accountId = accountId, onPinChange = onPinChange)
                } else {
                    Column(Modifier.padding(16.dp)) {
                        WorkoutPlacePickerRow(pin = null, accountId = accountId, onPinChange = onPinChange)
                    }
                }
            }
        }
    }
}
