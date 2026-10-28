package dev.repera.mobile

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.TextButton
import androidx.compose.material3.AlertDialog
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Star
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/** Pitidos y vibración del temporizador, paridad RestFeedback (iOS). */
private object TimerFeedback {
    private var toneGenerator: ToneGenerator? = null

    private fun beep(durationMs: Int) {
        runCatching {
            if (toneGenerator == null) {
                toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 85)
            }
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, durationMs)
        }
    }

    fun tick(remaining: Int) {
        if (remaining in 1..3) beep(120)
    }

    fun intervalBeep() = beep(250)

    fun complete(context: android.content.Context) {
        beep(500)
        runCatching {
            @Suppress("DEPRECATION")
            val vibrator = context.getSystemService(Vibrator::class.java)
            vibrator?.vibrate(
                VibrationEffect.createOneShot(250, VibrationEffect.DEFAULT_AMPLITUDE))
        }
    }
}

/**
 * Temporizador libre (pestaña Crear): configuración + reloj LED a pantalla
 * completa, paridad de StandaloneTimerView (iOS). El estado se ancla al reloj
 * de pared (System.currentTimeMillis), nunca a acumulación de ticks.
 *
 * @param onPersistSession persiste el resumen en historial (timerDetails); false si falla.
 * @param onSavedDay epoch millis del día a enfocar en Inicio tras Guardar.
 */
@Composable
internal fun StandaloneTimerScreen(
    onBack: () -> Unit,
    favoriteId: String? = null,
    onPersistSession: (StandaloneTimerCompletion) -> Boolean = { false },
    onSavedDay: (Long) -> Unit = {}
) {
    val context = LocalContext.current
    val store = remember { StandaloneTimerStore(context) }
    // Apertura desde el hub de favoritos (paridad FavoritesHubView iOS):
    // carga la configuración guardada y la edición queda anclada a ese id.
    // Sin favorito: restaurar última configuración (main 30aa3a37).
    val openedFavorite = remember(favoriteId) {
        favoriteId?.let { id -> store.favorites().firstOrNull { it.id == id } }
    }
    val usesLastConfiguration = openedFavorite == null
    var config by remember {
        mutableStateOf(
            openedFavorite?.config
                ?: store.loadLastConfiguration()
                ?: StandaloneTimerConfig()
        )
    }
    var favorites by remember { mutableStateOf(store.favorites()) }
    var editingFavoriteId by remember { mutableStateOf<String?>(openedFavorite?.id) }
    var showSaveDialog by remember { mutableStateOf(false) }
    var saveTitle by remember { mutableStateOf("") }
    var showClock by remember { mutableStateOf(false) }
    var completedSummary by remember {
        mutableStateOf(store.loadPendingCompletion())
    }
    var completionSaveError by remember { mutableStateOf<String?>(null) }
    var timerStartedAtMs by remember { mutableStateOf<Long?>(null) }

    // Estado del reloj (anclado a reloj de pared).
    var isRunning by remember { mutableStateOf(false) }
    var displaySeconds by remember { mutableIntStateOf(0) }
    var roundNumber by remember { mutableIntStateOf(1) }
    var phaseIsWork by remember { mutableStateOf(true) }
    var preCountdown by remember { mutableIntStateOf(0) }
    var preCountdownEndMs by remember { mutableLongStateOf(0L) }
    var phaseEndMs by remember { mutableLongStateOf(0L) }
    var phaseStartMs by remember { mutableLongStateOf(0L) }
    var pausedDisplaySeconds by remember { mutableStateOf<Int?>(null) }

    LaunchedEffect(config) {
        if (usesLastConfiguration) store.saveLastConfiguration(config)
    }
    LaunchedEffect(Unit) {
        if (completedSummary == null) completedSummary = store.loadPendingCompletion()
        if (usesLastConfiguration && !showClock && !isRunning &&
            completedSummary == null
        ) {
            store.loadLastConfiguration()?.let { config = it }
        }
    }

    fun recordTimerCompletion(finishedAtMs: Long = System.currentTimeMillis()) {
        if (completedSummary != null) return
        val started = minOf(
            timerStartedAtMs ?: (finishedAtMs - config.configuredDurationSeconds * 1000L),
            finishedAtMs
        )
        val summary = StandaloneTimerCompletion(
            startedAtMillis = started,
            finishedAtMillis = finishedAtMs,
            config = config
        )
        completedSummary = summary
        store.savePendingCompletion(summary)
        showClock = false
        isRunning = false
        preCountdownEndMs = 0L
        phaseEndMs = 0L
        phaseStartMs = 0L
    }

    fun dismissCompletedTimer() {
        showClock = false
        isRunning = false
        store.clearPendingCompletion()
        completedSummary = null
        completionSaveError = null
        timerStartedAtMs = null
    }

    fun saveCompletedTimer() {
        val summary = completedSummary ?: return
        val ok = onPersistSession(summary)
        if (!ok) {
            completionSaveError =
                "No se ha podido registrar la sesión en el historial. Puedes volver a intentarlo sin perder el temporizador."
            return
        }
        // onSavedDay ya navega a Inicio (pop de subpantallas); no hacer popBackStack.
        onSavedDay(summary.startedAtMillis)
        dismissCompletedTimer()
    }

    fun liveDisplaySeconds(nowMs: Long): Int = when {
        preCountdownEndMs > 0L ->
            ((preCountdownEndMs - nowMs).coerceAtLeast(0L) / 1000L).toInt()
        pausedDisplaySeconds != null && !isRunning -> pausedDisplaySeconds ?: displaySeconds
        config.mode == StandaloneTimerMode.UP -> {
            if (phaseStartMs > 0L)
                (((nowMs - phaseStartMs) / 1000L).toInt())
                    .coerceAtMost(config.durationTotalSeconds)
            else displaySeconds
        }
        else -> if (phaseEndMs > 0L)
            ((phaseEndMs - nowMs + 999L).coerceAtLeast(0L) / 1000L).toInt()
        else displaySeconds
    }

    fun advanceRoundOrFinish(nowMs: Long): Boolean {
        // false = todas las rondas terminadas
        if (roundNumber >= config.rounds) {
            displaySeconds = 0
            isRunning = false
            phaseEndMs = 0L
            phaseStartMs = 0L
            TimerFeedback.complete(context)
            return false
        }
        roundNumber += 1
        phaseIsWork = true
        phaseEndMs = nowMs + config.workTotalSeconds * 1000L
        displaySeconds = config.workTotalSeconds
        return true
    }

    fun catchUpIntervals(nowMs: Long) {
        if (phaseEndMs <= 0L) return
        if (nowMs < phaseEndMs) {
            val remaining = ((phaseEndMs - nowMs + 999L) / 1000L).toInt()
            displaySeconds = remaining
            TimerFeedback.tick(remaining)
            return
        }
        // Saltar tantas fases trabajo/descanso como exija el tiempo real.
        var cursor = phaseEndMs
        var safety = 0
        var finished = false
        while (nowMs >= cursor && safety < 500 && !finished) {
            safety += 1
            if (phaseIsWork) {
                if (config.restTotalSeconds > 0) {
                    phaseIsWork = false
                    cursor += config.restTotalSeconds * 1000L
                } else {
                    if (roundNumber >= config.rounds) { finished = true } else {
                        roundNumber += 1
                        phaseIsWork = true
                        cursor += config.workTotalSeconds * 1000L
                    }
                }
            } else {
                if (roundNumber >= config.rounds) { finished = true } else {
                    roundNumber += 1
                    phaseIsWork = true
                    cursor += config.workTotalSeconds * 1000L
                }
            }
        }
        if (finished) {
            displaySeconds = 0
            isRunning = false
            phaseEndMs = 0L
            TimerFeedback.complete(context)
            recordTimerCompletion(nowMs)
            return
        }
        val phaseLen = (if (phaseIsWork) config.workTotalSeconds
            else config.restTotalSeconds) * 1000L
        val remaining = ((cursor - nowMs).coerceAtLeast(0L) / 1000L).toInt()
        displaySeconds = remaining
        phaseEndMs = cursor
        TimerFeedback.intervalBeep()
    }

    fun tick(nowMs: Long) {
        if (preCountdownEndMs > 0L) {
            val remaining = ((preCountdownEndMs - nowMs).coerceAtLeast(0L) / 1000L).toInt()
            preCountdown = remaining
            TimerFeedback.tick(remaining)
            if (remaining == 0) {
                preCountdownEndMs = 0L
                TimerFeedback.complete(context)
                when (config.mode) {
                    StandaloneTimerMode.UP -> {
                        displaySeconds = 0
                        phaseStartMs = nowMs
                    }
                    StandaloneTimerMode.DOWN -> {
                        displaySeconds = config.durationTotalSeconds
                        phaseEndMs = nowMs + config.durationTotalSeconds * 1000L
                    }
                    StandaloneTimerMode.INTERVALS -> {
                        displaySeconds = config.workTotalSeconds
                        phaseIsWork = true
                        phaseEndMs = nowMs + config.workTotalSeconds * 1000L
                    }
                }
            }
            return
        }
        if (!isRunning) return
        when (config.mode) {
            StandaloneTimerMode.UP -> {
                val elapsed = liveDisplaySeconds(nowMs)
                displaySeconds = elapsed
                TimerFeedback.tick(config.durationTotalSeconds - elapsed)
                if (elapsed >= config.durationTotalSeconds) {
                    displaySeconds = config.durationTotalSeconds
                    isRunning = false
                    phaseStartMs = 0L
                    TimerFeedback.complete(context)
                    recordTimerCompletion(nowMs)
                }
            }
            StandaloneTimerMode.DOWN -> {
                val remaining = liveDisplaySeconds(nowMs)
                displaySeconds = remaining
                if (remaining <= 0) {
                    displaySeconds = 0
                    isRunning = false
                    phaseEndMs = 0L
                    TimerFeedback.complete(context)
                    recordTimerCompletion(nowMs)
                } else {
                    TimerFeedback.tick(remaining)
                }
            }
            StandaloneTimerMode.INTERVALS -> catchUpIntervals(nowMs)
        }
    }

    fun prepareAndShowClock() {
        isRunning = false
        phaseIsWork = true
        roundNumber = 1
        displaySeconds = when (config.mode) {
            StandaloneTimerMode.UP -> 0
            StandaloneTimerMode.DOWN -> config.durationTotalSeconds
            StandaloneTimerMode.INTERVALS -> config.workTotalSeconds
        }
        preCountdown = if (config.countdownBeforeStart) 3 else 0
        preCountdownEndMs = 0L
        phaseEndMs = 0L
        phaseStartMs = 0L
        pausedDisplaySeconds = null
        timerStartedAtMs = null
        completionSaveError = null
        showClock = true
    }

    fun toggleRun() {
        val nowMs = System.currentTimeMillis()
        if (isRunning || preCountdownEndMs > 0L) {
            val paused = liveDisplaySeconds(nowMs)
            if (preCountdownEndMs > 0L) preCountdown = paused.coerceAtLeast(1)
            displaySeconds = paused
            pausedDisplaySeconds = paused
            isRunning = false
            preCountdownEndMs = 0L
            phaseEndMs = 0L
            phaseStartMs = 0L
        } else {
            isRunning = true
            pausedDisplaySeconds = null
            if (timerStartedAtMs == null) timerStartedAtMs = nowMs
            if (preCountdown > 0) {
                preCountdownEndMs = nowMs + preCountdown * 1000L
            } else when (config.mode) {
                StandaloneTimerMode.UP ->
                    phaseStartMs = nowMs - displaySeconds * 1000L
                StandaloneTimerMode.DOWN, StandaloneTimerMode.INTERVALS ->
                    phaseEndMs = nowMs + displaySeconds.coerceAtLeast(1) * 1000L
            }
        }
    }

    LaunchedEffect(showClock) {
        if (!showClock) return@LaunchedEffect
        while (true) {
            delay(250)
            tick(System.currentTimeMillis())
        }
    }

    if (showSaveDialog) {
        AlertDialog(
            onDismissRequest = { showSaveDialog = false },
            title = { Text("Guardar en favoritos") },
            text = {
                OutlinedTextField(
                    value = saveTitle,
                    onValueChange = { saveTitle = it },
                    label = { Text("Nombre") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val title = saveTitle.trim().ifBlank { config.defaultFavoriteTitle }
                    val saved = store.save(
                        FavoriteTimer(
                            id = editingFavoriteId ?: java.util.UUID.randomUUID().toString(),
                            title = title, config = config))
                    editingFavoriteId = saved.id
                    favorites = store.favorites()
                    showSaveDialog = false
                }) { Text("Guardar") }
            },
            dismissButton = {
                TextButton(onClick = { showSaveDialog = false }) { Text("Cancelar") }
            }
        )
    }

    completedSummary?.let { summary ->
        AlertDialog(
            onDismissRequest = { /* mantener pendiente hasta Guardar/Descartar */ },
            title = { Text("Temporizador · ${summary.config.mode.title}") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Duración configurada: %d:%02d".format(
                            summary.configuredSeconds / 60,
                            summary.configuredSeconds % 60
                        )
                    )
                    Text("¿Guardar en el historial del día?")
                    completionSaveError?.let {
                        Text(it, color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { saveCompletedTimer() }) { Text("Guardar") }
            },
            dismissButton = {
                TextButton(onClick = { dismissCompletedTimer() }) { Text("Descartar") }
            }
        )
    }

    if (showClock && completedSummary == null) {
        StandaloneClock(
            title = "Temporizador",
            subtitle = when {
                preCountdown > 0 || preCountdownEndMs > 0L -> "Cuenta atrás"
                config.mode == StandaloneTimerMode.UP -> "Arriba"
                config.mode == StandaloneTimerMode.DOWN -> "Abajo"
                else -> if (phaseIsWork) "Trabajar" else "Descansar"
            },
            roundNumber = if (config.mode == StandaloneTimerMode.INTERVALS &&
                preCountdown == 0 && preCountdownEndMs == 0L) roundNumber else null,
            totalRounds = if (config.mode == StandaloneTimerMode.INTERVALS)
                config.rounds else null,
            displaySeconds = if (preCountdown > 0 && preCountdownEndMs > 0L)
                preCountdown else displaySeconds,
            running = isRunning || preCountdownEndMs > 0L,
            onPrimary = { toggleRun() },
            onClose = {
                isRunning = false
                preCountdownEndMs = 0L
                phaseEndMs = 0L
                phaseStartMs = 0L
                showClock = false
            }
        )
        return
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
            }
            Spacer(Modifier.weight(1f))
            IconButton(onClick = {
                saveTitle = editingFavoriteId?.let { id ->
                    favorites.firstOrNull { it.id == id }?.title
                } ?: config.defaultFavoriteTitle
                showSaveDialog = true
            }) {
                Icon(Icons.Outlined.Star, contentDescription =
                    if (editingFavoriteId == null) "Guardar en favoritos"
                    else "Actualizar favorito")
            }
        }
        ReperaPageHeader(
            title = "Temporizador",
            modifier = Modifier.padding(horizontal = 16.dp)
        )
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                ReperaSectionTitle("Tipo de temporizador")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StandaloneTimerMode.entries.forEach { mode ->
                        ReperaFilterChip(
                            selected = config.mode == mode,
                            onClick = { config = config.copy(mode = mode) },
                            label = { Text(mode.title) }
                        )
                    }
                }
            }
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text("Configuración", style = MaterialTheme.typography.titleSmall,
                        modifier = Modifier.padding(bottom = 10.dp))
                    when (config.mode) {
                        StandaloneTimerMode.UP, StandaloneTimerMode.DOWN ->
                            TimeRow("Duración", config.durationMinutes, config.durationSeconds,
                                maxMinutes = 180,
                                onMinutes = { config = config.copy(durationMinutes = it) },
                                onSeconds = { config = config.copy(durationSeconds = it) })
                        StandaloneTimerMode.INTERVALS -> {
                            IntRow("Rondas", config.rounds, 1..99,
                                onValue = { config = config.copy(rounds = it) })
                            TimeRow("Trabajar", config.workMinutes, config.workSeconds,
                                maxMinutes = 60,
                                onMinutes = { config = config.copy(workMinutes = it) },
                                onSeconds = { config = config.copy(workSeconds = it) })
                            TimeRow("Descansar", config.restMinutes, config.restSeconds,
                                maxMinutes = 30,
                                onMinutes = { config = config.copy(restMinutes = it) },
                                onSeconds = { config = config.copy(restSeconds = it) })
                        }
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Cuenta atrás")
                            Text("Antes de que comience el temporizador",
                                style = MaterialTheme.typography.bodySmall)
                        }
                        Switch(
                            checked = config.countdownBeforeStart,
                            onCheckedChange = {
                                config = config.copy(countdownBeforeStart = it)
                            },
                            colors = reperaSwitchColors()
                        )
                    }
                }
            }
            Button(
                onClick = { prepareAndShowClock() },
                modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
                shape = CircleShape,
                colors = reperaPrimaryButtonColors()
            ) { Text("Abrir reloj", fontSize = 17.sp, fontWeight = FontWeight.Bold) }
            if (favorites.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    ReperaSectionTitle("Favoritos")
                    favorites.forEach { favorite ->
                        ReperaCard(modifier = Modifier.fillMaxWidth()) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(
                                    start = 16.dp, top = 4.dp, bottom = 4.dp, end = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(favorite.title,
                                        style = MaterialTheme.typography.titleMedium)
                                    Text(favorite.config.shortLabel,
                                        style = MaterialTheme.typography.bodySmall)
                                }
                                TextButton(onClick = {
                                    config = favorite.config
                                    editingFavoriteId = favorite.id
                                }) { Text("Cargar") }
                                IconButton(onClick = {
                                    store.delete(favorite.id)
                                    if (editingFavoriteId == favorite.id) {
                                        editingFavoriteId = null
                                    }
                                    favorites = store.favorites()
                                }) {
                                    Icon(Icons.Outlined.Delete,
                                        contentDescription = "Eliminar favorito")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun IntRow(
    title: String,
    value: Int,
    range: IntRange,
    onValue: (Int) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, modifier = Modifier.weight(1f))
        OutlinedTextField(
            value = value.toString(),
            onValueChange = { input ->
                input.filter(Char::isDigit).toIntOrNull()?.let {
                    if (it in range) onValue(it)
                }
            },
            label = { Text("RONDAS") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.width(110.dp)
        )
    }
}

@Composable
private fun TimeRow(
    title: String,
    minutes: Int,
    seconds: Int,
    maxMinutes: Int,
    onMinutes: (Int) -> Unit,
    onSeconds: (Int) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, modifier = Modifier.weight(1f))
        OutlinedTextField(
            value = minutes.toString(),
            onValueChange = { input ->
                input.filter(Char::isDigit).toIntOrNull()?.let {
                    if (it in 0..maxMinutes) onMinutes(it)
                }
            },
            label = { Text("MIN") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.width(100.dp)
        )
        OutlinedTextField(
            value = seconds.toString(),
            onValueChange = { input ->
                input.filter(Char::isDigit).toIntOrNull()?.let {
                    if (it in 0..59) onSeconds(it)
                }
            },
            label = { Text("SEG") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.width(100.dp).padding(start = 8.dp)
        )
    }
}

/** Reloj LED a pantalla completa del temporizador libre (sin ejercicio). */
@Composable
internal fun StandaloneClock(
    title: String,
    subtitle: String,
    roundNumber: Int?,
    totalRounds: Int?,
    displaySeconds: Int,
    running: Boolean,
    onPrimary: () -> Unit,
    onClose: () -> Unit
) {
    val view = LocalView.current
    DisposableEffect(Unit) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }
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
                        totalSeconds = displaySeconds,
                        digitHeight = digitHeight
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (roundNumber != null && totalRounds != null) {
                            Text(
                                "$roundNumber/$totalRounds",
                                fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                                color = Color.White.copy(alpha = 0.6f)
                            )
                        }
                        Text(
                            subtitle,
                            fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                            color = brandGreen,
                            maxLines = 1
                        )
                    }
                }
            }
            @Composable
            fun Primary(modifier: Modifier = Modifier) {
                Button(
                    onClick = onPrimary,
                    modifier = modifier.heightIn(min = 54.dp),
                    shape = CircleShape,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White, contentColor = Color.Black)
                ) {
                    Text(if (running) "Pausar" else "Continuar",
                        fontSize = 18.sp, fontWeight = FontWeight.Bold)
                }
            }
            if (landscape) {
                Column(modifier = Modifier.fillMaxSize()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        TextButton(onClick = onClose) { Text("Volver", color = Color.White) }
                        Text(title, style = MaterialTheme.typography.titleLarge,
                            color = Color.White, maxLines = 1,
                            modifier = Modifier.padding(start = 8.dp))
                    }
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        ClockBlock()
                        Primary(Modifier.widthIn(max = 500.dp).fillMaxWidth()
                            .padding(top = 14.dp))
                    }
                }
            } else {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        TextButton(onClick = onClose) { Text("Volver", color = Color.White) }
                    }
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Text(title, style = MaterialTheme.typography.titleLarge,
                            color = Color.White)
                        ClockBlock()
                    }
                    Primary(Modifier.fillMaxWidth())
                }
            }
        }
    }
}
