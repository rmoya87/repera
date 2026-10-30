package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.MonitorWeight
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
internal fun HealthGoalsSection(
    value: HealthGoals,
    busy: Boolean,
    onChange: (HealthGoals) -> Unit
) {
    var steps by remember(value) { mutableStateOf(value.steps?.toString().orEmpty()) }
    var energy by remember(value) { mutableStateOf(value.energyKcal?.toString().orEmpty()) }
    var minutes by remember(value) { mutableStateOf(value.minutes?.toString().orEmpty()) }
    var weekly by remember(value) { mutableStateOf(value.weeklyWorkouts?.toString().orEmpty()) }
    var weight by remember(value) { mutableStateOf(value.weightKg?.toString().orEmpty()) }
    var error by remember { mutableStateOf<String?>(null) }
    Text(
        "Vacío = sin objetivo. No se inventa progreso.",
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ReperaSectionTitle("Objetivos diarios")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column {
                GoalIconRow(
                    icon = Icons.Outlined.DirectionsWalk,
                    label = "Pasos",
                    text = steps,
                    busy = busy,
                    onChange = { steps = it }
                )
                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = MaterialTheme.colorScheme.outlineVariant
                )
                GoalIconRow(
                    icon = Icons.Outlined.LocalFireDepartment,
                    label = "Calorías activas (kcal)",
                    text = energy,
                    busy = busy,
                    onChange = { energy = it }
                )
                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    color = MaterialTheme.colorScheme.outlineVariant
                )
                GoalIconRow(
                    icon = Icons.Outlined.Timer,
                    label = "Tiempo de entreno (min)",
                    text = minutes,
                    busy = busy,
                    onChange = { minutes = it }
                )
            }
        }
        ReperaSectionTitle("Objetivo semanal")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            GoalIconRow(
                icon = Icons.Outlined.FitnessCenter,
                label = "Entrenamientos por semana",
                text = weekly,
                busy = busy,
                onChange = { weekly = it }
            )
        }
        ReperaSectionTitle("Objetivo corporal")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            GoalIconRow(
                icon = Icons.Outlined.MonitorWeight,
                label = "Peso objetivo (kg)",
                text = weight,
                busy = busy,
                onChange = { weight = it }
            )
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
        OutlinedButton(
            enabled = !busy,
            onClick = {
                try {
                    fun int(s: String) = s.trim().takeIf { it.isNotEmpty() }?.toInt()
                    val next = HealthGoals(
                        int(steps),
                        int(energy),
                        int(minutes),
                        int(weekly),
                        weight.trim().takeIf { it.isNotEmpty() }?.replace(',', '.')?.toDouble()
                    )
                    HealthGoals.apply(org.json.JSONObject(), next)
                    error = null
                    onChange(next)
                } catch (_: Exception) {
                    error =
                        "Revisa los rangos: pasos100–100000, kcal10–10000, minutos1–1440, entrenamientos1–21, peso20–350kg."
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) { Text("Guardar objetivos") }
    }
}

@Composable
private fun GoalIconRow(
    icon: ImageVector,
    label: String,
    text: String,
    busy: Boolean,
    onChange: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(22.dp)
        )
        Text(
            label,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f)
        )
        BasicTextField(
            value = text,
            onValueChange = onChange,
            enabled = !busy,
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyLarge.copy(
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.End
            ),
            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.widthIn(min = 72.dp, max = 120.dp),
            decorationBox = { inner ->
                if (text.isEmpty()) {
                    Text(
                        "—",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.End,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                inner()
            }
        )
    }
}
