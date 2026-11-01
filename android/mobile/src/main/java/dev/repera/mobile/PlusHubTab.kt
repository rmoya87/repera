package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Tab «+» (paridad iOS PlusHubView): Clases del día | Centro (ficha + plan).
 * Tap en la caja → detalle; Apuntarme = botón verde con texto negro.
 */
@Composable
internal fun PlusHubTab(
    connected: Boolean,
    loading: Boolean,
    submitting: Boolean,
    errorMessage: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    onRefresh: () -> Unit,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onCancel: (BusinessCenterStore.Booking) -> Unit,
    loadRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)? = null,
) {
    var hubTab by remember { mutableStateOf(0) } // 0 clases, 1 centro
    var selectedDay by remember { mutableStateOf(LocalDate.now()) }
    var detailOccurrence by remember {
        mutableStateOf<BusinessCenterStore.Occurrence?>(null)
    }
    var pendingCancellation by remember {
        mutableStateOf<BusinessCenterStore.Booking?>(null)
    }
    val zone = remember { ZoneId.systemDefault() }
    val dayFmt = remember {
        DateTimeFormatter.ofPattern("HH:mm", Locale("es")).withZone(zone)
    }
    val weekdayFmt = remember {
        DateTimeFormatter.ofPattern("EE", Locale("es"))
    }
    val dateFmt = remember {
        DateTimeFormatter.ofPattern("EEEE d MMMM", Locale("es")).withZone(zone)
    }

    LaunchedEffect(Unit) { onRefresh() }

    Column(
        Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        ReperaTopicSegmentedPicker(
            options = listOf("Clases", "Centro"),
            selected = if (hubTab == 0) "Clases" else "Centro",
            onSelected = { hubTab = if (it == "Clases") 0 else 1 },
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 12.dp)
        )
        when {
            !connected -> {
                ReperaCard(Modifier.padding(top = 16.dp).fillMaxWidth()) {
                    Column(
                        Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text("Conecta tu cuenta", style = MaterialTheme.typography.titleSmall)
                        Text(
                            "Inicia sesión para ver clases del gimnasio y tu centro.",
                            style = MaterialTheme.typography.bodySmall
                        )
                        TextButton(onClick = onRefresh) { Text("Reintentar") }
                    }
                }
            }
            hubTab == 0 -> ClassesPane(
                loading = loading,
                errorMessage = errorMessage,
                snapshot = snapshot,
                selectedDay = selectedDay,
                onSelectDay = { selectedDay = it },
                weekdayFmt = weekdayFmt,
                dayFmt = dayFmt,
                zone = zone,
                submitting = submitting,
                onBook = onBook,
                onRequestCancel = { pendingCancellation = it },
                onOpenDetail = { detailOccurrence = it }
            )
            else -> CenterPane(
                snapshot = snapshot,
                dayFmt = dayFmt,
                onOpenDetail = { detailOccurrence = it }
            )
        }
    }

    detailOccurrence?.let { occurrence ->
        ClassDetailPage(
            occurrence = occurrence,
            snapshot = snapshot,
            dayFmt = dayFmt,
            dateFmt = dateFmt,
            submitting = submitting,
            loadRoster = loadRoster,
            onBook = onBook,
            onRequestCancel = { pendingCancellation = it },
            onClose = { detailOccurrence = null }
        )
    }

    pendingCancellation?.let { booking ->
        ReperaConfirmSheet(
            title = "¿Cancelar la reserva?",
            message = "Se te desapunta y, si tenías plaza confirmada, se te devuelve la sesión al plan.",
            confirmTitle = "Confirmar cancelación",
            onConfirm = {
                pendingCancellation = null
                onCancel(booking)
            },
            onCancel = { pendingCancellation = null },
            icon = Icons.Outlined.EventBusy,
            confirmDestructive = true
        )
    }
}

@Composable
private fun ClassesPane(
    loading: Boolean,
    errorMessage: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    selectedDay: LocalDate,
    onSelectDay: (LocalDate) -> Unit,
    weekdayFmt: DateTimeFormatter,
    dayFmt: DateTimeFormatter,
    zone: ZoneId,
    submitting: Boolean,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
) {
    val days = remember {
        (-3..10).map { LocalDate.now().plusDays(it.toLong()) }
    }
    val dayClasses = remember(snapshot, selectedDay) {
        (snapshot?.occurrences.orEmpty())
            .filter { occ ->
                occ.kind == "class" &&
                    occ.status == "active" &&
                    runCatching {
                        Instant.parse(occ.startsAt).atZone(zone).toLocalDate()
                    }.getOrNull() == selectedDay
            }
            .sortedBy { it.startsAt }
    }

    LazyColumn(
        contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        item {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(days) { day ->
                    val selected = day == selectedDay
                    TextButton(
                        onClick = { onSelectDay(day) },
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(
                                if (selected) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.surfaceVariant
                            )
                            .width(48.dp)
                            .height(56.dp)
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                weekdayFmt.format(day).take(1).uppercase(),
                                color = if (selected) MaterialTheme.colorScheme.onPrimary
                                else MaterialTheme.colorScheme.onSurface,
                                style = MaterialTheme.typography.labelSmall
                            )
                            Text(
                                day.dayOfMonth.toString(),
                                color = if (selected) MaterialTheme.colorScheme.onPrimary
                                else MaterialTheme.colorScheme.onSurface,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
        if (loading) {
            item { CircularProgressIndicator(Modifier.padding(24.dp)) }
        }
        errorMessage?.takeIf { it.isNotBlank() }?.let { msg ->
            item {
                Text(msg, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
        }
        if (dayClasses.isEmpty() && !loading) {
            item {
                ReperaCard(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Sin clases este día", style = MaterialTheme.typography.titleSmall)
                        Text(
                            "Cuando tu gimnasio publique horarios, aparecerán aquí con su color.",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }
        items(dayClasses, key = { it.id }) { occurrence ->
            ClassDayCard(
                occurrence = occurrence,
                centerName = snapshot?.centerName(occurrence.orgId).orEmpty(),
                booking = snapshot?.bookingFor(occurrence.id),
                places = snapshot?.remainingPlaces(occurrence),
                passes = snapshot?.availablePasses(occurrence).orEmpty(),
                canBook = snapshot?.canBookNow(occurrence) == true,
                opensAt = snapshot?.bookingOpensAt(occurrence),
                dayFmt = dayFmt,
                submitting = submitting,
                onBook = onBook,
                onRequestCancel = onRequestCancel,
                onOpenDetail = onOpenDetail
            )
        }
    }
}

@Composable
private fun ClassDayCard(
    occurrence: BusinessCenterStore.Occurrence,
    centerName: String,
    booking: BusinessCenterStore.Booking?,
    places: Int?,
    passes: List<BusinessCenterStore.Pass>,
    canBook: Boolean,
    opensAt: Instant?,
    dayFmt: DateTimeFormatter,
    submitting: Boolean,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
) {
    val accent = parseClassColor(occurrence.color)
    val full = (places ?: 1) == 0
    val canTap = canBook && !full && passes.isNotEmpty()
    ReperaCard(Modifier.fillMaxWidth()) {
        Row(
            Modifier
                .fillMaxWidth()
                .heightIn(min = 96.dp)
        ) {
            Box(
                Modifier
                    .width(5.dp)
                    .fillMaxHeight()
                    .background(accent)
            )
            Column(
                Modifier
                    .weight(1f)
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clickable { onOpenDetail(occurrence) },
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(occurrence.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    if (centerName.isNotBlank()) {
                        Text(centerName, style = MaterialTheme.typography.bodySmall)
                    }
                    runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()?.let { start ->
                        val end = occurrence.endsAt?.let { runCatching { Instant.parse(it) }.getOrNull() }
                        Text(
                            buildString {
                                append(dayFmt.format(start))
                                if (end != null) {
                                    append(" – ")
                                    append(dayFmt.format(end))
                                    append(" · ")
                                    append(durationLabel(start, end))
                                }
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                    }
                    occurrence.location?.takeIf { it.isNotBlank() }?.let {
                        Text(it, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                if (booking != null) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            if (booking.status == "waitlist") "Lista de espera" else "Apuntado",
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.SemiBold
                        )
                        TextButton(
                            onClick = { onRequestCancel(booking) },
                            enabled = !submitting,
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text("Cancelar", color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.SemiBold)
                        }
                    }
                } else {
                    Button(
                        onClick = {
                            val pass = passes.firstOrNull() ?: return@Button
                            onBook(occurrence, pass)
                        },
                        enabled = canTap && !submitting,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = Color.Black,
                            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(if (full) "Completa" else "Apuntarme", fontWeight = FontWeight.Bold)
                    }
                    Text(
                        when {
                            opensAt != null -> "Inscripción desde ${dayFmt.format(opensAt)}"
                            full -> "Sin plazas libres"
                            places != null -> "$places plaza${if (places == 1) "" else "s"} libre${if (places == 1) "" else "s"}"
                            else -> ""
                        },
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun ClassDetailPage(
    occurrence: BusinessCenterStore.Occurrence,
    snapshot: BusinessCenterStore.Snapshot?,
    dayFmt: DateTimeFormatter,
    dateFmt: DateTimeFormatter,
    submitting: Boolean,
    loadRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)?,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onClose: () -> Unit,
) {
    var roster by remember { mutableStateOf<BusinessCenterStore.ClassRoster?>(null) }
    var loadingRoster by remember { mutableStateOf(true) }
    val booking = snapshot?.bookingFor(occurrence.id)
    val places = snapshot?.remainingPlaces(occurrence)
    val open = snapshot?.canBookNow(occurrence) == true
    val full = (places ?: 1) == 0
    val passes = snapshot?.availablePasses(occurrence).orEmpty()
    val accent = parseClassColor(occurrence.color)
    val center = snapshot?.centers?.firstOrNull { it.id == occurrence.orgId }
    val start = runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()
    val end = occurrence.endsAt?.let { runCatching { Instant.parse(it) }.getOrNull() }

    LaunchedEffect(occurrence.id) {
        loadingRoster = true
        roster = loadRoster?.invoke(occurrence.id)
        loadingRoster = false
    }

    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = onClose) { Text("Cerrar") }
                Spacer(Modifier.weight(1f))
            }
            Column(
                Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 14.dp)
                    .padding(bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                val canTap = open && !full && passes.isNotEmpty()
                ReperaCard(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                        Row(
                            verticalAlignment = Alignment.Top,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Box(
                                Modifier
                                    .width(5.dp)
                                    .height(56.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(accent)
                            )
                            Column(
                                Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Text(
                                    occurrence.title,
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = accent
                                )
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    CenterAvatar(center = center, size = 30.dp)
                                    Text(
                                        center?.name ?: snapshot?.centerName(occurrence.orgId).orEmpty(),
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                            ClassBookingCircleButton(
                                booked = booking != null,
                                enabled = if (booking != null) !submitting else canTap && !submitting,
                                onClick = {
                                    if (booking != null) {
                                        onRequestCancel(booking)
                                    } else {
                                        val pass = passes.firstOrNull() ?: return@ClassBookingCircleButton
                                        onBook(occurrence, pass)
                                    }
                                }
                            )
                        }
                        if (booking != null) {
                            val waitlist = booking.status == "waitlist"
                            Text(
                                if (waitlist) "Lista de espera" else "Apuntado",
                                color = if (waitlist) MaterialTheme.colorScheme.onSurfaceVariant else accent,
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier
                                    .clip(RoundedCornerShape(50))
                                    .background(
                                        if (waitlist) MaterialTheme.colorScheme.surfaceVariant
                                        else accent.copy(alpha = 0.14f)
                                    )
                                    .padding(horizontal = 12.dp, vertical = 7.dp)
                            )
                        }
                        if (start != null) {
                            DetailRow("Fecha", dateFmt.format(start).replaceFirstChar { it.uppercase() })
                            Row(
                                Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                MetricTile(
                                    title = "Hora",
                                    value = buildString {
                                        append(dayFmt.format(start))
                                        if (end != null) {
                                            append(" – ")
                                            append(dayFmt.format(end))
                                        }
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                                MetricTile(
                                    title = "Duración",
                                    value = if (end != null) durationLabel(start, end) else "—",
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                        val reserved = roster?.reserved ?: places?.let { (occurrence.capacity ?: 0) - it }
                        val capacity = roster?.capacity ?: occurrence.capacity
                        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                            if (reserved != null && capacity != null) {
                                DetailRow("Plazas", "$reserved / $capacity")
                            }
                            occurrence.location?.takeIf { it.isNotBlank() }?.let {
                                DetailRow("Sala", it)
                            }
                        }
                    }
                }

                if (!loadingRoster && roster?.coach != null) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            "Entrenador",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        ReperaCard(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(18.dp)) {
                                PersonRow(
                                    name = roster!!.coach!!.displayName,
                                    avatarUrl = roster!!.coach!!.avatarUrl,
                                    subtitle = "Impartirá la clase"
                                )
                            }
                        }
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    val count = roster?.attendees?.size ?: 0
                    Text(
                        if (count > 0) "Apuntados ($count)" else "Apuntados",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    ReperaCard(Modifier.fillMaxWidth()) {
                        Column(
                            Modifier.padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            when {
                                loadingRoster -> CircularProgressIndicator(Modifier.size(24.dp))
                                roster?.attendees.isNullOrEmpty() -> Text(
                                    "Todavía no hay nadie apuntado. Sé el primero.",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                else -> roster!!.attendees.forEach { person ->
                                    PersonRow(
                                        name = person.displayName,
                                        avatarUrl = person.avatarUrl,
                                        subtitle = if (person.status == "waitlist") "Lista de espera" else null
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

@Composable
private fun MetricTile(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier
            .clip(RoundedCornerShape(14.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            title,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun DetailRow(title: String, value: String) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Text(
            title,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 12.dp)
        )
    }
}

@Composable
private fun ClassBookingCircleButton(
    booked: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val container = if (booked) {
        MaterialTheme.colorScheme.error.copy(alpha = 0.18f)
    } else if (enabled) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.surfaceVariant
    }
    val content = when {
        booked -> MaterialTheme.colorScheme.error
        enabled -> Color.White
        else -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)
    }
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(container)
            .clickable(enabled = enabled, onClick = onClick)
    ) {
        Icon(
            imageVector = if (booked) Icons.Filled.Close else Icons.Filled.Check,
            contentDescription = if (booked) "Desapuntarse" else "Apuntarme",
            tint = content,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
private fun PersonRow(name: String, avatarUrl: String?, subtitle: String?) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AvatarInitials(name = name, hint = avatarUrl)
        Column {
            Text(name, fontWeight = FontWeight.SemiBold)
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

@Composable
private fun AvatarInitials(name: String, hint: String? = null) {
    val initials = name.split(" ")
        .filter { it.isNotBlank() }
        .take(2)
        .mapNotNull { it.firstOrNull()?.uppercaseChar()?.toString() }
        .joinToString("")
        .ifBlank { if (hint.isNullOrBlank()) "?" else "·" }
    Box(
        Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primary),
        contentAlignment = Alignment.Center
    ) {
        Text(initials, color = Color.White, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun CenterAvatar(center: BusinessCenterStore.Organization?, size: androidx.compose.ui.unit.Dp) {
    val name = center?.name.orEmpty()
    val initials = name.split(" ")
        .filter { it.isNotBlank() }
        .take(2)
        .mapNotNull { it.firstOrNull()?.uppercaseChar()?.toString() }
        .joinToString("")
        .ifBlank { "?" }
    Box(
        Modifier
            .size(size)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.9f)),
        contentAlignment = Alignment.Center
    ) {
        Text(
            initials,
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = (size.value * 0.32f).sp
        )
    }
}

@Composable
private fun CenterPane(
    snapshot: BusinessCenterStore.Snapshot?,
    dayFmt: DateTimeFormatter,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
) {
    val linkedIds = snapshot?.athleteCenterIds.orEmpty()
    val centers = snapshot?.centers.orEmpty().filter { it.id in linkedIds }
    LazyColumn(
        contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        if (centers.isEmpty()) {
            item {
                ReperaCard(Modifier.fillMaxWidth()) {
                    Text(
                        "Todavía no perteneces a ningún centro. Cuando te inviten, verás aquí su ficha y tu plan.",
                        modifier = Modifier.padding(16.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
        centers.forEach { center ->
            val upcoming = upcomingBookings(snapshot, center.id)
            item(key = "hero-${center.id}") {
                CenterHeroCard(center = center, next = upcoming.firstOrNull(), dayFmt = dayFmt)
            }
            item(key = "plan-title-${center.id}") {
                Text(
                    "Plan",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 4.dp)
                )
            }
            val passes = snapshot?.activePasses(center.id).orEmpty()
            if (passes.isEmpty()) {
                item(key = "empty-${center.id}") {
                    ReperaCard(Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("Sin plan activo", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                            Text(
                                "Pide a tu centro que te asigne un bono o acceso.",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                }
            } else {
                passes.forEach { pass ->
                    item(key = pass.id) {
                        PlanCard(
                            centerName = center.name,
                            pass = pass,
                            offerName = snapshot?.offerName(pass)
                        )
                    }
                }
            }
            if (upcoming.isNotEmpty()) {
                item(key = "upcoming-title-${center.id}") {
                    Text(
                        "Próximas reservas",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 4.dp)
                    )
                }
                item(key = "upcoming-${center.id}") {
                    ReperaCard(Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            upcoming.take(3).forEach { row ->
                                Row(
                                    Modifier
                                        .fillMaxWidth()
                                        .clickable { onOpenDetail(row.occurrence) },
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        Modifier
                                            .width(4.dp)
                                            .height(36.dp)
                                            .clip(RoundedCornerShape(3.dp))
                                            .background(parseClassColor(row.occurrence.color))
                                    )
                                    Column(Modifier.weight(1f)) {
                                        Text(row.occurrence.title, fontWeight = FontWeight.SemiBold)
                                        runCatching { Instant.parse(row.occurrence.startsAt) }.getOrNull()?.let { start ->
                                            Text(
                                                dayFmt.format(start),
                                                style = MaterialTheme.typography.labelSmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }
                                    Text("›", color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                }
            }
            item(key = "payments-${center.id}") {
                PaymentsCard(snapshot = snapshot, centerId = center.id)
            }
            item(key = "history-${center.id}") {
                ClassHistoryCard(snapshot = snapshot, centerId = center.id, dayFmt = dayFmt)
            }
        }
    }
}

@Composable
private fun PaymentsCard(snapshot: BusinessCenterStore.Snapshot?, centerId: String) {
    val payments = snapshot?.paymentHistory(centerId).orEmpty().take(5)
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            "Últimos pagos",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp)
        )
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (payments.isEmpty()) {
                    Text(
                        "Todavía no hay pagos registrados con este centro.",
                        style = MaterialTheme.typography.bodySmall
                    )
                } else {
                    payments.forEach { pass ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    snapshot?.offerName(pass) ?: if (pass.kind == "class") "Plan de clases" else "Plan de citas",
                                    fontWeight = FontWeight.SemiBold
                                )
                                Text(paymentLabel(pass), style = MaterialTheme.typography.labelSmall)
                            }
                            pass.paidAmountCents?.let { cents ->
                                Text(
                                    String.format(Locale("es"), "%.2f €", cents / 100.0),
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ClassHistoryCard(
    snapshot: BusinessCenterStore.Snapshot?,
    centerId: String,
    dayFmt: DateTimeFormatter,
) {
    val history = snapshot?.pastBookings(centerId).orEmpty().take(8)
    val occById = snapshot?.occurrences.orEmpty().associateBy { it.id }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            "Historial de clases",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp)
        )
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (history.isEmpty()) {
                    Text(
                        "Aún no has asistido ni reservado clases con este centro.",
                        style = MaterialTheme.typography.bodySmall
                    )
                } else {
                    history.forEach { booking ->
                        val occ = occById[booking.occurrenceId]
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(Modifier.weight(1f)) {
                                Text(occ?.title ?: "Clase", fontWeight = FontWeight.SemiBold)
                                occ?.startsAt?.let { raw ->
                                    runCatching { Instant.parse(raw) }.getOrNull()?.let { start ->
                                        Text(
                                            dayFmt.format(start),
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                            Text(
                                bookingStatusLabel(booking.status),
                                color = MaterialTheme.colorScheme.primary,
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CenterHeroCard(
    center: BusinessCenterStore.Organization,
    next: UpcomingRow?,
    dayFmt: DateTimeFormatter,
) {
    val email = center.publicEmail?.trim().orEmpty()
    val phone = center.phone?.trim().orEmpty()
    val uriHandler = LocalUriHandler.current
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                CenterAvatar(center = center, size = 64.dp)
                Column(verticalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.weight(1f)) {
                    Text(center.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    center.tagline?.takeIf { it.isNotBlank() }?.let {
                        Text(it, style = MaterialTheme.typography.bodySmall)
                    }
                    if (next != null) {
                        val start = runCatching { Instant.parse(next.occurrence.startsAt) }.getOrNull()
                        Text(
                            buildString {
                                append("Próxima: ")
                                append(next.occurrence.title)
                                if (start != null) {
                                    append(" · ")
                                    append(dayFmt.format(start))
                                }
                            },
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            if (email.isNotBlank() || phone.isNotBlank()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (email.isNotBlank()) {
                        Text(
                            email,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.clickable { uriHandler.openUri("mailto:$email") }
                        )
                    }
                    if (phone.isNotBlank()) {
                        val digits = phone.filter { it.isDigit() || it == '+' }
                        Text(
                            phone,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.clickable(enabled = digits.isNotBlank()) {
                                uriHandler.openUri("tel:$digits")
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PlanCard(
    centerName: String,
    pass: BusinessCenterStore.Pass,
    offerName: String?,
) {
    val unlimited = pass.remainingCredits >= 9000 || pass.totalCredits >= 9000
    val used = (pass.totalCredits - pass.remainingCredits).coerceAtLeast(0)
    val kindLabel = if (pass.kind == "class") "Clases / acceso" else "Citas 1:1"
    val daysLeft = pass.validUntil?.let { raw ->
        runCatching {
            val end = Instant.parse(raw).atZone(ZoneId.systemDefault()).toLocalDate()
            Duration.between(LocalDate.now().atStartOfDay(), end.atStartOfDay()).toDays().toInt()
        }.getOrNull()
    }
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(Modifier.weight(1f)) {
                    Text(
                        offerName ?: kindLabel,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(centerName, style = MaterialTheme.typography.bodySmall)
                }
                Text(
                    kindLabel,
                    color = MaterialTheme.colorScheme.primary,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f))
                        .padding(horizontal = 10.dp, vertical = 6.dp)
                )
            }
            if (unlimited) {
                Text(
                    "Acceso ilimitado",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            } else {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        "${pass.remainingCredits}",
                        style = MaterialTheme.typography.displaySmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        " de ${pass.totalCredits} sesiones",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(start = 6.dp, bottom = 8.dp)
                    )
                }
                LinearProgressIndicator(
                    progress = { used.toFloat() / pass.totalCredits.coerceAtLeast(1).toFloat() },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (daysLeft != null) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(
                        if (daysLeft >= 0) "Quedan $daysLeft día${if (daysLeft == 1) "" else "s"}"
                        else "Caducado",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                    pass.validUntil?.let { raw ->
                        val formatted = runCatching {
                            Instant.parse(raw).atZone(ZoneId.systemDefault()).toLocalDate()
                                .format(DateTimeFormatter.ofPattern("d MMM yyyy", Locale("es")))
                        }.getOrDefault(raw)
                        Text("Hasta $formatted", style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
            Text(
                "Para renovar, habla con tu centro; te asignarán el siguiente plan cuando cobren fuera de Repera.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private data class UpcomingRow(
    val booking: BusinessCenterStore.Booking,
    val occurrence: BusinessCenterStore.Occurrence,
)

private fun upcomingBookings(
    snapshot: BusinessCenterStore.Snapshot?,
    orgId: String,
): List<UpcomingRow> {
    val now = Instant.now()
    return snapshot?.bookings.orEmpty().mapNotNull { booking ->
        if (booking.orgId != orgId) return@mapNotNull null
        if (booking.status != "booked" && booking.status != "waitlist") return@mapNotNull null
        val occ = snapshot.occurrences.firstOrNull { it.id == booking.occurrenceId } ?: return@mapNotNull null
        val start = runCatching { Instant.parse(occ.startsAt) }.getOrNull() ?: return@mapNotNull null
        if (start.isBefore(now)) return@mapNotNull null
        UpcomingRow(booking, occ)
    }.sortedBy { it.occurrence.startsAt }
}

private fun kindLabel(kind: String): String = when (kind) {
    "trainer", "coach", "personal_trainer" -> "Entrenador"
    "gym", "center" -> "Gimnasio"
    "sports_center" -> "Centro deportivo"
    else -> "Centro"
}

private fun paymentLabel(pass: BusinessCenterStore.Pass): String = when {
    pass.issuanceType == "complimentary" || pass.paymentMethod == "complimentary" -> "Cortesía"
    pass.paymentMethod == "cash" -> "Efectivo"
    pass.paymentMethod == "transfer" -> "Transferencia"
    pass.paymentMethod == "card" -> "Tarjeta"
    pass.paymentMethod == "other" -> "Otro cobro"
    pass.issuanceType == "manual_offline" -> "Cobro externo"
    else -> "Plan"
}

private fun bookingStatusLabel(status: String): String = when (status) {
    "attended" -> "Asististe"
    "booked" -> "Reservada"
    "waitlist" -> "Lista de espera"
    "cancelled" -> "Cancelada"
    "no_show" -> "No presentado"
    else -> status
}

private fun durationLabel(start: Instant, end: Instant): String {
    val mins = Duration.between(start, end).toMinutes().toInt().coerceAtLeast(1)
    if (mins >= 60) {
        val h = mins / 60
        val m = mins % 60
        return if (m == 0) "$h h" else "$h h $m min"
    }
    return "$mins min"
}

private fun parseClassColor(raw: String?): Color {
    val hex = raw?.trim()?.removePrefix("#").orEmpty()
    if (hex.length != 6) return Color(0xFF22834D)
    val value = hex.toLongOrNull(16) ?: return Color(0xFF22834D)
    return Color(
        red = ((value shr 16) and 0xff) / 255f,
        green = ((value shr 8) and 0xff) / 255f,
        blue = (value and 0xff) / 255f
    )
}
