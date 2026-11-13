
package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.WorkoutPhase
import dev.repera.domain.WorkoutPhaseKind
import dev.repera.domain.WorkoutSetMethod
import dev.repera.domain.WorkoutStrengthTechnique

/** Advanced phases stay inside the current Create/Edit/Play block card. */
@Composable
internal fun AdvancedPhaseControls(block: BlockDraftUi) {
    var expanded by rememberSaveable(block.listKey) { mutableStateOf(false) }
    TextButton(onClick = { expanded = !expanded }) {
        Text((if (expanded) "Ocultar fases y técnicas" else "Fases y técnicas") +
            " · " + block.advancedPhases.size)
    }
    if (!expanded) return

    if (block.format.isNotBlank() && block.format != "strength" && block.format != "partner") {
        var teamMenu by remember(block.listKey) { mutableStateOf(false) }
        val modes = listOf(
            "solo" to "Individual", "youGoIGo" to "Alternando",
            "synchronized" to "Sincronizado",
            "sharedReps" to "Repeticiones compartidas", "together" to "Juntos")
        Box {
            OutlinedButton(onClick = { teamMenu = true }) {
                Text("Modalidad: " + (modes.firstOrNull { it.first == block.teamMode }?.second ?: "Individual"))
            }
            DropdownMenu(expanded = teamMenu, onDismissRequest = { teamMenu = false }) {
                modes.forEach { (id, title) ->
                    DropdownMenuItem(text = { Text(title) }, onClick = {
                        block.teamMode = id
                        teamMenu = false
                    })
                }
            }
        }
    }

    if (block.advancedPhases.isEmpty()) {
        Text("Combina trabajo, descanso, buy-in, cash-out y fuerza.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    block.advancedPhases.forEachIndexed { index, row ->
        val phase = row.phase
        Column(modifier = Modifier.fillMaxWidth()
            .padding(start = if (row.parentID == null) 0.dp else 12.dp),
            verticalArrangement = Arrangement.spacedBy(7.dp)) {
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            ReperaMetaTextField(
                caption = if (row.parentID == null) "Fase" else "Subfase",
                value = phase.title,
                onValueChange = { row.phase = row.phase.copy(title = it.take(120)) },
                placeholder = "Trabajo principal")
            var kindMenu by remember(phase.id) { mutableStateOf(false) }
            Box {
                OutlinedButton(onClick = { kindMenu = true }) {
                    Text("Tipo: " + phase.kind.name)
                }
                DropdownMenu(expanded = kindMenu, onDismissRequest = { kindMenu = false }) {
                    WorkoutPhaseKind.entries.forEach { type ->
                        DropdownMenuItem(text = { Text(type.name) }, onClick = {
                            row.phase = row.phase.copy(kind = type)
                            kindMenu = false
                        })
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                ReperaMetaTextField(
                    caption = "Repeticiones",
                    value = phase.repeatCount?.toString() ?: "",
                    onValueChange = { raw ->
                        val n = raw.toIntOrNull()?.takeIf { it in 1..200 }
                        if (raw.isEmpty() || n != null) row.phase = row.phase.copy(repeatCount = n)
                    }, modifier = Modifier.weight(1f), placeholder = "1")
                ReperaMetaTextField(
                    caption = "Trabajo (s)",
                    value = phase.workSeconds?.toString() ?: "",
                    onValueChange = { raw ->
                        val n = raw.toIntOrNull()?.takeIf { it in 1..86400 }
                        if (raw.isEmpty() || n != null) row.phase = row.phase.copy(workSeconds = n)
                    }, modifier = Modifier.weight(1f), placeholder = "0")
                ReperaMetaTextField(
                    caption = "Descanso (s)",
                    value = phase.restSeconds?.toString() ?: "",
                    onValueChange = { raw ->
                        val n = raw.toIntOrNull()?.takeIf { it in 0..86400 }
                        if (raw.isEmpty() || n != null) row.phase = row.phase.copy(restSeconds = n)
                    }, modifier = Modifier.weight(1f), placeholder = "0")
            }
            val references = block.entries.mapNotNull { item ->
                item.itemId?.let { it to item.name }
            }
            var movementMenu by remember(phase.id) { mutableStateOf(false) }
            Box {
                OutlinedButton(onClick = { movementMenu = true }) {
                    Text("Ejercicios asignados (" + phase.movementIDs.size + ")")
                }
                DropdownMenu(expanded = movementMenu, onDismissRequest = { movementMenu = false }) {
                    references.forEach { (id, name) ->
                        DropdownMenuItem(
                            text = { Text((if (phase.movementIDs.contains(id)) "✓ " else "") + name) },
                            onClick = {
                                val ids = if (phase.movementIDs.contains(id))
                                    phase.movementIDs.filterNot { it == id }
                                else phase.movementIDs + id
                                row.phase = row.phase.copy(movementIDs = ids)
                            })
                    }
                }
            }
            var methodMenu by remember(phase.id) { mutableStateOf(false) }
            Box {
                OutlinedButton(onClick = { methodMenu = true }) {
                    Text("Método: " + (phase.technique?.method?.name ?: "normal"))
                }
                DropdownMenu(expanded = methodMenu, onDismissRequest = { methodMenu = false }) {
                    WorkoutSetMethod.entries.forEach { method ->
                        DropdownMenuItem(text = { Text(method.name) }, onClick = {
                            row.phase = row.phase.copy(technique =
                                if (method == WorkoutSetMethod.standard) null else
                                    (phase.technique ?: WorkoutStrengthTechnique(method)).copy(method = method))
                            methodMenu = false
                        })
                    }
                }
            }
            phase.technique?.let { technique ->
                ReperaMetaTextField(caption = "Tempo (31X1)",
                    value = technique.tempo ?: "",
                    onValueChange = {
                        val tempo = it.uppercase().take(4)
                        if (tempo.isEmpty() || tempo.matches(Regex("[0-9X]{0,4}")))
                            row.phase = row.phase.copy(technique = technique.copy(
                                tempo = tempo.takeIf { it.isNotEmpty() }))
                    }, placeholder = "31X1")
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    ReperaMetaTextField(caption = "Pausa (s)",
                        value = technique.pauseSeconds?.toString() ?: "",
                        onValueChange = { raw ->
                            val n = raw.toIntOrNull()?.takeIf { it in 0..300 }
                            if (raw.isEmpty() || n != null)
                                row.phase = row.phase.copy(technique = technique.copy(pauseSeconds = n))
                        }, modifier = Modifier.weight(1f), placeholder = "0")
                    ReperaMetaTextField(caption = "Descanso intra-serie",
                        value = technique.intraSetRestSeconds?.toString() ?: "",
                        onValueChange = { raw ->
                            val n = raw.toIntOrNull()?.takeIf { it in 0..300 }
                            if (raw.isEmpty() || n != null)
                                row.phase = row.phase.copy(technique = technique.copy(intraSetRestSeconds = n))
                        }, modifier = Modifier.weight(1f), placeholder = "0")
                }
                if (technique.method == WorkoutSetMethod.cluster) {
                    ReperaMetaTextField(caption = "Reps por cluster",
                        value = technique.clusterReps?.toString() ?: "",
                        onValueChange = { raw ->
                            val n = raw.toIntOrNull()?.takeIf { it in 1..100 }
                            if (raw.isEmpty() || n != null)
                                row.phase = row.phase.copy(technique = technique.copy(clusterReps = n))
                        }, placeholder = "3")
                }
                if (technique.method == WorkoutSetMethod.dropSet) {
                    ReperaMetaTextField(caption = "Reducciones de peso (%)",
                        value = technique.dropPercentages.joinToString(","),
                        onValueChange = { raw ->
                            val numbers = raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                                .mapNotNull { it.toDoubleOrNull() }
                            if (numbers.size <= 8 && numbers.all { it in 0.0..100.0 })
                                row.phase = row.phase.copy(technique = technique.copy(dropPercentages = numbers))
                        }, placeholder = "20,15")
                }
            }
            ReperaMetaTextField(caption = "Indicaciones",
                value = phase.notes ?: "",
                onValueChange = { row.phase = row.phase.copy(notes = it.take(2000)) },
                placeholder = "Opcional")
            Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                if (row.parentID == null) {
                    TextButton(onClick = {
                        block.advancedPhases.add(AdvancedPhaseUi(
                            WorkoutPhase(kind = WorkoutPhaseKind.main, title = "Subfase"),
                            parentID = phase.id))
                    }) { Text("+ Subfase") }
                }
                TextButton(onClick = {
                    val target = index - 1
                    if (target >= 0 && block.advancedPhases[target].parentID == row.parentID)
                        block.advancedPhases.add(target, block.advancedPhases.removeAt(index))
                }, enabled = index > 0) { Text("↑") }
                TextButton(onClick = {
                    val target = index + 1
                    if (target < block.advancedPhases.size &&
                        block.advancedPhases[target].parentID == row.parentID)
                        block.advancedPhases.add(target, block.advancedPhases.removeAt(index))
                }, enabled = index + 1 < block.advancedPhases.size) { Text("↓") }
                TextButton(onClick = {
                    block.advancedPhases.removeAll { it.phase.id == phase.id || it.parentID == phase.id }
                }) { Text("Eliminar") }
            }
        }
    }
    OutlinedButton(onClick = {
        block.advancedPhases.add(AdvancedPhaseUi(WorkoutPhase(
            kind = WorkoutPhaseKind.main, title = "Trabajo principal",
            movementIDs = block.entries.mapNotNull { it.itemId }
        )))
    }) { Text("+ Añadir fase") }
}
