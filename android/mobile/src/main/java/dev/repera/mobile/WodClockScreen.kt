package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowInsetsControllerCompat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import dev.repera.domain.WodFormat
import kotlinx.coroutines.delay

private data class TimerExerciseRow(
    val key: String,
    val name: String,
    val detail: String,
    val catalog: ExerciseEntry,
    val isActive: Boolean,
)

/** Full-screen WOD / bloque libre clock, twin of the iPhone full-screen timer. */
@Composable
internal fun WodClockScreen(
    active: ActiveWorkout,
    busy: Boolean,
    timer: WodTimerState?,
    onTimerAction: (String) -> Unit,
    onTimerTick: () -> Unit,
    onBack: () -> Unit,
    /** Cap alcanzado o Finalizar: vuelve a Play y limpia formato/reloj. */
    onFinished: () -> Unit = onBack,
    requestNotificationPermission: Boolean = true,
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    manualConfig: ManualBlockTimerConfig? = null,
    launchConfig: BlockClockLaunchConfig? = null,
) {
    val wod = active.wod
    val launch = launchConfig ?: manualConfig?.let { BlockClockLaunchConfig.fromManual(it) }
    if (wod == null && launch == null) return
    val context = LocalContext.current
    val view = LocalView.current
    // Preferir launch/draft: tras elegir Tabata el flush aún no ha poblado wod.
    val spec = when {
        launch != null -> launch.toSpec()
        wod != null -> WodClockSpec(
            format = WodFormat.fromWire(wod.format),
            blockTimeCapMinutes = wod.timeCapMinutes,
            blockTimeCapSeconds = wod.timeCapSeconds,
            repeatedWorkSeconds = wod.repeatedWorkSeconds,
            repeatedRestSeconds = wod.repeatedRestSeconds,
            repeatCount = wod.repeatCount,
            intervalSeconds = wod.intervalSeconds,
            rounds = wod.rounds,
            workSeconds = wod.workSeconds,
            restSeconds = wod.restSeconds,
            restBetweenRoundsSeconds = wod.restBetweenRoundsSeconds,
            stations = wod.movements.count { !it.isRest }.coerceAtLeast(1)
        )
        else -> return
    }
    DisposableEffect(Unit) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }
    // Negro bajo status bar: sin franja blanca.
    androidx.compose.runtime.SideEffect {
        val window = (view.context as? android.app.Activity)?.window ?: return@SideEffect
        @Suppress("DEPRECATION")
        run {
            window.statusBarColor = android.graphics.Color.BLACK
            window.navigationBarColor = android.graphics.Color.BLACK
        }
        WindowInsetsControllerCompat(window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }
    val startWithNotificationPermission = rememberForegroundNotificationPermission()
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
    // Cap alcanzado DURANTE esta visita → onFinished (limpia formato).
    // Si ya venía finalizado al abrir, no cerrar al instante.
    var wasFinishedOnOpen by remember(active.id, active.index, launch?.formatWire, wod?.format) {
        mutableStateOf(face.finishedIntervals)
    }
    LaunchedEffect(face.finishedIntervals, active.id, active.index) {
        if (!face.finishedIntervals) {
            wasFinishedOnOpen = false
            return@LaunchedEffect
        }
        if (wasFinishedOnOpen) return@LaunchedEffect
        wasFinishedOnOpen = true
        if (timer?.running == true) onTimerAction("pause")
        onFinished()
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
    val format = launch?.let { WodFormat.fromWire(it.formatWire) }
        ?: wod?.let { WodFormat.fromWire(it.format) }
        ?: WodFormat.TABATA
    val intervalFormats = setOf(
        WodFormat.EMOM, WodFormat.DEATH_BY, WodFormat.TABATA, WodFormat.CIRCUIT
    )
    val activeInterval = if (format in intervalFormats && !face.finishedIntervals)
        WodClock.activeIntervalIndex(spec, elapsedClock) else 0
    val roundNumber = if (format in intervalFormats && !face.finishedIntervals)
        activeInterval + 1 else null
    val isPaused = timer?.running != true && elapsedClock > 0
    val aliases = remember(context) { ExerciseSearchAssets.load(context) }
    val timerRows = remember(
        wod?.movements, active.navigationEntries, active.index, active.exerciseId,
        activeInterval, isRest, format, exerciseCatalog, face.label
    ) {
        buildTimerExerciseRows(
            active = active,
            wod = wod,
            catalog = exerciseCatalog,
            aliases = aliases,
            format = format,
            activeInterval = activeInterval,
            isRestPhase = isRest || (face.label?.contains("Descanso", ignoreCase = true) == true)
        )
    }

    // Negro edge-to-edge (status + nav); el padding de sistema va en el contenido.
    Surface(modifier = Modifier.fillMaxSize(), color = Color.Black) {
        BoxWithConstraints(
            Modifier
                .fillMaxSize()
                .background(Color.Black)
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp)
                .padding(top = 8.dp, bottom = 12.dp)
        ) {
            val landscape = maxWidth > maxHeight
            val hasList = timerRows.isNotEmpty()
            val digitHeight = minOf(
                if (landscape) 165f else if (hasList) 110f else 138f,
                maxWidth.value / LedClock.widthFactor(roundNumber != null),
                maxHeight.value * if (landscape) 0.36f else if (hasList) 0.18f else 0.22f
            ).dp

            @Composable
            fun ExerciseListBlock(modifier: Modifier = Modifier) {
                LazyColumn(
                    modifier = modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    itemsIndexed(timerRows, key = { _, row -> row.key }) { _, row ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    if (row.isActive) brandGreen.copy(alpha = 0.18f)
                                    else Color.White.copy(alpha = 0.06f),
                                    RoundedCornerShape(14.dp)
                                )
                                .then(
                                    if (row.isActive) Modifier.border(
                                        1.dp, brandGreen.copy(alpha = 0.7f), RoundedCornerShape(14.dp)
                                    ) else Modifier
                                )
                                .padding(horizontal = 10.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            WodExerciseThumbnail(row.catalog, aliases, size = 52.dp)
                            Column(Modifier.weight(1f)) {
                                Text(
                                    row.name,
                                    color = Color.White,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 16.sp,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis
                                )
                                if (row.detail.isNotBlank()) {
                                    Text(
                                        row.detail,
                                        color = if (row.isActive) brandGreen
                                        else Color.White.copy(alpha = 0.55f),
                                        fontWeight = FontWeight.Medium,
                                        fontSize = 13.sp,
                                        maxLines = 1
                                    )
                                }
                            }
                        }
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
                            onClick = {
                                if (requestNotificationPermission) startWithNotificationPermission { onTimerAction("start") }
                                else onTimerAction("start")
                            },
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
                                    onFinished()
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
                            Modifier.fillMaxWidth().weight(1f),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(20.dp)
                        ) {
                            Column(
                                Modifier.weight(1f),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center
                            ) {
                                ClockBlock()
                            }
                            if (hasList) {
                                ExerciseListBlock(
                                    Modifier
                                        .widthIn(max = 320.dp)
                                        .fillMaxHeight()
                                        .weight(0.9f)
                                )
                            }
                        }
                        ControlButtons(
                            Modifier
                                .widthIn(max = 500.dp)
                                .fillMaxWidth()
                                .padding(top = 18.dp)
                        )
                    }
                } else {
                    // Reloj arriba → listado del bloque → botones abajo.
                    Column(
                        Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Aire bajo minimizar: el LED no queda pegado al botón.
                        Spacer(Modifier.height(20.dp))
                        ClockBlock()
                        if (hasList) {
                            Spacer(Modifier.height(16.dp))
                            ExerciseListBlock(Modifier.weight(1f))
                        } else {
                            Spacer(Modifier.weight(1f))
                        }
                        ControlButtons(Modifier.fillMaxWidth().padding(bottom = 8.dp))
                    }
                }
            }
        }
    }
}

private fun buildTimerExerciseRows(
    active: ActiveWorkout,
    wod: WodExecution?,
    catalog: List<ExerciseEntry>,
    aliases: Map<String, String>,
    format: WodFormat,
    activeInterval: Int,
    isRestPhase: Boolean,
): List<TimerExerciseRow> {
    if (wod != null && wod.movements.isNotEmpty()) {
        val work = wod.movements.filter { !it.isRest }
        // Solo EMOM / Circuito / Tabata / Death By marcan estación activa.
        // AFAP / Escalera / For Time / Chipper… lista estática con dosis.
        val activeWork = when {
            isRestPhase -> null
            format == WodFormat.EMOM || format == WodFormat.DEATH_BY ||
                format == WodFormat.CIRCUIT || format == WodFormat.TABATA ->
                if (work.isEmpty()) null else activeInterval % work.size
            else -> null
        }
        var workOrdinal = 0
        return wod.movements.map { move ->
            val detail = when {
                move.isRest -> move.restSeconds?.takeIf { it > 0 }?.let { "$it s" } ?: "Descanso"
                move.repScheme.isNotEmpty() -> move.repScheme.joinToString("-")
                move.calories != null -> "${move.calories} cal"
                move.meters != null -> "${move.meters} m"
                move.reps != null -> "${move.reps}"
                else -> ""
            }
            val isWork = !move.isRest
            val ordinal = if (isWork) workOrdinal++ else -1
            TimerExerciseRow(
                key = move.id.ifBlank { move.name },
                name = if (move.isRest) "Descanso" else move.name,
                detail = detail,
                catalog = resolveWodExercise(move.name, catalog, aliases),
                isActive = isWork && ordinal == activeWork
            )
        }
    }
    val blockId = active.navigationEntries.firstOrNull { it.index == active.index }?.blockId
        ?.ifBlank { null }
    val peers = active.navigationEntries.filter {
        val id = it.blockId.ifBlank { "ex-${it.index}" }
        val current = blockId ?: "ex-${active.index}"
        id == current || (blockId == null && it.index == active.index)
    }.ifEmpty {
        listOf(
            ActiveExerciseNavigation(
                active.index, active.exerciseName, "", "", false,
                detailLine = listOfNotNull(
                    active.pendingSets.size.takeIf { it > 0 }?.let { "$it×${active.prescribedQuantity ?: 0}" }
                        ?.takeIf { active.prescribedQuantity != null },
                    active.prescribedQuantity?.let { "$it reps" }
                ).firstOrNull(),
                exerciseId = active.exerciseId
            )
        )
    }
    val workPeers = peers.filter {
        !it.name.equals("REST", true) && !it.exerciseId.equals("rest", true)
    }
    val activeWork = when {
        isRestPhase -> null
        format == WodFormat.EMOM || format == WodFormat.DEATH_BY ||
            format == WodFormat.CIRCUIT || format == WodFormat.TABATA ->
            if (workPeers.isEmpty()) null else activeInterval % workPeers.size
        else -> null
    }
    var workOrdinal = 0
    return peers.map { nav ->
        val isRestMove = nav.name.equals("REST", true) || nav.exerciseId.equals("rest", true)
        val ordinal = if (!isRestMove) workOrdinal++ else -1
        TimerExerciseRow(
            key = "${nav.index}-${nav.exerciseId.ifBlank { nav.name }}",
            name = if (isRestMove) "Descanso" else nav.name,
            detail = nav.detailLine.orEmpty(),
            catalog = catalog.firstOrNull { it.id == nav.exerciseId }
                ?: resolveWodExercise(nav.name, catalog, aliases),
            isActive = !isRestMove && ordinal == activeWork
        )
    }
}
