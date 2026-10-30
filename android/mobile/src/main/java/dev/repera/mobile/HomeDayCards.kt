package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.DirectionsWalk
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.NightsStay
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

private val registerCardShape = RoundedCornerShape(12.dp)
private val chipShape = RoundedCornerShape(8.dp)

/** «ENTRENO · 7:11» (hoy) o «VIERNES · 7:11» (iOS WorkoutListCaption / RegisterSessionChrome). */
internal fun homeDayTimeCaption(day: LocalDate, timeLabel: String?): String {
    val locale = Locale("es", "ES")
    val dayLabel = if (day == LocalDate.now()) "ENTRENO"
    else day.dayOfWeek.getDisplayName(TextStyle.FULL, locale).uppercase(locale)
    return if (timeLabel.isNullOrBlank()) dayLabel else "$dayLabel · $timeLabel"
}

internal fun homeTimeFromIso(iso: String?): String? {
    if (iso.isNullOrBlank()) return null
    return runCatching {
        val instant = Instant.parse(iso)
        DateTimeFormatter.ofPattern("H:mm").withZone(ZoneId.systemDefault()).format(instant)
    }.getOrNull()
}

internal fun homeDurationText(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return if (m > 0) "${m} min" else "${s} s"
}

internal fun homeMinutesLabel(seconds: Double?): String? {
    val s = seconds ?: return null
    if (s <= 0) return null
    return "${(s / 60.0).toInt()} min"
}

@Composable
internal fun HomeRegisterChip(text: String, icon: ImageVector) {
    // surfaceVariant (#F2F5F3 claro / #2C2C2E oscuro): evita chip blanco en dark (R4 #57).
    Row(
        modifier = Modifier
            .clip(chipShape)
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(12.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(text, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
internal fun HomeRegisterLeadingIcon(
    icon: ImageVector,
    tint: Color = brandGreen,
    /** Paridad iOS: círculo = tint @ 22 %. Día libre / vacío → gris, no verde. */
    circleColor: Color = tint.copy(alpha = 0.22f)
) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(circleColor),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(22.dp))
    }
}

/**
 * Swipe reveal en cards compactas de Inicio (paridad RegisterSwipeRevealCard iOS):
 * izquierda = Eliminar; derecha = Editar cuando [onEdit] no es null.
 */
@Composable
internal fun HomeSwipeRevealCard(
    key: String,
    busy: Boolean,
    onDelete: () -> Unit,
    onEdit: (() -> Unit)? = null,
    content: @Composable () -> Unit
) {
    val density = LocalDensity.current
    val deleteWidthPx = with(density) { 88.dp.toPx() }
    val editWidthPx = with(density) { if (onEdit != null) 72.dp.toPx() else 0f }
    var offset by remember(key) { mutableStateOf(0f) }
    var confirmDelete by remember(key) { mutableStateOf(false) }
    // Clip del contenedor al mismo radio que la card frontal: sin picos de
    // Editar/Eliminar sobresaliendo por las esquinas del entreno.
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(registerCardShape)
    ) {
        Row(
            modifier = Modifier.matchParentSize(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (onEdit != null) {
                TextButton(
                    onClick = { offset = 0f; onEdit() },
                    enabled = !busy && offset > 0f,
                    modifier = Modifier
                        .width(72.dp)
                        .fillMaxHeight()
                        .background(Color(0xFF0A84FF))
                ) {
                    Icon(Icons.Outlined.Edit, contentDescription = "Editar", tint = Color.White)
                }
            } else {
                Spacer(Modifier.width(0.dp))
            }
            TextButton(
                onClick = { offset = 0f; confirmDelete = true },
                enabled = !busy && offset < 0f,
                modifier = Modifier
                    .width(88.dp)
                    .fillMaxHeight()
                    .background(Color(0xFFFF3B30)) // rojo eléctrico (systemRed)
            ) {
                Icon(
                    Icons.Outlined.Delete,
                    contentDescription = "Eliminar",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(registerCardShape)
                .offset { IntOffset(offset.toInt(), 0) }
                .pointerInput(key, busy, onEdit != null) {
                    if (busy) return@pointerInput
                    detectDragGestures(
                        onDrag = { change, drag ->
                            if (kotlin.math.abs(drag.x) > kotlin.math.abs(drag.y)) {
                                val maxLeft = -deleteWidthPx
                                val maxRight = editWidthPx
                                offset = (offset + drag.x).coerceIn(maxLeft, maxRight)
                                change.consume()
                            }
                        },
                        onDragEnd = {
                            offset = when {
                                offset < -deleteWidthPx * 0.45f -> -deleteWidthPx
                                onEdit != null && offset > editWidthPx * 0.45f -> editWidthPx
                                else -> 0f
                            }
                        }
                    )
                }
        ) { content() }
    }
    if (confirmDelete) {
        ReperaConfirmSheet(
            title = "¿Eliminar entreno?",
            message = "Esta acción no se puede deshacer.",
            confirmTitle = "Eliminar",
            onConfirm = { confirmDelete = false; onDelete() },
            onCancel = { confirmDelete = false }
        )
    }
}

@Composable
internal fun HomeDayRegisterCard(
    caption: String,
    title: String,
    leadingIcon: ImageVector,
    chips: List<Pair<ImageVector, String>>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    leadingIconTint: Color = brandGreen,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(registerCardShape)
            .background(MaterialTheme.colorScheme.surface)
            .border(0.7.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.75f), registerCardShape)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            HomeRegisterLeadingIcon(leadingIcon, tint = leadingIconTint)
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    caption,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 0.3.sp,
                        fontSize = 11.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    title,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium,
                        fontSize = 17.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 2
                )
            }
        }
        if (chips.isNotEmpty()) {
            Row(
                modifier = Modifier
                    .padding(start = 70.dp, end = 14.dp, top = 6.dp)
                    .height(24.dp),
                horizontalArrangement = Arrangement.spacedBy(7.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                chips.forEach { (icon, label) -> HomeRegisterChip(label, icon) }
            }
        }
    }
}

@Composable
internal fun HomeEmptyDayCard(day: LocalDate) {
    // Paridad iOS emptyWorkoutCard: icono gris, subtítulo sin chip.
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(registerCardShape)
            .background(MaterialTheme.colorScheme.surface)
            .border(0.7.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.75f), registerCardShape)
            .padding(vertical = 10.dp)
            .testTag("home_empty_day")
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            HomeRegisterLeadingIcon(
                Icons.Outlined.EventBusy,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    homeDayTimeCaption(day, null),
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 0.3.sp,
                        fontSize = 11.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Sin entrenamientos programados",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium,
                        fontSize = 17.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
        // Pegado al título (iOS padding.top 2); icono/fondo grises vía tint.
        Row(
            modifier = Modifier
                .padding(start = 70.dp, end = 14.dp, top = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            Icon(
                Icons.Outlined.NightsStay,
                contentDescription = null,
                modifier = Modifier.size(12.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                "Día libre · puedes añadir un entrenamiento",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
internal fun HomeCompletedWorkoutCard(
    workout: WorkoutHistoryEntry,
    day: LocalDate,
    prCount: Int = 0,
    onClick: () -> Unit
) {
    val chips = buildList {
        if (workout.timerDetails != null) {
            val secs = workout.timerDetails.configuredSeconds
            add(Icons.Outlined.Timer to homeDurationText(secs))
        } else {
            homeMinutesLabel(workout.displayDurationMinutes().takeIf { it > 0 }?.times(60.0))?.let {
                add(Icons.Outlined.Schedule to it)
            }
        }
        workout.recordedDistanceMeters?.takeIf { it > 0 }?.let {
            add(Icons.Outlined.Route to "${dev.repera.domain.ReperaNumberFormat.decimal(it / 1000)} km")
        }
        if (prCount > 0) {
            add(Icons.Outlined.EmojiEvents to "$prCount PR")
        }
        workout.review?.let {
            add(Icons.Outlined.Star to it.scoreLabel)
        }
    }
    val icon = when {
        workout.timerDetails != null -> Icons.Outlined.Timer
        workout.liveSportID != null -> Icons.AutoMirrored.Outlined.DirectionsWalk
        else -> Icons.Outlined.FitnessCenter
    }
    HomeDayRegisterCard(
        caption = homeDayTimeCaption(day, homeTimeFromIso(workout.startedAtIso ?: workout.startedAt)),
        title = workout.title,
        leadingIcon = icon,
        chips = chips,
        onClick = onClick
    )
}

/**
 * Ficha «en curso» en el listado del día (paridad dayActionRow iOS):
 * círculo naranja + play, título del ejercicio, tap → Play / Comenzar.
 */
@Composable
internal fun HomeInProgressCard(
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    HomeDayRegisterCard(
        caption = "EN CURSO",
        title = title,
        leadingIcon = Icons.Filled.PlayArrow,
        chips = if (subtitle.isNotBlank()) {
            listOf(Icons.Outlined.Schedule to subtitle)
        } else emptyList(),
        onClick = onClick,
        modifier = modifier.testTag("home_in_progress_card"),
        leadingIconTint = brandAmber
    )
}

@Composable
internal fun HomePlannedRoutineCard(
    routine: RoutineEntry,
    day: LocalDate,
    onClick: () -> Unit
) {
    val time = routine.timeMinutes?.let { "%d:%02d".format(it / 60, it % 60) }
    val chips = buildList {
        if (routine.blocks.isNotEmpty()) {
            add(Icons.Outlined.FitnessCenter to "${routine.blocks.size} bloq.")
        }
    }
    // Solo realizados (historial) van en verde; planificados siempre gris.
    val tint = MaterialTheme.colorScheme.onSurfaceVariant
    HomeDayRegisterCard(
        caption = homeDayTimeCaption(day, time),
        title = routine.title,
        leadingIcon = Icons.Outlined.FitnessCenter,
        chips = chips,
        onClick = onClick,
        leadingIconTint = tint
    )
}

@Composable
internal fun HomeAddWorkoutButton(enabled: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(brandGreen)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 18.dp)
            .height(54.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Outlined.Add, contentDescription = null, tint = Color.Black,
            modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(12.dp))
        Text(
            "Añadir nuevo entreno",
            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
            color = Color.Black
        )
        Spacer(Modifier.weight(1f))
        Icon(
            Icons.AutoMirrored.Outlined.KeyboardArrowRight,
            contentDescription = null,
            tint = Color.Black.copy(alpha = 0.85f),
            modifier = Modifier.size(18.dp)
        )
    }
}

@Composable
internal fun HomeActivityTodayCard(
    isToday: Boolean,
    steps: Long?,
    stepsGoal: Int?,
    energyKcal: Double?,
    energyGoal: Int?,
    minutes: Double?,
    minutesGoal: Int?,
    healthPlaceholder: String,
    @Suppress("UNUSED_PARAMETER") onHealthConnect: () -> Unit,
    @Suppress("UNUSED_PARAMETER") healthAccess: HealthAccessState
) {
    ReperaCard(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(
                if (isToday) "Actividad de hoy" else "Actividad del día",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold)
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                HomeActivityMetricTile(
                    title = "Pasos",
                    value = steps?.let { dev.repera.domain.ReperaNumberFormat.integer(it.toInt()) } ?: "—",
                    unit = "",
                    icon = Icons.AutoMirrored.Outlined.DirectionsWalk,
                    tint = brandGreen,
                    progress = progressOrNull(steps?.toDouble(), stepsGoal?.toDouble()),
                    modifier = Modifier.weight(1f)
                )
                HomeActivityMetricTile(
                    title = "Calorías",
                    value = energyKcal?.let {
                        dev.repera.domain.ReperaNumberFormat.integer(it.toInt())
                    } ?: "—",
                    unit = "kcal",
                    icon = Icons.Outlined.LocalFireDepartment,
                    tint = Color(0xFFFF9F0A),
                    progress = progressOrNull(energyKcal, energyGoal?.toDouble()),
                    modifier = Modifier.weight(1f)
                )
                HomeActivityMetricTile(
                    title = "Tiempo",
                    value = minutes?.let {
                        dev.repera.domain.ReperaNumberFormat.integer(it.toInt())
                    } ?: "—",
                    unit = "min",
                    icon = Icons.Outlined.Schedule,
                    tint = Color(0xFF0A84FF),
                    progress = progressOrNull(minutes, minutesGoal?.toDouble()),
                    modifier = Modifier.weight(1f)
                )
            }
            // iOS HomeView: sin enlace «Conectar Salud» dentro de Actividad de hoy.
        }
    }
}

@Composable
private fun HomeActivityMetricTile(
    title: String,
    value: String,
    unit: String,
    icon: ImageVector,
    tint: Color,
    progress: Float?,
    modifier: Modifier = Modifier
) {
    // Paridad HomeView.homeActivityMetric: icono+título en fila, valor centrado, barra.
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(17.dp))
            Text(
                title,
                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
        }
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.Center) {
            Text(
                value,
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 22.sp
                ),
                maxLines = 1
            )
            if (unit.isNotEmpty()) {
                Text(
                    " $unit",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(bottom = 3.dp)
                )
            }
        }
        LinearProgressIndicator(
            progress = { progress ?: 0f },
            modifier = Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)),
            color = if (progress != null && progress > 0f) tint
            else MaterialTheme.colorScheme.outlineVariant,
            trackColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f),
            strokeCap = StrokeCap.Round
        )
    }
}

private fun progressOrNull(value: Double?, goal: Double?): Float? {
    if (value == null || goal == null || goal <= 0) return null
    return (value / goal).toFloat().coerceIn(0f, 1f)
}
