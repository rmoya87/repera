package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
 * Confirmación = círculo verde con ✓ (DayEditorTopBar).
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

    fun commit() {
        onCreate(
            name.trim(),
            muscleGroup,
            equipment.trim().ifBlank { null },
            targetMuscle.trim().ifBlank { bodyPart.trim().ifBlank { null } },
            secondary.split(',').map { it.trim() }.filter { it.isNotEmpty() },
            description.trim().ifBlank { null },
            instructions.trim().ifBlank { null }
        )
    }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(reperaScrollContentPadding(extraBottom = 16.dp)),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        DayEditorTopBar(
            onBack = onBack,
            onConfirm = { commit() },
            confirmEnabled = canAdd,
            confirmContentDescription = "Añadir",
            busy = busy
        )
        ReperaPageHeader(title = "Nuevo ejercicio")
        ReperaSectionTitle("Básico")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                ReperaMetaTextField(
                    caption = "Nombre",
                    value = name,
                    onValueChange = { name = it },
                    testTag = "new_exercise_name"
                )
                ExposedDropdownMenuBox(
                    expanded = muscleMenu,
                    onExpandedChange = { muscleMenu = it }
                ) {
                    OutlinedTextField(
                        value = muscleGroup,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Grupo muscular") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(muscleMenu) },
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                            .testTag("new_exercise_muscle")
                    )
                    ExposedDropdownMenu(
                        expanded = muscleMenu,
                        onDismissRequest = { muscleMenu = false }
                    ) {
                        newExerciseMuscleGroups.forEach { g ->
                            DropdownMenuItem(
                                text = { Text(g) },
                                onClick = { muscleGroup = g; muscleMenu = false }
                            )
                        }
                    }
                }
                ReperaMetaTextField(
                    caption = "Equipamiento (barra, mancuernas…)",
                    value = equipment,
                    onValueChange = { equipment = it }
                )
            }
        }
        ReperaSectionTitle("Detalle")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                ReperaMetaTextField(
                    caption = "Músculo objetivo",
                    value = targetMuscle,
                    onValueChange = { targetMuscle = it }
                )
                ReperaMetaTextField(
                    caption = "Parte del cuerpo",
                    value = bodyPart,
                    onValueChange = { bodyPart = it }
                )
                ReperaMetaTextField(
                    caption = "Secundarios (separados por coma)",
                    value = secondary,
                    onValueChange = { secondary = it }
                )
                ReperaMetaTextField(
                    caption = "Descripción",
                    value = description,
                    onValueChange = { description = it },
                    singleLine = false
                )
            }
        }
        ReperaSectionTitle("Instrucciones")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp)) {
                ReperaMetaTextField(
                    caption = "Un paso por línea",
                    value = instructions,
                    onValueChange = { instructions = it },
                    placeholder = "Un paso por línea",
                    singleLine = false,
                    testTag = "new_exercise_steps"
                )
            }
        }
    }
}
