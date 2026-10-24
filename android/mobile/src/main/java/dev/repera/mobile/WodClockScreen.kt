package dev.repera.mobile

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
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
    val format = WodFormat.fromWire(wod.format)
    val intervalFormats = setOf(
        WodFormat.EMOM, WodFormat.DEATH_BY, WodFormat.TABATA, WodFormat.CIRCUIT)
    val roundNumber = if (format in intervalFormats && !face.finishedIntervals)
        WodClock.activeIntervalIndex(spec, elapsedClock) + 1 else null
    // "Terminar" con la semántica de canFinishByUser (iOS): cronómetros que
    // cuentan hacia arriba (For Time, Chipper, AFAP, Ladder, BuyIn/CashOut) o
    // Death By (intervalos con cierre anticipado), una vez iniciado.
    val canFinish = (face.countsUp || format == WodFormat.DEATH_BY) &&
        elapsedClock > 0 && !face.finishedIntervals
    // Pantalla completa en negro con dígitos LED, como BlockTimerScreen (iOS).
    Surface(modifier = Modifier.fillMaxSize(), color = Color.Black) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize().padding(24.dp)) {
        val landscape = maxWidth > maxHeight
        val digitHeight = minOf(
            if (landscape) 165f else 138f,
            maxWidth.value / LedClock.widthFactor(roundNumber != null),
            maxHeight.value * if (landscape) 0.36f else 0.235f
        ).dp
        @Composable
        fun ClockBlock() {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                LedClockDisplay(
                    roundNumber = roundNumber,
                    totalSeconds = face.primarySeconds,
                    digitHeight = digitHeight
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    face.label?.let { label ->
                        Text(
                            label,
                            style = MaterialTheme.typography.titleMedium,
                            color = if (isRest) brandGreen else Color.White.copy(alpha = 0.6f)
                        )
                    }
                }
                Text(
                    wod.title + " · " + (format?.displayName ?: wod.format),
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.6f)
                )
            }
        }
        @Composable
        fun PrimaryButton(modifier: Modifier = Modifier) {
            // Cápsula blanca con texto negro, como pauseOrResumeButton (iOS).
            Button(
                onClick = { onTimerAction(if (timer?.running == true) "pause" else "start") },
                enabled = !busy && !face.finishedIntervals,
                modifier = modifier.heightIn(min = 54.dp),
                shape = CircleShape,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White, contentColor = Color.Black
                )
            ) {
                Text(
                    if (timer?.running == true) "Pausar"
                    else if (elapsedClock > 0) "Reanudar" else "Iniciar",
                    fontSize = 18.sp, fontWeight = FontWeight.Bold
                )
            }
        }
        @Composable
        fun FinishButton(modifier: Modifier = Modifier) {
            // Cápsula en el color de acento; pausa conservando el tiempo
            // (la tarjeta de sesión lo aplica con "Usar tiempo del cronómetro")
            // y vuelve a la sesión, donde se confirma el resultado del bloque.
            if (canFinish) {
                Button(
                    onClick = {
                        onTimerAction("pause")
                        onBack()
                    },
                    enabled = !busy,
                    modifier = modifier.heightIn(min = 54.dp),
                    shape = CircleShape,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = brandGreen, contentColor = Color.Black
                    )
                ) { Text("Terminar", fontSize = 18.sp, fontWeight = FontWeight.Bold) }
            }
        }
        @Composable
        fun TopBar(showTitle: Boolean) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = onBack) { Text("Volver", color = Color.White) }
                if (showTitle) {
                    Text(
                        active.title,
                        style = MaterialTheme.typography.titleLarge,
                        color = Color.White,
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
                        FinishButton(Modifier.weight(1f))
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
                    Text(
                        active.title,
                        style = MaterialTheme.typography.titleLarge,
                        color = Color.White
                    )
                    ClockBlock()
                }
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    PrimaryButton(Modifier.fillMaxWidth())
                    FinishButton(Modifier.fillMaxWidth())
                }
            }
        }
    }
    }
}
