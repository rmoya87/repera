package dev.repera.mobile

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

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
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onLogSet: (Int, Double?) -> Unit,
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
        Scaffold(
            topBar = { TopAppBar(title = { Text("repera") }) },
            bottomBar = {
                NavigationBar {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = selected == tab,
                            onClick = { selected = tab },
                            icon = { Text(when (tab) {
                                "Inicio" -> "⌂"
                                "Diario" -> "▦"
                                "Crear" -> "+"
                                "Progreso" -> "↗"
                                else -> "◉"
                            }) },
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
                        if (activeWorkout != null) {
                            key(activeWorkout.id, activeWorkout.index, activeWorkout.completedSets) {
                                ActiveWorkoutCard(
                                    active = activeWorkout,
                                    busy = busy,
                                    onLogSet = onLogSet,
                                    onNext = onNext,
                                    onFinish = onFinish
                                )
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
                    val workouts = overview?.recentWorkoutTitles.orEmpty()
                    if (workouts.isEmpty()) item { Text("Todavía no hay sesiones registradas") }
                    items(workouts) { title ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Text(title, modifier = Modifier.padding(16.dp))
                        }
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
                                    enabled = !busy && activeWorkout == null
                                ) { Text("Empezar entrenamiento") }
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
                    val exerciseTitles = overview?.exerciseTitles.orEmpty()
                        .asSequence()
                        .filter { it.contains(exerciseSearch.trim(), ignoreCase = true) }
                        .take(100).toList()
                    if (exerciseTitles.isEmpty()) item { Text("Sin ejercicios coincidentes") }
                    items(exerciseTitles) { name ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Text(name, modifier = Modifier.padding(16.dp))
                        }
                    }
                }
                if (selected == "Crear") {
                    item {
                        Text("Para conservar el histórico de iOS y sus ejercicios, importa el JSON exportado por Repera. La edición de nuevos bloques WOD todavía no está disponible.")
                        OutlinedButton(
                            onClick = onImportJson,
                            enabled = !busy && overview == null,
                            modifier = Modifier.fillMaxWidth()
                        ) { Text("Importar datos de Repera") }
                    }
                }
                if (selected == "Inicio" && overview == null) {
                    item {
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
    onLogSet: (Int, Double?) -> Unit,
    onNext: () -> Unit,
    onFinish: () -> Unit
) {
    var quantity by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedQuantity?.toString() ?: "")
    }
    var weight by remember(active.id, active.index, active.completedSets) {
        mutableStateOf(active.prescribedWeightKg?.toString() ?: "")
    }
    val parsedQuantity = quantity.toIntOrNull()
    val parsedWeight = weight.trim().replace(',', '.').takeIf { it.isNotBlank() }?.toDoubleOrNull()
    val valid = parsedQuantity != null && parsedQuantity >= 0 &&
        (weight.isBlank() || (parsedWeight != null && parsedWeight.isFinite() && parsedWeight >= 0))
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(active.title, style = MaterialTheme.typography.titleLarge)
            Text("Ejercicio ${active.index + 1}/${active.total}: ${active.exerciseName}",
                style = MaterialTheme.typography.titleMedium)
            Text("${active.completedSets} series registradas")
            active.sets.forEachIndexed { index, set ->
                Text("Serie ${index + 1}: ${set.reps} reps" +
                    (set.weightKg?.let { " · $it kg" } ?: ""))
            }
            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it.filter { char -> char.isDigit() } },
                label = { Text("Repeticiones o cantidad") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = weight,
                onValueChange = { weight = it },
                label = { Text("Peso (kg), si procede") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Button(
                onClick = { if (parsedQuantity != null) onLogSet(parsedQuantity, parsedWeight) },
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
