package dev.repera.mobile
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.domain.*
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow

/** Only observed device-local samples. RMSSD is not labeled as Apple's SDNN. */
@Composable
internal fun RecoveryHistoryCards(
    recovery: RecoveryState,
    range: ProgressTimeRange,
    monday: Boolean,
    pro: Boolean = true,
    outerHorizontalPaddingDp: Float = 0f
) {
    val today = java.time.LocalDate.now()
    val trend = recovery.trend.filter { range.contains(it.day, today, monday) }
    val sleep = SleepPeriodSummary.forRange(recovery.nights, range, today, monday)
    val nights = sleep.nights
    val vitals = recovery.vitals.filter { range.contains(it.day, today, monday) }
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = adaptiveCardColumns(maxWidth.value, outerHorizontalPaddingDp)
        val readinessHeight = readinessChartHeightDp((maxWidth.value - 16f * (columns - 1)) / columns, columns > 1).dp
        val sleepHeight = sleepChartHeightDp((maxWidth.value - 16f * (columns - 1)) / columns, columns > 1).dp
        val latestForHeight = recovery.vitals.maxByOrNull { it.day }
        val additionalVitals = latestForHeight?.let {
            it.oxygenSaturationPercent != null || it.wristTemperatureCelsius != null || it.heartRateRecoveryBpm != null
        } ?: false
        val physiologyHeight =
            physiologyChartHeightDp((maxWidth.value - 16f * (columns - 1)) / columns, columns > 1, additionalVitals).dp
        val cards = mutableListOf<@Composable () -> Unit>()
        cards.add { TrainingReadinessCard(recovery) }
        cards.add {
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ReperaSectionTitle("Evolución de recuperación")
                ReperaCard(Modifier.fillMaxWidth()) {
                    Column(
                        Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        if (pro) {
                            if (trend.size < 2) {
                                EmptyHealthChart(
                                    "Aún no hay suficientes registros para ver la recuperación.",
                                    0.0, 10.0, readinessHeight
                                )
                            } else {
                                DayPointLineChart(
                                    trend,
                                    valueFormat = { "${kotlin.math.round(it).toInt()}/10" },
                                    bounds = 0.0..10.0,
                                    readinessStyle = true,
                                    chartHeight = readinessHeight
                                )
                            }
                        } else {
                            DayPointLineChart(
                                listOf(5.0, 6.0, 7.0, 6.0, 8.0, 7.0, 9.0).mapIndexed { i, v ->
                                    ProgressDayPoint(today.minusDays((6 - i).toLong()), v)
                                },
                                valueFormat = { "${it.toInt()}/10" },
                                bounds = 0.0..10.0,
                                interactive = false,
                                readinessStyle = true,
                                readinessGradient = false,
                                readinessPreview = true,
                                chartHeight = readinessHeight
                            )
                            Text("No son tus datos de recuperación", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            }
        }
        cards.add {
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ReperaSectionTitle("Sueño esta semana")
                ReperaCard(Modifier.fillMaxWidth()) {
                    Column(
                        Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        if (nights.isEmpty()) {
                            EmptyHealthChart(
                                "Sin registros de sueño en Health Connect todavía.",
                                0.0, 10.0, sleepHeight
                            )
                        } else {
                            Row(
                                Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Column(Modifier.widthIn(min = 72.dp)) {
                                    Text(
                                        "Media",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        "${formatWeight(sleep.hours ?: 0.0)} h",
                                        style = MaterialTheme.typography.headlineSmall,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    if (sleep.outsideRange) {
                                        Text(
                                            "Fuera del periodo",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                                val total = sleep.deep + sleep.rem + sleep.light
                                if (total > 0.2) {
                                    SleepPhaseBar(
                                        deep = sleep.deep,
                                        rem = sleep.rem,
                                        light = sleep.light,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                            RecoverySleepChart(nights, sleepHeight)
                            if (nights.size > 1) {
                                Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                                    nights.sortedByDescending { it.day }.forEachIndexed { index, night ->
                                        ProgressListRow(
                                            title = night.day.format(reperaDayFormatter),
                                            trailing = "${formatWeight(night.hours)} h",
                                            showChevron = false
                                        )
                                        if (index < nights.lastIndex) {
                                            HorizontalDivider(
                                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        cards.add {
            if (pro) {
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    ReperaSectionTitle("Constantes fisiológicas")
                    ReperaCard(Modifier.fillMaxWidth()) {
                        Column(
                            Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            val hrv = vitals.mapNotNull { it.hrvMilliseconds?.let { v -> ProgressDayPoint(it.day, v) } }
                            val rest =
                                vitals.mapNotNull { it.restingHeartRateBpm?.let { v -> ProgressDayPoint(it.day, v) } }
                            RecoveryVitalTrend(hrv, physiologyHeight)
                            Text(
                                "RMSSD de Health Connect no equivale a SDNN de Apple Salud.",
                                style = MaterialTheme.typography.bodySmall
                            )
                            val breathing =
                                vitals.mapNotNull { it.respiratoryRateBpm?.let { v -> ProgressDayPoint(it.day, v) } }
                            RecoveryVitalBars(rest, breathing)
                            val latest = recovery.vitals.maxByOrNull { it.day }
                            if (latest != null &&
                                (latest.oxygenSaturationPercent != null || latest.wristTemperatureCelsius != null)
                            ) {
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    latest.oxygenSaturationPercent?.let { v ->
                                        Column(Modifier.weight(1f).testTag("recovery_tile_spo2")) {
                                            Text(
                                                "Oxígeno en sangre",
                                                style = MaterialTheme.typography.labelMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                            Text(
                                                ReperaNumberFormat.decimal(v, maximumFractionDigits = 0) + " %",
                                                style = MaterialTheme.typography.titleLarge
                                            )
                                        }
                                    }
                                    latest.wristTemperatureCelsius?.let { v ->
                                        Column(Modifier.weight(1f).testTag("recovery_tile_temp")) {
                                            Text(
                                                "T nocturna",
                                                style = MaterialTheme.typography.labelMedium,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                            Text(
                                                ReperaNumberFormat.decimal(v, maximumFractionDigits = 1) + " °C",
                                                style = MaterialTheme.typography.titleLarge
                                            )
                                        }
                                    }
                                }
                            }
                            latest?.heartRateRecoveryBpm?.let { v ->
                                Column(Modifier.fillMaxWidth().testTag("recovery_tile_hr_recovery")) {
                                    Text(
                                        "Recuperación cardíaca 1 min",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        Math.round(v).toString() + " lpm",
                                        style = MaterialTheme.typography.titleLarge
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    ReperaSectionTitle("Constantes fisiológicas")
                    RecoveryPhysiologyPreviewCard(today, physiologyHeight)
                }
            }
        }
        if (recovery.menstrualDays.isNotEmpty()) {
            cards.add {
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    ReperaSectionTitle("Ciclo menstrual")
                    CycleHistoryCard(recovery, monday)
                }
            }
        }
        Column(
            Modifier.fillMaxWidth().testTag("recovery_columns_$columns"),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            cards.chunked(columns).forEach { row ->
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    row.forEach { card -> Box(Modifier.weight(1f)) { card() } }
                    repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
    }
}

/** Barra de fases: etiquetas arriba, valor dentro de cada color, esquinas redondeadas. */
@Composable
internal fun SleepPhaseBar(
    deep: Double,
    rem: Double,
    light: Double,
    modifier: Modifier = Modifier
) {
    val total = maxOf(0.01, deep + rem + light)
    val deepColor = Color(0xFF1B2A6B)
    val remColor = Color(0xFF5168C8)
    val lightColor = Color(0xFF8CA6F0)
    Column(modifier, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(Modifier.fillMaxWidth()) {
            listOf("Profundo" to deep, "REM" to rem, "Ligero" to light).forEach { (label, hours) ->
                Text(
                    label,
                    modifier = Modifier.weight((hours / total).toFloat().coerceAtLeast(0.01f)),
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        Row(
            Modifier
                .fillMaxWidth()
                .height(32.dp)
                .clip(RoundedCornerShape(10.dp))
        ) {
            listOf(
                deep to deepColor,
                rem to remColor,
                light to lightColor
            ).forEach { (hours, color) ->
                if (hours > 0) {
                    Box(
                        Modifier
                            .weight(hours.toFloat())
                            .fillMaxHeight()
                            .background(color),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "${formatWeight(hours)} h",
                            style = MaterialTheme.typography.labelMedium.copy(fontSize = 11.sp),
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            maxLines = 1
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CycleHistoryCard(recovery: RecoveryState, monday: Boolean) {
    val today = java.time.LocalDate.now()
    val phase = RecoveryEngine.cyclePhase(recovery.menstrualDays, today)
    val label = when (phase) {
        RecoveryEngine.CyclePhase.MENSTRUAL -> "Menstruación registrada"
        RecoveryEngine.CyclePhase.FOLLICULAR -> "Fase folicular estimada"
        RecoveryEngine.CyclePhase.OVULATORY -> "Ovulación aproximada"
        RecoveryEngine.CyclePhase.LUTEAL -> "Fase lútea estimada"
        RecoveryEngine.CyclePhase.UNKNOWN -> "Fase no disponible"
    }
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(label, style = MaterialTheme.typography.titleSmall)
            if (recovery.menstrualDays.isEmpty()) {
                Text("Sin registros de menstruación. Activa el seguimiento del ciclo en Ajustes para leer los datos autorizados.")
            } else {
                val recent = recovery.menstrualDays.filter { !it.isBefore(today.minusDays(89)) && !it.isAfter(today) }
                if (recent.isEmpty()) Text("Sin registros en los últimos 90 días")
                else DayPointLineChart(recent.map { ProgressDayPoint(it, 1.0) }, valueFormat = { "Menstruación registrada" })
                Text("Registros de menstruación de los últimos 90 días", style = MaterialTheme.typography.bodySmall)
            }
            Text("Calendario de las últimas seis semanas", style = MaterialTheme.typography.titleSmall)
            val firstWeekday = if (monday) java.time.DayOfWeek.MONDAY else java.time.DayOfWeek.SUNDAY
            val currentWeek = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(firstWeekday))
            val start = currentWeek.minusWeeks(5)
            Row(Modifier.fillMaxWidth()) {
                (0..6).forEach { offset ->
                    Text(
                        start.plusDays(offset.toLong()).dayOfWeek.getDisplayName(
                            java.time.format.TextStyle.NARROW,
                            java.util.Locale("es")
                        ),
                        Modifier.weight(1f)
                    )
                }
            }
            (0..5).forEach { week ->
                Row(Modifier.fillMaxWidth()) {
                    (0..6).forEach { offset ->
                        val day = start.plusDays((week * 7 + offset).toLong())
                        val observed = day in recovery.menstrualDays
                        val background =
                            if (observed) MaterialTheme.colorScheme.tertiaryContainer
                            else if (day == today) MaterialTheme.colorScheme.primaryContainer
                            else MaterialTheme.colorScheme.surfaceVariant
                        Surface(Modifier.weight(1f).padding(1.dp), color = background, shape = MaterialTheme.shapes.small) {
                            Text(
                                day.dayOfMonth.toString(),
                                Modifier
                                    .padding(vertical = 6.dp)
                                    .then(
                                        Modifier.semantics {
                                            contentDescription =
                                                "${day.format(reperaDayFormatter)}${if (observed) ", menstruación registrada" else ""}"
                                        }
                                    ),
                                textAlign = TextAlign.Center,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                }
            }
            Text("Días registrados de menstruación", style = MaterialTheme.typography.bodySmall)
            if (recovery.positiveOvulationTests.isNotEmpty()) {
                Text("Pruebas de ovulación positivas registradas: ${recovery.positiveOvulationTests.size}")
            }
            Text(
                "Fase aproximada solo si hay suficientes ciclos compatibles. Nunca equivale a una ovulación confirmada ni debe utilizarse para anticoncepción.",
                style = MaterialTheme.typography.bodySmall
            )
            Text(
                "Solo en este dispositivo. No se incluye en Drive, copias ni datos compartidos con centros.",
                style = MaterialTheme.typography.bodySmall
            )
        }
    }
}
