package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.MuscleLoadEngine
import dev.repera.domain.MuscleMapEngine
import dev.repera.domain.MuscleTaxonomy
import kotlin.math.max

/**
 * Equilibrio muscular: mapa por fatiga retenida (vida media) + barras por
 * series del periodo. Port 1:1 de MuscleBalanceCard (iOS).
 */
@Composable
internal fun MuscleBalanceCard(
    loadAll: Map<String, Double>,
    loadHard: Map<String, Double>,
    fatigueAll: Map<String, Double>,
    fatigueHard: Map<String, Double>,
    hasHardSets: Boolean,
    includesEstimatedWodMuscles: Boolean = false
) {
    var hardOnly by rememberSaveable { mutableStateOf(false) }
    var selected by rememberSaveable { mutableStateOf<String?>(null) }
    var expanded by rememberSaveable { mutableStateOf(false) }

    val load = if (hardOnly) loadHard else loadAll
    val fatigue = if (hardOnly) fatigueHard else fatigueAll
    val (worked, missed) = MuscleLoadEngine.ranked(load)

    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // R7 P1: sin título interno duplicado («EQUILIBRIO MUSCULAR» ya va fuera).
            ReperaTopicSegmentedPicker(
                options = listOf("Fatiga", "Esfuerzo"),
                selected = if (hardOnly) "Esfuerzo" else "Fatiga",
                onSelected = { label ->
                    hardOnly = label == "Esfuerzo"
                    selected = null
                    expanded = false
                },
                optionTestTag = { i, _ -> "muscle_balance_mode_$i" }
            )

            BodyMapView(
                load = load,
                fatigueScores = fatigue,
                selected = selected,
                onSelect = { slug -> selected = if (selected == slug) null else slug }
            )
            BodyMapLegend()

            BarsSection(load, fatigue, worked, selected, expanded) { expanded = !expanded }

            if (hardOnly && !hasHardSets) {
                Text("Registra el RIR de las series para identificar el esfuerzo alto.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            if (missed.isNotEmpty()) {
                Text(if (hardOnly) "Sin series duras en este periodo" else "Sin entrenar en este periodo",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    missed.forEach { slug ->
                        Text(MuscleTaxonomy.displayName(slug),
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier
                                .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(50))
                                .padding(horizontal = 10.dp, vertical = 5.dp))
                    }
                }
            } else if (worked.isNotEmpty()) {
                Text(if (hardOnly) "Cada grupo tuvo al menos una serie dura."
                    else "Cada grupo muscular recibió trabajo.",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (!hardOnly && includesEstimatedWodMuscles) {
                Text("Los movimientos WOD confirmados sin series registradas aportan una estimación mínima de estímulo muscular.",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun BodyMapLegend() {
    Row(modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically) {
        Text("Recuperado", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer4()
        for (level in 0..4) {
            Box(modifier = Modifier.testTag("body_legend_$level")
                .width(12.dp)
                .height(12.dp)
                .background(BodyMapPalette.fill(level, BodyMapPalette.neutralFor(MaterialTheme.colorScheme.surfaceContainerHighest)), RoundedCornerShape(2.dp)))
        }
        Spacer4()
        Text("Fatigado", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun Spacer4() {
    androidx.compose.foundation.layout.Spacer(Modifier.width(6.dp))
}

@Composable
private fun BarsSection(
    load: Map<String, Double>,
    fatigue: Map<String, Double>,
    worked: List<String>,
    selected: String?,
    expanded: Boolean,
    onToggleExpanded: () -> Unit
) {
    val maxLoad = worked.firstOrNull()?.let { load[it] } ?: 0.0
    val visible = when {
        selected != null -> listOf(selected)
        expanded -> worked
        else -> worked.take(4)
    }

    if (visible.isEmpty()) {
        Text("Sin series en este periodo.", fontSize = 13.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            visible.forEach { slug ->
                val value = load[slug] ?: 0.0
                val level = max(MuscleMapEngine.level(fatigue[slug] ?: 0.0), 1)
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(MuscleTaxonomy.displayName(slug),
                        fontSize = 13.sp,
                        fontWeight = if (selected == slug) FontWeight.Bold else FontWeight.Normal,
                        modifier = Modifier.width(96.dp))
                    Box(modifier = Modifier.weight(1f).height(8.dp)
                        .background(MaterialTheme.colorScheme.surfaceVariant, CircleShape)) {
                        val fraction = if (maxLoad > 0) (value / maxLoad).toFloat() else 0f
                        Box(modifier = Modifier
                            .fillMaxWidth(fraction.coerceIn(0f, 1f))
                            .height(8.dp)
                            .background(BodyMapPalette.fill(level, BodyMapPalette.neutralFor(MaterialTheme.colorScheme.surfaceContainerHighest)), CircleShape))
                    }
                    Text("${formatSets(value)} series",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.width(72.dp),
                        textAlign = androidx.compose.ui.text.style.TextAlign.End)
                }
            }
            if (selected == null && worked.count() > 4) {
                TextButton(onClick = onToggleExpanded) {
                    Text(if (expanded) "Ver menos" else "Ver más",
                        fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

private fun formatSets(v: Double): String =
    dev.repera.domain.ReperaNumberFormat.decimal(v)
