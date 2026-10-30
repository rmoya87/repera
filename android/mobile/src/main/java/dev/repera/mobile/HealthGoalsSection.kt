package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.MonitorWeight
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
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

    fun commitAll(
        nextSteps: String = steps,
        nextEnergy: String = energy,
        nextMinutes: String = minutes,
        nextWeekly: String = weekly,
        nextWeight: String = weight
    ) {
        try {
            fun int(s: String) = s.trim().takeIf { it.isNotEmpty() }?.toInt()
            val next = HealthGoals(
                int(nextSteps),
                int(nextEnergy),
                int(nextMinutes),
                int(nextWeekly),
                nextWeight.trim().takeIf { it.isNotEmpty() }?.replace(',', '.')?.toDouble()
            )
            HealthGoals.apply(org.json.JSONObject(), next)
            error = null
            onChange(next)
        } catch (_: Exception) {
            error =
                "Revisa los rangos: pasos100–100000, kcal10–10000, minutos1–1440, entrenamientos1–21, peso20–350kg."
        }
    }

    Column(
        Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Una sola caja: Pasos · Calorías · Tiempo · Entrenamientos · Peso.
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            GoalIconRow(
                icon = Icons.AutoMirrored.Outlined.DirectionsWalk,
                label = "Pasos",
                text = steps,
                busy = busy,
                allowsDecimal = false,
                onChange = {
                    steps = it
                    commitAll(nextSteps = it)
                }
            )
            GoalDivider()
            GoalIconRow(
                icon = Icons.Outlined.LocalFireDepartment,
                label = "Calorías activas (kcal)",
                text = energy,
                busy = busy,
                allowsDecimal = false,
                onChange = {
                    energy = it
                    commitAll(nextEnergy = it)
                }
            )
            GoalDivider()
            GoalIconRow(
                icon = Icons.Outlined.Timer,
                label = "Tiempo de entreno (min)",
                text = minutes,
                busy = busy,
                allowsDecimal = false,
                onChange = {
                    minutes = it
                    commitAll(nextMinutes = it)
                }
            )
            GoalDivider()
            GoalIconRow(
                icon = Icons.Outlined.FitnessCenter,
                label = "Entrenamientos por semana",
                text = weekly,
                busy = busy,
                allowsDecimal = false,
                onChange = {
                    weekly = it
                    commitAll(nextWeekly = it)
                }
            )
            GoalDivider()
            GoalIconRow(
                icon = Icons.Outlined.MonitorWeight,
                label = "Peso objetivo (kg)",
                text = weight,
                busy = busy,
                allowsDecimal = true,
                onChange = {
                    weight = it
                    commitAll(nextWeight = it)
                }
            )
        }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
    }
}

@Composable
private fun GoalDivider() {
    HorizontalDivider(
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f),
        modifier = Modifier.padding(horizontal = 16.dp)
    )
}

@Composable
private fun GoalIconRow(
    icon: ImageVector,
    label: String,
    text: String,
    busy: Boolean,
    allowsDecimal: Boolean,
    onChange: (String) -> Unit
) {
    var showPad by remember { mutableStateOf(false) }
    var draft by remember(text) { mutableStateOf(text) }
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
        ReperaMetaNumericField(
            caption = "",
            value = text,
            onClick = {
                if (!busy) {
                    draft = text
                    showPad = true
                }
            },
            enabled = !busy,
            modifier = Modifier.widthIn(min = 72.dp, max = 120.dp)
        )
    }
    if (showPad) {
        ReperaNumericKeypadSheet(
            title = label,
            draft = draft,
            onDraftChange = { draft = it },
            onDismiss = {
                onChange(draft)
                showPad = false
            },
            onCommit = {
                onChange(it)
                showPad = false
            },
            allowsDecimal = allowsDecimal,
            showDraftPreview = true
        )
    }
}
