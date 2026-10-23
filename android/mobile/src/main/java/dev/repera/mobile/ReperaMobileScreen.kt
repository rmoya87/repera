package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat

private val brandGreen = Color(0xFF30D158)
private val tabs = listOf("Inicio", "Diario", "Crear", "Progreso", "Ejercicios")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReperaMobileScreen(
    isAuthenticated: Boolean,
    displayName: String?,
    busy: Boolean,
    status: String?,
    overview: StateOverview?,
    todayHealth: TodayHealth?,
    onHealthConnect: () -> Unit,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onCreateRoutine: (String, String, List<RoutineDraftEntry>, Int, Int) -> Unit,
    onWodScore: (Int?, Int?, Int?) -> Unit,
    onQuickLog: (String) -> Unit,
    onInitializeLocal: () -> Unit,
    onLogSet: (Int, Double?, Double?, Boolean) -> Unit,
    onReviseSet: (String, Int, Double?) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit,
    onImportJson: () -> Unit,
    onGoogleSignIn: () -> Unit,
    onDriveSync: () -> Unit,
    onSignOut: () -> Unit
) {
    val scheme = if (isSystemInDarkTheme()) {
        darkColorScheme(primary = brandGreen, onPrimary = Color.Black)
    } else lightColorScheme(primary = Color(0xFF16833B), onPrimary = Color.White)
    val context = LocalContext.current
    val englishAliases = remember(context) { ExerciseSearchAssets.load(context) }
    MaterialTheme(colorScheme = scheme) {
        if (!isAuthenticated) {
            Column(
                modifier = Modifier.fillMaxSize().padding(28.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Text("repera", style = MaterialTheme.typography.displayLarge)
                Text("Tu entrenamiento, ahora en Android", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.padding(12.dp))
                Button(
                    onClick = onGoogleSignIn, enabled = !busy,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black)
                ) { Text("Iniciar sesión con Google") }
                if (busy) CircularProgressIndicator(modifier = Modifier.padding(12.dp))
                if (status != null) Text(status, modifier = Modifier.padding(top = 12.dp))
            }
            return@MaterialTheme
        }
        var selected by remember { mutableStateOf("Inicio") }
        var exerciseSearch by remember { mutableStateOf("") }
        // LazyListScope is not @Composable: calculate the filtered list here,
        // where remember is legal, then hand the immutable result to LazyColumn.
        val filteredExerciseEntries = remember(exerciseSearch, overview?.exerciseEntries) {
            overview?.exerciseEntries.orEmpty()
                .asSequence()
                .map { it to ExerciseAliasSearch.score(exerciseSearch, it.name, englishAliases) }
                .filter { it.second >= 0 }
                .sortedWith(compareByDescending<Pair<ExerciseEntry, Int>> { it.second }
                    .thenBy { it.first.name })
                .take(100).map { it.first }.toList()
        }
        Scaffold(
            topBar = { TopAppBar(title = { Text("repera") }) },
            bottomBar = {
                NavigationBar {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = selected == tab,
                            onClick = { selected = tab },
                            icon = {
                                Icon(imageVector = when (tab) {
                                    "Inicio" -> Icons.Outlined.Home
                                    "Diario" -> Icons.Outlined.CalendarMonth
                                    "Crear" -> Icons.Outlined.AddCircleOutline
                                    "Progreso" -> Icons.Outlined.TrendingUp
                                    else -> Icons.Outlined.FitnessCenter
                                }, contentDescription = null)
                            },
                            label = { Text(tab) }
                        )
                    }
                }
            }
        ) { padding ->
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Text(
                        when (selected) {
                            "Inicio" -> "Hola, " + (displayName ?: "Deportista")
                            else -> selected
                        },
                        style = MaterialTheme.typography.headlineMedium
                    )
                }
                if (selected == "Inicio") {
                    item {
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(
                                modifier = Modifier.padding(18.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Text("Actividad del día", style = MaterialTheme.typography.titleMedium)
                                Text("Pasos: " + (todayHealth?.steps?.toString() ?: "—"))
                                Text("Energía activa: " + (todayHealth?.activeKcal?.let {
                                    "${it.toInt()} kcal"
                                } ?: "—"))
                                TextButton(
                                    enabled = !busy,
                                    onClick = onHealthConnect
                                ) { Text("Conectar o actualizar Salud") }
                            }
                        }
                    }
                    item {
                        if (activeWorkout != null) {
                            key(activeWorkout.id, activeWorkout.index, activeWorkout.completedSets) {
                                if (activeWorkout.wod != null) {
                                    WodScoreCard(
                                        active = activeWorkout,
                                        busy = busy,
                                        onSave = onWodScore,
                                        onFinish = onFinish
                                    )
                                } else {
                                    ActiveWorkoutCard(
                                        active = activeWorkout,
                                        busy = busy,
                                        onLogSet = onLogSet,
                                        onReviseSet = onReviseSet,
                                        onNext = onNext,
                                        onFinish = onFinish
                                    )
                                }
                            }
                        } else {
                            Card(modifier = Modifier.fillMaxWidth()) {
                                Column(modifier = Modifier.padding(18.dp)) {
                                    Text("Sesión activa", style = MaterialTheme.typography.titleMedium)
                                    Text("Sin entrenamiento iniciado")
                                }
                            }
                        }
                    }
                }
                if (selected == "Inicio" || selected == "Diario" ||
                    selected == "Progreso" || selected == "Ejercicios") {
                    val count = when (selected) {
                        "Diario" -> overview?.routines
                        "Ejercicios" -> overview?.exercises
                        else -> overview?.workouts
                    }
                    item {
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(18.dp)) {
                                Text(
                                    when (selected) {
                                        "Diario" -> "Rutinas"
                                        "Ejercicios" -> "Catálogo local"
                                        else -> "Entrenamientos registrados"
                                    },
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Text(count?.toString() ?: "—", style = MaterialTheme.typography.headlineLarge)
                                if (overview == null) Text("No hay datos locales cargados")
                            }
                        }
                    }
                }
                if (selected == "Inicio") {
                    item { Text("Historial reciente", style = MaterialTheme.typography.titleMedium) }
                    val workouts = overview?.history.orEmpty()
                    if (workouts.isEmpty()) item { Text("Todavía no hay sesiones registradas") }
                    items(workouts, key = { it.id }) { workout ->
                        WorkoutHistoryCard(workout)
                    }
                }
                if (selected == "Diario") {
                    val routines = overview?.routineEntries.orEmpty()
                    if (routines.isEmpty()) item { Text("Sin rutinas locales disponibles") }
                    items(routines, key = { it.id }) { routine ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(routine.title, style = MaterialTheme.typography.titleMedium)
                                TextButton(
                                    onClick = { onStartRoutine(routine.id); selected = "Inicio" },
                                    enabled = !busy && activeWorkout == null && routine.supported
                                ) { Text(if (routine.supported) "Empezar entrenamiento" else "Formato pendiente") }
                            }
                        }
                    }
                }
                if (selected == "Ejercicios") {
                    item {
                        OutlinedTextField(
                            value = exerciseSearch,
                            onValueChange = { exerciseSearch = it },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            label = { Text("Buscar ejercicio") }
                        )
                    }
                    val entries = filteredExerciseEntries
                    if (entries.isEmpty()) item { Text("Sin ejercicios coincidentes") }
                    items(entries, key = { it.id }) { entry ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(entry.name, style = MaterialTheme.typography.titleMedium)
                                TextButton(
                                    onClick = { onQuickLog(entry.id); selected = "Inicio" },
                                    enabled = !busy && activeWorkout == null && entry.supportsBasicInput
                                ) { Text(if (entry.supportsBasicInput) "Apuntar series" else "Registro avanzado pendiente") }
                            }
                        }
                    }
                }
                if (selected == "Crear" && overview != null) {
                    item {
                        RoutineCreatorCard(
                            exercises = overview.exerciseEntries,
                            aliases = englishAliases,
                            busy = busy,
                            onSave = onCreateRoutine
                        )
                    }
                }
                if (overview == null) {
                    item {
                        Button(
                            onClick = onInitializeLocal,
                            enabled = !busy,
                            modifier = Modifier.fillMaxWidth()
                        ) { Text("Empezar con catálogo Repera") }
                        OutlinedButton(
                            onClick = onImportJson,
                            enabled = !busy,
                            modifier = Modifier.fillMaxWidth()
                        ) { Text("Importar historial JSON") }
                    }
                }
                item {
                    Text("Cuenta y sincronización", style = MaterialTheme.typography.titleMedium)
                    Button(
                        onClick = onDriveSync, enabled = !busy,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = brandGreen, contentColor = Color.Black)
                    ) { Text(if (busy) "Sincronizando…" else "Sincronizar con Google Drive") }
                    if (busy) CircularProgressIndicator(modifier = Modifier.padding(12.dp))
                    if (status != null) Text(status)
                    TextButton(onClick = onSignOut, enabled = !busy) { Text("Cerrar sesión") }
                }
            }
        }
    }
}

@Composable
private fun ActiveWorkoutCard(
    active: ActiveWorkout,
    busy: Boolean,
    onLogSet: (Int, Double?, Double?, Boolean) -> Unit,
    onReviseSet: (String, Int, Double?) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit
) {
    var quantity by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedQuantity?.toString() ?: "")
    }
    var weight by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedWeightKg?.toString() ?: "")
    }
    var warmup by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(false)
    }
    var rirText by remember(active.id, active.index, active.completedSets) {
        mutableStateOf("")
    }
    var editingId by remember(active.id, active.index) { mutableStateOf<String?>(null) }
    var editingQuantity by remember(active.id, active.index) { mutableStateOf("") }
    var editingWeight by remember(active.id, active.index) { mutableStateOf("") }
    val parsedRir = rirText.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val parsedQuantity = quantity.toIntOrNull()
    val parsedWeight = weight.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val valid = parsedQuantity != null && parsedQuantity >= 0 &&
        (!active.allowsWeight || weight.isBlank() ||
            (parsedWeight != null && parsedWeight.isFinite() && parsedWeight >= 0)) &&
        (rirText.isBlank() || (parsedRir != null && parsedRir.isFinite() && parsedRir >= 0))
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text("Ejercicio ${active.index + 1}/${active.total}: ${active.exerciseName}",
                style = MaterialTheme.typography.titleMedium)
            Text("${active.completedSets} series registradas")
            active.sets.forEachIndexed { index, set ->
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    Text((if (set.phase == "warmup") "Calentamiento" else "Serie") +
                        " ${index + 1}: ${set.reps} reps" +
                        (set.weightKg?.let { " · $it kg" } ?: "") +
                        (set.rir?.let { " · RIR $it" } ?: ""))
                    TextButton(onClick = {
                        editingId = set.id
                        editingQuantity = set.reps.toString()
                        editingWeight = set.weightKg?.toString() ?: ""
                    }, enabled = !busy) { Text("Editar") }
                }
            }
            if (editingId != null) {
                OutlinedTextField(
                    value = editingQuantity,
                    onValueChange = { editingQuantity = it.filter(Char::isDigit) },
                    label = { Text("Corregir repeticiones") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                if (active.allowsWeight) {
                    OutlinedTextField(
                        value = editingWeight,
                        onValueChange = { editingWeight = it },
                        label = { Text("Corregir peso (kg)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                val parsedEdit = editingQuantity.toIntOrNull()
                val editWeight = editingWeight.trim().replace(',', '.')
                    .takeIf { it.isNotBlank() }?.toDoubleOrNull()
                val editValid = parsedEdit != null &&
                    (!active.allowsWeight || editingWeight.isBlank() ||
                        (editWeight != null && editWeight.isFinite() && editWeight >= 0))
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween) {
                    TextButton(onClick = { editingId = null }, enabled = !busy) {
                        Text("Cancelar")
                    }
                    Button(onClick = {
                        val id = editingId
                        if (id != null && parsedEdit != null) {
                            onReviseSet(id, parsedEdit, if (active.allowsWeight) editWeight else null)
                            editingId = null
                        }
                    }, enabled = !busy && editValid) { Text("Guardar corrección") }
                }
            }
            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it.filter { char -> char.isDigit() } },
                label = { Text("Repeticiones o cantidad") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            if (active.allowsWeight) {
                OutlinedTextField(
                    value = weight,
                    onValueChange = { weight = it },
                    label = { Text("Peso (kg)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            OutlinedTextField(
                value = rirText,
                onValueChange = { rirText = it },
                label = { Text("RIR opcional (repeticiones en reserva)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start
            ) {
                Checkbox(checked = warmup, onCheckedChange = { warmup = it }, enabled = !busy)
                Text("Serie de calentamiento", modifier = Modifier.padding(top = 12.dp))
            }
            Button(
                onClick = {
                    if (parsedQuantity != null) onLogSet(
                        parsedQuantity,
                        if (active.allowsWeight) parsedWeight else null,
                        parsedRir,
                        warmup
                    )
                },
                enabled = !busy && valid,
                modifier = Modifier.fillMaxWidth()
            ) { Text("Registrar serie") }
            OutlinedButton(onClick = onNext, enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                Text(if (active.index + 1 == active.total) "Terminar último ejercicio" else "Siguiente ejercicio")
            }
            TextButton(onClick = onFinish, enabled = !busy) { Text("Finalizar entrenamiento") }
        }
    }
}


/** Inline score editor like the iPhone Play review, no modal or imaginary movement sets. */
@Composable
private fun WodScoreCard(
    active: ActiveWorkout,
    busy: Boolean,
    onSave: (Int?, Int?, Int?) -> Unit,
    onFinish: () -> Unit
) {
    val wod = active.wod ?: return
    var rounds by remember(active.id, active.index) { mutableStateOf("") }
    var extraReps by remember(active.id, active.index) { mutableStateOf("") }
    var minutes by remember(active.id, active.index) { mutableStateOf("") }
    var seconds by remember(active.id, active.index) { mutableStateOf("") }
    val m = minutes.toIntOrNull()
    val sec = seconds.toIntOrNull()
    val elapsed = if (m != null && sec != null && sec in 0..59) {
        if (m <= (Int.MAX_VALUE - sec) / 60) m * 60 + sec else null
    } else null
    val scoreIsTime = wod.capture == "ELAPSED_TIME"
    val valid = if (scoreIsTime) elapsed != null else
        extraReps.toIntOrNull() != null && (rounds.toIntOrNull() != null || !wod.expectsRounds)

    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text(wod.title + " · " +
                (WodFormat.fromWire(wod.format)?.displayName ?: wod.format),
                style = MaterialTheme.typography.titleMedium)
            wod.movements.forEach { movement ->
                val prefix = when {
                    movement.isRest -> movement.restSeconds?.let { "${it}s descanso" } ?: "Descanso"
                    movement.repScheme.isNotEmpty() ->
                        movement.repScheme.joinToString("-") + " reps"
                    movement.calories != null -> "${movement.calories} cal"
                    movement.meters != null -> "${movement.meters} m"
                    movement.reps != null -> "${movement.reps} reps"
                    else -> ""
                }
                Text((prefix + "  " + movement.name).trim(),
                    style = MaterialTheme.typography.bodyMedium)
            }
            if (scoreIsTime) {
                Text("Tiempo total realizado", style = MaterialTheme.typography.titleSmall)
                OutlinedTextField(
                    value = minutes,
                    onValueChange = { minutes = it.filter(Char::isDigit) },
                    label = { Text("Minutos") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = seconds,
                    onValueChange = { seconds = it.filter(Char::isDigit) },
                    label = { Text("Segundos (0–59)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            } else {
                if (wod.expectsRounds) {
                    OutlinedTextField(
                        value = rounds,
                        onValueChange = { rounds = it.filter(Char::isDigit) },
                        label = { Text("Rondas completadas") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                OutlinedTextField(
                    value = extraReps,
                    onValueChange = { extraReps = it.filter(Char::isDigit) },
                    label = { Text(if (wod.expectsRounds) "Repeticiones adicionales" else "Repeticiones totales") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            Button(
                enabled = !busy && valid,
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    if (scoreIsTime) onSave(null, null, elapsed)
                    else onSave(rounds.toIntOrNull(), extraReps.toIntOrNull(), null)
                }
            ) { Text("Guardar resultado y continuar") }
            TextButton(onClick = onFinish, enabled = !busy) {
                Text("Finalizar sin añadir otro resultado")
            }
        }
    }
}

private data class RoutineDraftRow(
    val id: String, val name: String, val sets: Int, val quantity: Int, val weightKg: Double?
)

/** Material editor for the Swift Routine/RoutineBlock subset actually supported on Android. */
@Composable
private fun RoutineCreatorCard(
    exercises: List<ExerciseEntry>,
    aliases: Map<String, String>,
    busy: Boolean,
    onSave: (String, String, List<RoutineDraftEntry>, Int, Int) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var kind by remember { mutableStateOf("strength") }
    var search by remember { mutableStateOf("") }
    var reps by remember { mutableStateOf("10") }
    var sets by remember { mutableStateOf("3") }
    var weight by remember { mutableStateOf("") }
    var cap by remember { mutableStateOf("12") }
    var rounds by remember { mutableStateOf("1") }
    val chosen = remember { mutableStateListOf<RoutineDraftRow>() }
    val weightValue = weight.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val quantity = reps.toIntOrNull()
    val setCount = sets.toIntOrNull()
    val validNumeric = quantity != null && quantity in 1..10000 &&
        (kind != "strength" || (setCount != null && setCount in 1..30 &&
            (weight.isBlank() || (weightValue != null &&
                weightValue.isFinite() && weightValue >= 0))))
    val candidates = remember(exercises, search, kind, chosen.size) {
        exercises.asSequence()
            .filter { kind != "strength" || it.supportsBasicInput }
            .filter { candidate -> chosen.none { it.id == candidate.id } }
            .map { entry -> entry to ExerciseAliasSearch.score(search, entry.name, aliases) }
            .filter { it.second >= 0 }
            .sortedWith(compareByDescending<Pair<ExerciseEntry, Int>> { it.second }
                .thenBy { it.first.name })
            .take(8).map { it.first }.toList()
    }
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("Nueva rutina", style = MaterialTheme.typography.titleLarge)
            OutlinedTextField(
                value = title, onValueChange = { title = it },
                label = { Text("Nombre de la rutina") },
                singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("strength" to "Fuerza", "amrap" to "AMRAP", "forTime" to "For Time")
                    .forEach { option ->
                        FilterChip(
                            selected = kind == option.first,
                            onClick = {
                                kind = option.first
                                chosen.clear()
                            },
                            label = { Text(option.second) }
                        )
                    }
            }
            if (kind != "strength") {
                OutlinedTextField(
                    value = cap, onValueChange = { cap = it.filter(Char::isDigit) },
                    label = { Text("Límite (minutos)") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                if (kind == "forTime") {
                    OutlinedTextField(
                        value = rounds,
                        onValueChange = { rounds = it.filter(Char::isDigit) },
                        label = { Text("Número de rondas") },
                        modifier = Modifier.fillMaxWidth(), singleLine = true
                    )
                }
            }
            OutlinedTextField(
                value = reps, onValueChange = { reps = it.filter(Char::isDigit) },
                label = { Text("Repeticiones por ejercicio") },
                modifier = Modifier.fillMaxWidth(), singleLine = true
            )
            if (kind == "strength") {
                OutlinedTextField(
                    value = sets, onValueChange = { sets = it.filter(Char::isDigit) },
                    label = { Text("Series por ejercicio") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
                OutlinedTextField(
                    value = weight, onValueChange = { weight = it },
                    label = { Text("Peso prescrito opcional (kg)") },
                    modifier = Modifier.fillMaxWidth(), singleLine = true
                )
            }
            Text("Ejercicios de la rutina", style = MaterialTheme.typography.titleMedium)
            chosen.forEach { draft ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(draft.name + " · " +
                        (if (kind == "strength") "${draft.sets}×" else "") +
                        "${draft.quantity} reps")
                    TextButton(onClick = { chosen.remove(draft) }, enabled = !busy) {
                        Text("Quitar")
                    }
                }
            }
            OutlinedTextField(
                value = search, onValueChange = { search = it },
                label = { Text("Buscar para añadir") },
                modifier = Modifier.fillMaxWidth(), singleLine = true
            )
            candidates.forEach { candidate ->
                TextButton(
                    enabled = !busy && validNumeric,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = {
                        if (quantity != null) {
                            chosen.add(RoutineDraftRow(
                                candidate.id,
                                candidate.name,
                                if (kind == "strength") setCount ?: 3 else 1,
                                quantity,
                                if (kind == "strength" && candidate.allowsWeight) weightValue else null
                            ))
                        }
                    }
                ) { Text("+ " + candidate.name) }
            }
            val validCap = cap.toIntOrNull()?.let { it in 1..180 } == true
            val validRounds = kind != "forTime" ||
                rounds.toIntOrNull()?.let { it in 1..100 } == true
            Button(
                enabled = !busy && title.trim().isNotEmpty() &&
                    title.trim().length <= 100 && chosen.isNotEmpty() &&
                    (kind == "strength" || (validCap && validRounds)),
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    val entries = chosen.map {
                        RoutineDraftEntry(it.id, it.quantity, it.sets, it.weightKg)
                    }
                    onSave(title, kind, entries, cap.toIntOrNull() ?: 12,
                        rounds.toIntOrNull() ?: 1)
                }
            ) { Text("Guardar rutina") }
        }
    }
}


/** Drill-down stays inside the workout, preserving the back-to-summary behaviour. */
@Composable
private fun WorkoutHistoryCard(workout: WorkoutHistoryEntry) {
    var expanded by remember(workout.id) { mutableStateOf(false) }
    var selectedMovement by remember(workout.id) { mutableStateOf<Int?>(null) }
    Card(modifier = Modifier.fillMaxWidth().animateContentSize()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            Text(workout.title, style = MaterialTheme.typography.titleMedium)
            if (workout.startedAt.isNotBlank()) {
                Text(workout.startedAt, style = MaterialTheme.typography.labelMedium)
            }
            workout.results.forEach { result ->
                Text(result, style = MaterialTheme.typography.titleSmall)
            }
            if (!expanded) {
                TextButton(onClick = { expanded = true }) { Text("Ver ejercicios y resultados") }
            } else if (selectedMovement != null) {
                val index = selectedMovement!!
                val exercise = workout.movements.getOrNull(index)
                TextButton(onClick = { selectedMovement = null }) {
                    Text("← Volver al resumen")
                }
                if (exercise != null) {
                    Text(exercise.name, style = MaterialTheme.typography.titleMedium)
                    if (exercise.registered.isEmpty()) {
                        Text(if (exercise.wod && workout.results.isNotEmpty())
                            "Resultado registrado para todo el bloque WOD"
                            else "Este ejercicio no contiene series confirmadas")
                    } else {
                        exercise.registered.forEachIndexed { n, line ->
                            Text("Serie ${n + 1} · $line")
                        }
                    }
                }
            } else {
                workout.movements.forEachIndexed { index, movement ->
                    TextButton(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { selectedMovement = index }
                    ) {
                        Text(movement.name + if (movement.registered.isNotEmpty())
                            " · ${movement.registered.size} series" else
                            if (movement.wod && workout.results.isNotEmpty())
                                " · resultado por bloque" else "")
                    }
                }
                TextButton(onClick = { expanded = false }) {
                    Text("Ocultar detalle")
                }
            }
        }
    }
}
