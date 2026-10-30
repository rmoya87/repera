package dev.repera.mobile

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.view.WindowInsetsControllerCompat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat
import kotlinx.coroutines.delay

/** Full-screen WOD / bloque libre clock, twin of the iPhone full-screen timer. */
@Composable
internal fun WodClockScreen(
    active: ActiveWorkout,
    busy: Boolean,
    timer: WodTimerState?,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    onBack: () -> Unit,
    requestNotificationPermission: Boolean = true,
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    manualConfig: ManualBlockTimerConfig? = null,
) {
    val wod = active.wod
    if (wod == null && manualConfig == null) return
    val context = LocalContext.current
    val view = LocalView.current
    val spec = if (wod != null) {
        WodClockSpec(
            format = WodFormat.fromWire(wod.format),
            blockTimeCapMinutes = wod.timeCapMinutes,
            intervalSeconds = wod.intervalSeconds,
            rounds = wod.rounds,
            workSeconds = wod.workSeconds,
            restSeconds = wod.restSeconds,
            restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
            stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
        )
    } else {
        val cfg = manualConfig!!
        WodClockSpec(
            format = WodFormat.TABATA,
            rounds = cfg.rounds.coerceAtLeast(1),
            workSeconds = cfg.workSeconds.coerceAtLeast(1),
            restSeconds = cfg.restSeconds.coerceAtLeast(0)
        )
    }
    DisposableEffect(Unit) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }
    // Negro bajo status bar: sin franja blanca.
    androidx.compose.runtime.SideEffect {
        val window = (view.context as? android.app.Activity)?.window ?: return@SideEffect
        window.statusBarColor = android.graphics.Color.BLACK
        window.navigationBarColor = android.graphics.Color.BLACK
        WindowInsetsControllerCompat(window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }
    LaunchedEffect(Unit) {
        if (requestNotificationPermission && Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(
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
    var lastRestLabel by remember(active.id, active.index) { mutableStateOf<String?>(null) }
    val restLabel = face.label?.takeIf {
        it.startsWith("Descanso") && timer?.running == true
    }
    LaunchedEffect(restLabel) {
        if (restLabel != null && restLabel != lastRestLabel) {
            val settings = trainingSettingsForAccount(context, SessionStore(context).load()?.uniqueId)
            RestNotifier.notifyRest(
                context, restLabel, face.primarySeconds,
                settings.restSoundEnabled, settings.restHapticEnabled
            )
        } else if (restLabel == null && lastRestLabel != null) {
            RestNotifier.cancel(context)
        }
        lastRestLabel = restLabel
    }
    val isRest = restLabel != null
    val format = wod?.let { WodFormat.fromWire(it.format) } ?: WodFormat.TABATA
    val intervalFormats = setOf(
        WodFormat.EMOM, WodFormat.DEATH_BY, WodFormat.TABATA, WodFormat.CIRCUIT
    )
    val roundNumber = if (format in intervalFormats && !face.finishedIntervals)
        WodClock.activeIntervalIndex(spec, elapsedClock) + 1 else null
    val isPaused = timer?.running != true && elapsedClock > 0
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    val firstMove = wod?.movements?.firstOrNull { !it.isRest }
    val moveExercise = remember(firstMove?.name, active.exerciseId, active.exerciseName, exerciseCatalog) {
        firstMove?.let { resolveWodExercise(it.name, exerciseCatalog, aliases) }
            ?: exerciseCatalog.firstOrNull { it.id == active.exerciseId }
            ?: exerciseCatalog.firstOrNull {
                it.name.equals(active.exerciseName, ignoreCase = true)
            }
            ?: resolveWodExercise(active.exerciseName, exerciseCatalog, aliases)
    }
    val exerciseDisplayName = firstMove?.name?.takeIf { it.isNotBlank() }
        ?: active.exerciseName.takeIf { it.isNotBlank() }

    Surface(modifier = Modifier.fillMaxSize(), color = Color.Black) {
        BoxWithConstraints(
            Modifier
                .fillMaxSize()
                .background(Color.Black)
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 12.dp)
        ) {
            val landscape = maxWidth > maxHeight
            val digitHeight = minOf(
                if (landscape) 165f else 138f,
                maxWidth.value / LedClock.widthFactor(roundNumber != null),
                maxHeight.value * if (landscape) 0.36f else 0.22f
            ).dp
            val thumbSize = if (landscape) 96.dp else 132.dp

            @Composable
            fun ExerciseArtBlock() {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    moveExercise?.let { exercise ->
                        WodExerciseThumbnail(exercise, aliases, size = thumbSize)
                    }
                    exerciseDisplayName?.let { moveName ->
                        Text(
                            moveName,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White,
                            textAlign = TextAlign.Center,
                            maxLines = 3
                        )
                    }
                }
            }

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
                    face.label?.let { label ->
                        Text(
                            label,
                            style = MaterialTheme.typography.titleMedium,
                            color = if (isRest) brandGreen else Color.White.copy(alpha = 0.6f)
                        )
                    }
                }
            }

            @Composable
            fun ControlButtons(modifier: Modifier = Modifier) {
                val running = timer?.running == true
                Column(
                    modifier = modifier,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (running) {
                        Button(
                            onClick = { onTimerAction("pause") },
                            enabled = !busy && !face.finishedIntervals,
                            modifier = Modifier.fillMaxWidth().heightIn(min = 54.dp),
                            shape = CircleShape,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color.White, contentColor = Color.Black
                            )
                        ) {
                            Text("Pausar", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        }
                    } else {
                        Button(
                            onClick = { onTimerAction("start") },
                            enabled = !busy && !face.finishedIntervals,
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 54.dp)
                                .testTag("wod_clock_continue"),
                            shape = CircleShape,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = brandGreen, contentColor = Color.Black
                            )
                        ) {
                            Text(
                                if (elapsedClock > 0) "Continuar" else "Iniciar",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        if (isPaused) {
                            Button(
                                onClick = {
                                    onTimerAction("finish")
                                    onBack()
                                },
                                enabled = !busy,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .heightIn(min = 54.dp)
                                    .testTag("wod_clock_finish"),
                                shape = CircleShape,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = Color.White, contentColor = Color.Black
                                )
                            ) {
                                Text("Finalizar", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            Column(Modifier.fillMaxSize()) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier
                        .size(48.dp)
                        .testTag("wod_clock_minimize")
                ) {
                    Box(
                        Modifier
                            .size(44.dp)
                            .background(Color.White.copy(alpha = 0.18f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Outlined.KeyboardArrowDown,
                            contentDescription = "Minimizar",
                            tint = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
                if (landscape) {
                    Column(
                        Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(20.dp)
                        ) {
                            ClockBlock()
                            ExerciseArtBlock()
                        }
                        ControlButtons(
                            Modifier
                                .widthIn(max = 500.dp)
                                .fillMaxWidth()
                                .padding(top = 18.dp)
                        )
                    }
                } else {
                    // Reloj arriba → thumb/nombre a media altura → botones abajo.
                    Column(
                        Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Spacer(Modifier.height(8.dp))
                        ClockBlock()
                        Spacer(Modifier.weight(1f))
                        ExerciseArtBlock()
                        Spacer(Modifier.weight(1f))
                        ControlButtons(Modifier.fillMaxWidth().padding(bottom = 8.dp))
                    }
                }
            }
        }
    }
}
