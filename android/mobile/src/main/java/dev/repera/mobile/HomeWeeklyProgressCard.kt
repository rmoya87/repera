package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.WeeklyWorkoutDay

@Composable
internal fun HomeWeeklyProgressCard(days: List<WeeklyWorkoutDay>, goal: Int?, modifier: Modifier = Modifier) {
    val count = days.sumOf { it.completedCount }
    val trained = days.count { it.completedCount > 0 }
    val planned = days.count { it.planned }
    val summary = when {
        goal != null && goal > 0 -> "$trained de $goal días"
        planned > 0 -> "$trained de $planned días"
        trained == 1 -> "1 día entrenado"
        else -> "$trained días entrenados"
    }
    ReperaCard(modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                Text(
                    "Progreso semanal",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
                )
                Spacer(Modifier.weight(1f))
                Text(
                    summary,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                days.forEach { day ->
                    val label = listOf("LU", "MA", "MI", "JU", "VI", "SA", "DO")[day.date.dayOfWeek.value - 1]
                    val done = day.completedCount > 0
                    val description = "$label ${day.date.dayOfMonth}: " + when {
                        done -> "entrenamiento completado"
                        day.planned -> "entrenamiento planificado"
                        else -> "sin entrenamiento"
                    }
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.weight(1f).semantics(mergeDescendants = true) {
                            contentDescription = description
                        }
                    ) {
                        Text(
                            label,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Box(
                            modifier = Modifier
                                .padding(top = 8.dp)
                                .size(32.dp)
                                .background(if (done) brandGreen else Color.Transparent, CircleShape)
                                .border(
                                    if (done) 0.dp else 1.5.dp,
                                    if (day.planned && !done) brandGreen.copy(alpha = 0.55f)
                                    else MaterialTheme.colorScheme.outlineVariant,
                                    CircleShape
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            if (done) {
                                Icon(
                                    Icons.Outlined.Check,
                                    contentDescription = null,
                                    tint = Color.Black,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                    }
                }
            }
            if (goal != null && goal > 0) {
                LinearProgressIndicator(
                    progress = { (trained.toFloat() / goal).coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth().height(4.dp),
                    color = brandGreen,
                    trackColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f),
                    strokeCap = StrokeCap.Round
                )
            } else if (planned > 0) {
                LinearProgressIndicator(
                    progress = { (trained.toFloat() / planned).coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth().height(4.dp),
                    color = brandGreen,
                    trackColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f),
                    strokeCap = StrokeCap.Round
                )
            }
        }
    }
}

/** Same cutoff as the current Apple HomeView. Width includes the page's content padding. */
internal fun homeUsesExpandedLayout(widthDp: Float): Boolean = adaptiveCardColumns(widthDp) == 2
