package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Grupos musculares del formulario «Nuevo ejercicio» (paridad I-133 iOS). */
internal val newExerciseMuscleGroups = listOf(
    "Pecho", "Espalda", "Hombros", "Bíceps", "Tríceps",
    "Piernas", "Glúteos", "Core", "Cardio", "Otro"
)

/**
 * I-133 Nuevo ejercicio: Nombre, grupo, equipo, detalle e instrucciones.
 * «Añadir» desactivado sin nombre. El gating Gratis/Pro lo aplica el host.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewExerciseScreen(
    busy: Boolean,
    onBack: () -> Unit,
    onCreate: (
        name: String,
        muscleGroup: String,
        equipment: String?,
        targetMuscle: String?,
        secondaryMuscles: List<String>,
        description: String?,
        instructions: String?
    ) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var muscleGroup by remember { mutableStateOf(newExerciseMuscleGroups.first()) }
    var muscleMenu by remember { mutableStateOf(false) }
    var equipment by remember { mutableStateOf("") }
    var targetMuscle by remember { mutableStateOf("") }
    var bodyPart by remember { mutableStateOf("") }
    var secondary by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var instructions by remember { mutableStateOf("") }
    val canAdd = name.trim().isNotEmpty() && !busy

    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, enabled = !busy) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Volver")
            }
            Spacer(Modifier.weight(1f))
            TextButton(
                onClick = {
                    onCreate(
                        name.trim(),
                        muscleGroup,
                        equipment.trim().ifBlank { null },
                        targetMuscle.trim().ifBlank { bodyPart.trim().ifBlank { null } },
                        secondary.split(',').map { it.trim() }.filter { it.isNotEmpty() },
                        description.trim().ifBlank { null },
                        instructions.trim().ifBlank { null }
                    )
                },
                enabled = canAdd,
                modifier = Modifier.testTag("new_exercise_add")
            ) { Text("Añadir") }
        }
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ReperaPageHeader(title = "Nuevo ejercicio")
            ReperaSectionTitle("Básico")
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Nombre") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().testTag("new_exercise_name")
            )
            ExposedDropdownMenuBox(expanded = muscleMenu, onExpandedChange = { muscleMenu = it }) {
                OutlinedTextField(
                    value = muscleGroup,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Grupo muscular") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(muscleMenu) },
                    modifier = Modifier.menuAnchor().fillMaxWidth().testTag("new_exercise_muscle")
                )
                ExposedDropdownMenu(expanded = muscleMenu, onDismissRequest = { muscleMenu = false }) {
                    newExerciseMuscleGroups.forEach { g ->
                        DropdownMenuItem(text = { Text(g) }, onClick = {
                            muscleGroup = g; muscleMenu = false
                        })
                    }
                }
            }
            OutlinedTextField(
                value = equipment,
                onValueChange = { equipment = it },
                label = { Text("Equipamiento (barra, mancuernas…)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            ReperaSectionTitle("Detalle")
            OutlinedTextField(
                value = targetMuscle,
                onValueChange = { targetMuscle = it },
                label = { Text("Músculo objetivo") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = bodyPart,
                onValueChange = { bodyPart = it },
                label = { Text("Parte del cuerpo") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = secondary,
                onValueChange = { secondary = it },
                label = { Text("Secundarios (separados por coma)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Descripción") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2
            )
            ReperaSectionTitle("Instrucciones")
            OutlinedTextField(
                value = instructions,
                onValueChange = { instructions = it },
                label = { Text("Un paso por línea") },
                placeholder = { Text("Un paso por línea") },
                modifier = Modifier.fillMaxWidth().testTag("new_exercise_steps"),
                minLines = 4
            )
            Button(
                colors = reperaPrimaryButtonColors(),
                onClick = {
                    onCreate(
                        name.trim(),
                        muscleGroup,
                        equipment.trim().ifBlank { null },
                        targetMuscle.trim().ifBlank { bodyPart.trim().ifBlank { null } },
                        secondary.split(',').map { it.trim() }.filter { it.isNotEmpty() },
                        description.trim().ifBlank { null },
                        instructions.trim().ifBlank { null }
                    )
                },
                enabled = canAdd,
                modifier = Modifier.fillMaxWidth()
            ) { Text("Añadir ejercicio") }
        }
    }
}
