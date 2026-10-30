package dev.repera.mobile
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** Listado compacto: sin título interno (va en ReperaSectionTitle). */
@Composable
internal fun ProgressExercisesCard(exercises: List<ProgressExerciseRow>, onExercise: (String) -> Unit) {
    var all by remember { mutableStateOf(false) }
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
            if (exercises.isEmpty()) {
                Box(Modifier.padding(vertical = 12.dp)) {
                    ReperaEmptyState(
                        title = "Sin ejercicios aún",
                        subtitle = "Cuando registres series, verás el progreso aquí"
                    )
                }
            } else {
                val listed = exercises.take(5)
                listed.forEachIndexed { index, e ->
                    ProgressListRow(
                        title = e.name,
                        trailing = e.topWeight?.let { "${formatWeight(it)} kg" },
                        onClick = { onExercise(e.id) }
                    )
                    if (index < listed.lastIndex || exercises.size > 5) {
                        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
                    }
                }
                if (exercises.size > 5) {
                    TextButton(
                        onClick = { all = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .semantics { contentDescription = "Ver todos los ejercicios" }
                    ) {
                        Text("Ver más", color = brandGreenReadable)
                        Spacer(Modifier.weight(1f))
                        Icon(
                            Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                            contentDescription = null,
                            tint = brandGreenReadable
                        )
                    }
                }
            }
        }
    }
    if (all) {
        AlertDialog(
            onDismissRequest = { all = false },
            title = { Text("Todos los ejercicios del periodo") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    exercises.forEachIndexed { index, e ->
                        ProgressListRow(
                            title = e.name,
                            trailing = e.topWeight?.let { "${formatWeight(it)} kg" },
                            onClick = {
                                all = false
                                onExercise(e.id)
                            }
                        )
                        if (index < exercises.lastIndex) {
                            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
                        }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { all = false }) { Text("Cerrar") } }
        )
    }
}

/** Fila de listado Progreso: título negro + valor a la derecha, sin mucho aire. */
@Composable
internal fun ProgressListRow(
    title: String,
    trailing: String? = null,
    showChevron: Boolean = true,
    onClick: (() -> Unit)? = null
) {
    Row(
        Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            title,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        if (!trailing.isNullOrBlank()) {
            Text(
                trailing,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
        if (showChevron && onClick != null) {
            Icon(
                Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/** Apple mobilityProgressCard: tiempo, sesiones y (Pro) enlaces — sin título interno. */
@Composable
internal fun ProgressMobilityCard(
    sessions: Int,
    seconds: Int,
    proLinks: List<ProgressExerciseRow>,
    onExercise: (String) -> Unit
) {
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
            ProgressListRow(
                title = "Tiempo registrado",
                trailing = ProgressTilesModel.mobilityDuration(seconds),
                showChevron = false
            )
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
            ProgressListRow(
                title = "Sesiones con movilidad",
                trailing = "$sessions",
                showChevron = false
            )
            proLinks.forEach { e ->
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
                ProgressListRow(title = e.name, onClick = { onExercise(e.id) })
            }
        }
    }
}

/** Apple freeExerciseTrendPreview: fixed fictitious weights, never reads user data. */
@Composable
internal fun ProgressExerciseTrendPreview(today: java.time.LocalDate) {
    val weights = listOf(42.0, 45.0, 44.0, 49.0, 47.0, 52.0, 55.0)
    ReperaCard(
        Modifier
            .fillMaxWidth()
            .semantics { contentDescription = "Ejemplo de evolución por ejercicio, datos simulados." }
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Evolución por ejercicio", style = MaterialTheme.typography.titleMedium)
                Text("Ejemplo", style = MaterialTheme.typography.labelMedium)
            }
            Text("Evolución de carga · datos ficticios", style = MaterialTheme.typography.bodySmall)
            ExerciseTrendPreviewChart(weights)
        }
    }
}

/** StatsView freeExerciseTrendPreview: session axis0..8 (not calendar dates), y35..65. */
@Composable
internal fun ExerciseTrendPreviewChart(weights: List<Double>) {
    val accent = MaterialTheme.colorScheme.primary
    val grid = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.18f)
    Column(
        Modifier
            .fillMaxWidth()
            .semantics { contentDescription = "Sesiones 1, 3, 5, 7; peso de 35 a 65 kg; ejemplo ficticio" }
    ) {
        androidx.compose.foundation.Canvas(
            Modifier
                .fillMaxWidth()
                .height(195.dp)
                .then(Modifier.semantics { contentDescription = "Gráfica de ejemplo por sesión, altura 195" })
        ) {
            fun x(session: Float) = session / 8f * size.width
            fun y(value: Double) = size.height - ((value - 35.0) / 30.0 * size.height).toFloat()
            listOf(1f, 3f, 5f, 7f).forEach { v ->
                drawLine(
                    grid,
                    androidx.compose.ui.geometry.Offset(x(v), 0f),
                    androidx.compose.ui.geometry.Offset(x(v), size.height),
                    1.dp.toPx()
                )
            }
            val samples = weights.mapIndexed { i, v -> ReadinessCurve.Point(x(i + 1f), y(v)) }
            if (samples.isNotEmpty()) {
                val curve = androidx.compose.ui.graphics.Path()
                curve.moveTo(samples.first().x, samples.first().y)
                ReadinessCurve.segments(samples).forEach { c ->
                    curve.cubicTo(c.control1.x, c.control1.y, c.control2.x, c.control2.y, c.end.x, c.end.y)
                }
                clipRect {
                    drawPath(
                        curve,
                        accent,
                        style = androidx.compose.ui.graphics.drawscope.Stroke(
                            2.5.dp.toPx(),
                            cap = androidx.compose.ui.graphics.StrokeCap.Round
                        )
                    )
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(22.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
                listOf("1", "3", "5", "7").forEach {
                    Text(
                        it,
                        modifier = Modifier.weight(1f),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }
        }
    }
}
