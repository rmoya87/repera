package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
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
    onSelectExercise:(Int)->Unit = {},
    onUpdateNotes:(String)->Unit = {}
) {
    LazyColumn(Modifier.fillMaxSize().testTag("active_workout_screen"),
        contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item { TextButton(onClick=onBack) { Text("Volver") } }
        item { Text("Entrenamiento activo",style=MaterialTheme.typography.headlineMedium) }
        item {ActiveSessionControls(workout,busy,onSelectExercise,onUpdateNotes)}
        item {
            if(workout.wod!=null) WodScoreCard(active=workout,busy=busy,timer=timer,
                onTimerAction=onTimerAction,onTimerTick=onTimerTick,onSave=onWodScore,
                onMovement=onWodMovement,onCompleteBlock=onCompleteWodBlock,
                onReviseMovement=onReviseWodMovement,onDeleteMovement=onDeleteWodMovement,
                onFinish=onFinish,onDiscard=onDiscard,onOpenClock=onOpenClock)
            else ActiveWorkoutCard(effortUnit=effortUnit,active=workout,busy=busy,onLogSet=onLogSet,
                onLogDropSet=onLogDropSet,onLogRestPauseSet=onLogRestPauseSet,
                onReviseSet=onReviseSet,onDeleteSet=onDeleteSet,onNext=onNext,
                onFinish=onFinish,onDiscard=onDiscard)
        }
        item {
            Text("Lugar",style=MaterialTheme.typography.titleMedium)
            WorkoutPlacePickerRow(pin=pin,accountId=accountId,onPinChange=onPinChange)
        }
    }
}
