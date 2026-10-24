package dev.repera.mobile

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
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
    // Layout adaptativo en paridad con BlockTimerScreen (iOS): en apaisado
    // (ancho > alto) el reloj y los controles van en una fila centrada con
    // los controles en horizontal bajo el reloj; en vertical, columna con
    // controles apilados. El tamaño de dígito se calcula como en iOS:
    // min(tope 165/138, ancho disponible / 2.76, alto * 0.36/0.235).
    BoxWithConstraints(modifier = Modifier.fillMaxSize().padding(24.dp)) {
        val landscape = maxWidth > maxHeight
        val clockFont = minOf(
            if (landscape) 165f else 138f,
            maxWidth.value / 2.76f,
            maxHeight.value * if (landscape) 0.36f else 0.235f
        ).sp
        @Composable
        fun ClockBlock() {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Text(
                    "%d:%02d".format(face.primarySeconds / 60, face.primarySeconds % 60),
                    fontSize = clockFont,
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
        }
        @Composable
        fun PrimaryButton(modifier: Modifier = Modifier) {
            Button(
                onClick = { onTimerAction(if (timer?.running == true) "pause" else "start") },
                enabled = !busy && !face.finishedIntervals,
                modifier = modifier,
                colors = ButtonDefaults.buttonColors(
                    containerColor = brandGreen, contentColor = Color.Black
                )
            ) {
                Text(if (timer?.running == true) "Pausar"
                    else if (elapsedClock > 0) "Reanudar" else "Iniciar")
            }
        }
        @Composable
        fun ResetButton(modifier: Modifier = Modifier) {
            OutlinedButton(
                onClick = { onTimerAction("reset") },
                enabled = !busy,
                modifier = modifier
            ) { Text("Reiniciar") }
        }
        @Composable
        fun TopBar(showTitle: Boolean) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = onBack) { Text("Volver") }
                if (showTitle) {
                    Text(
                        active.title,
                        style = MaterialTheme.typography.titleLarge,
                        maxLines = 1,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
            }
        }
        if (landscape) {
            Column(modifier = Modifier.fillMaxSize()) {
                TopBar(showTitle = true)
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    ClockBlock()
                    Row(
                        modifier = Modifier.widthIn(max = 500.dp)
                            .fillMaxWidth().padding(top = 14.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        PrimaryButton(Modifier.weight(1f))
                        ResetButton(Modifier.weight(1f))
                    }
                }
            }
        } else {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                TopBar(showTitle = false)
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(active.title, style = MaterialTheme.typography.titleLarge)
                    ClockBlock()
                }
                // En vertical los controles se apilan a ancho completo,
                // como en BlockTimerScreen (iOS).
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    PrimaryButton(Modifier.fillMaxWidth())
                    ResetButton(Modifier.fillMaxWidth())
                }
            }
        }
    }
}
