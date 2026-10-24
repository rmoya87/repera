package dev.repera.mobile

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat
import kotlinx.coroutines.delay

/** Full-screen WOD clock, twin of the iPhone full-screen timer. */
@Composable
internal fun WodClockScreen(
    active: ActiveWorkout,
    busy: Boolean,
    timer: WodTimerState?,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    onBack: () -> Unit
) {
    val wod = active.wod ?: return
    val context = LocalContext.current
    val view = LocalView.current
    val spec = WodClockSpec(
        format = WodFormat.fromWire(wod.format),
        blockTimeCapMinutes = wod.timeCapMinutes,
        intervalSeconds = wod.intervalSeconds,
        rounds = wod.rounds,
        workSeconds = wod.workSeconds,
        restSeconds = wod.restSeconds,
        restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
        stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
    )
    DisposableEffect(Unit) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }
    val elapsedClock = timer?.elapsedSeconds ?: 0
    val face = WodClock.face(spec, elapsedClock)
    LaunchedEffect(active.id, active.index, timer?.running) {
        if (timer?.running == true) {
            while (true) {
                delay(250)
                onTimerTick()
            }
        }
    }
    // Rest-phase cue: fires on the transition into a rest label, never per tick.
    var lastRestLabel by remember(active.id, active.index) { mutableStateOf<String?>(null) }
    val restLabel = face.label?.takeIf {
        it.startsWith("Descanso") && timer?.running == true
    }
    LaunchedEffect(restLabel) {
        if (restLabel != null && restLabel != lastRestLabel) {
            RestNotifier.notifyRest(context, restLabel, face.primarySeconds)
        } else if (restLabel == null && lastRestLabel != null) {
            RestNotifier.cancel(context)
        }
        lastRestLabel = restLabel
    }
    val isRest = restLabel != null
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
            TextButton(onClick = onBack) { Text("Volver") }
        }
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text(
                "%d:%02d".format(face.primarySeconds / 60, face.primarySeconds % 60),
                fontSize = 96.sp,
                fontWeight = FontWeight.Bold,
                color = if (isRest) brandGreen else Color.Unspecified
            )
            face.label?.let { label ->
                Text(label, style = MaterialTheme.typography.headlineSmall)
            }
            Text(wod.title + " · " +
                (WodFormat.fromWire(wod.format)?.displayName ?: wod.format),
                style = MaterialTheme.typography.bodyMedium)
        }
        Row(modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = { onTimerAction(if (timer?.running == true) "pause" else "start") },
                enabled = !busy && !face.finishedIntervals,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(
                    containerColor = brandGreen, contentColor = Color.Black
                )
            ) {
                Text(if (timer?.running == true) "Pausar"
                    else if (elapsedClock > 0) "Reanudar" else "Iniciar")
            }
            OutlinedButton(
                onClick = { onTimerAction("reset") },
                enabled = !busy,
                modifier = Modifier.weight(1f)
            ) { Text("Reiniciar") }
        }
    }
}
