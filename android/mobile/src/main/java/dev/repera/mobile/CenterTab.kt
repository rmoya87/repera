package dev.repera.mobile

import androidx.activity.compose.BackHandler
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material.icons.outlined.MarkEmailUnread
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

private enum class CenterSection(val kind: String?, @StringRes val label: Int) {
    CLASSES("class", R.string.center_section_classes),
    APPOINTMENTS("appointment", R.string.center_section_appointments),
    OPEN_ACCESS("open_access", R.string.center_section_open_access),
    AGENDA(null, R.string.center_section_agenda)
}

/**
 * Center: clases y citas reales desde Supabase (paridad con CenterView iOS).
 * Nunca inventa horarios ni plazas. Reservas/cancelaciones van por RPC
 * server-side con bono compatible. En ancho expandido (≥ 620 dp, mismo corte
 * que iOS) centros e invitaciones quedan a la izquierda y reservas/agenda a
 * la derecha.
 */
@Composable
internal fun CenterTab(
    connected: Boolean,
    loading: Boolean,
    submitting: Boolean,
    errorMessage: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    onRefresh: () -> Unit,
    onAccept: (BusinessCenterStore.Invitation) -> Unit,
    onDecline: (BusinessCenterStore.Invitation) -> Unit = {},
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onCancel: (BusinessCenterStore.Booking) -> Unit,
    sharingByCenter: Map<String, Boolean> = emptyMap(),
    sharingUpdating: Boolean = false,
    onSetSharing: (String, Boolean) -> Unit = { _, _ -> },
    directory:List<BusinessCenterStore.Organization> = emptyList(),
    directorySearching:Boolean = false,
    onSearchDirectory:(String)->Unit = {},
    onRequestLink:(BusinessCenterStore.Organization,String,String?)->Unit = {_,_,_->},
    onLeave:(BusinessCenterStore.Organization)->Unit = {},
    accountId:String = "",
    onBack: (() -> Unit)? = null,
    focusInvitationId: String? = null,
    onInvitationHandled: () -> Unit = {},
    onLoadInvitationPreview: suspend (String) -> BusinessCenterStore.InvitationPreviewResult =
        { BusinessCenterStore.InvitationPreviewResult.Unavailable }
) {
    if (onBack != null) BackHandler(onBack = onBack)
    var showDirectory by rememberSaveable(accountId) {mutableStateOf(false)}
    var detail by remember {mutableStateOf<BusinessCenterStore.Organization?>(null)}
    var section by rememberSaveable { mutableStateOf(CenterSection.CLASSES) }
    var pendingCancellation by remember {
        mutableStateOf<BusinessCenterStore.Booking?>(null)
    }
    val now = remember { Instant.now() }
    val zone = remember { ZoneId.systemDefault() }
    val dayFmt = remember {
        DateTimeFormatter.ofPattern("d MMM, HH:mm", Locale("es")).withZone(zone)
    }
    val hasLinkedCenters = connected && snapshot?.athleteCenterIds.orEmpty().isNotEmpty()
    val showOpenAccess = snapshot?.centers.orEmpty().any { snapshot?.openAccessEnabled(it.id) == true }
    val sections = CenterSection.entries.filter { it != CenterSection.OPEN_ACCESS || showOpenAccess }
    val activeSection = if (section in sections) section else CenterSection.CLASSES

    val header: LazyListScope.() -> Unit = {
        // R6 P1-16 / P0-2: iOS «Buscar» con Volver, campo y tarjeta vacía.
        item(key = "header") {
            if (onBack != null) {
                ReperaToolbarGlassIconButton(
                    icon = Icons.AutoMirrored.Outlined.ArrowBack,
                    contentDescription = stringResource(R.string.action_back),
                    onClick = onBack,
                    modifier = Modifier.testTag("center_back")
                )
            }
            ReperaPageHeader(title = stringResource(R.string.center_search_title),
                modifier = Modifier.semantics { heading() })
        }
        item(key = "search") {
            var query by remember(accountId) { mutableStateOf("") }
            ReperaSearchField(
                value = query,
                onValueChange = {
                    query = it
                    if (connected) onSearchDirectory(it)
                },
                placeholder = stringResource(R.string.center_search_placeholder),
                modifier = Modifier.testTag("center_search_field")
            )
            if (query.isNotBlank()) {
                TextButton(
                    onClick = { showDirectory = true },
                    modifier = Modifier.padding(top = 4.dp)
                ) { Text(stringResource(R.string.center_search_results)) }
            }
        }
    }
    val centersPane: LazyListScope.() -> Unit = {
        centerMembershipItems(connected, loading, submitting, errorMessage, snapshot,
            sharingByCenter, sharingUpdating, onSetSharing, onAccept, onDecline) { detail = it }
    }
    val bookingsPane: LazyListScope.() -> Unit = {
        if (hasLinkedCenters && snapshot != null) {
            item(key = "bookings_title") {
                ReperaSectionTitle(stringResource(R.string.center_bookings_title),
                    modifier = Modifier.semantics { heading() })
            }
            item(key = "bookings_picker") {
                val labels = sections.map { stringResource(it.label) }
                ReperaTopicSegmentedPicker(
                    options = labels,
                    selected = labels[sections.indexOf(activeSection).coerceAtLeast(0)],
                    onSelected = { label -> section = sections[labels.indexOf(label).coerceAtLeast(0)] },
                    modifier = Modifier.fillMaxWidth(),
                    optionTestTag = { i, _ -> "center_section_$i" }
                )
            }
            if (activeSection == CenterSection.AGENDA) {
                centerAgendaItems(snapshot, now, zone, submitting) { pendingCancellation = it }
            } else {
                centerOccurrenceItems(snapshot, activeSection, now, dayFmt, submitting, onBook) {
                    pendingCancellation = it
                }
            }
        }
    }

    BoxWithConstraints(Modifier.fillMaxSize()) {
        val twoPane = hasLinkedCenters && adaptiveCardColumns(maxWidth.value) == 2
        if (twoPane) {
            Row(Modifier.fillMaxSize().testTag("center_two_pane"),
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                LazyColumn(
                    modifier = Modifier.weight(0.42f).fillMaxHeight(),
                    contentPadding = reperaScrollContentPadding(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) { header(); centersPane() }
                LazyColumn(
                    modifier = Modifier.weight(0.58f).fillMaxHeight(),
                    contentPadding = reperaScrollContentPadding(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) { bookingsPane() }
            }
        } else {
            ReadableColumn {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = reperaScrollContentPadding(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) { header(); centersPane(); bookingsPane() }
            }
        }
    }

    val cancelling = pendingCancellation
    if (cancelling != null) {
        AlertDialog(
            onDismissRequest = { pendingCancellation = null },
            title = { Text(stringResource(R.string.center_cancel_title)) },
            text = {
                val occurrence = snapshot?.occurrences?.firstOrNull {
                    it.id == cancelling.occurrenceId
                }
                Text(dev.repera.domain.CenterCancellationPolicy.notice(
                    occurrence?.startsAt, now))
            },
            confirmButton = {
                TextButton(onClick = {
                    pendingCancellation = null
                    onCancel(cancelling)
                }) { Text(stringResource(R.string.center_cancel_confirm),
                    color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { pendingCancellation = null }) {
                    Text(stringResource(R.string.action_back))
                }
            }
        )
    }
    if(showDirectory) CenterDirectoryDialog(connected,directory,directorySearching,submitting,
        snapshot?.athleteCenterIds.orEmpty(),onSearchDirectory,onRequestLink,{showDirectory=false},errorMessage,accountId)
    detail?.let {center -> LinkedCenterDialog(center,snapshot,submitting,onLeave,{detail=null},
        sharingByCenter[center.id]==true,sharingUpdating,{onSetSharing(center.id,it)},errorMessage)}
    if (focusInvitationId != null) {
        InvitationDeepLinkSheet(
            invitationId = focusInvitationId,
            connected = connected,
            submitting = submitting,
            errorMessage = errorMessage,
            snapshot = snapshot,
            loadPreview = onLoadInvitationPreview,
            onRefresh = onRefresh,
            onAccept = onAccept,
            onDecline = onDecline,
            onDismiss = onInvitationHandled
        )
    }
}

private fun LazyListScope.centerMembershipItems(
    connected: Boolean,
    loading: Boolean,
    submitting: Boolean,
    errorMessage: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    sharingByCenter: Map<String, Boolean>,
    sharingUpdating: Boolean,
    onSetSharing: (String, Boolean) -> Unit,
    onAccept: (BusinessCenterStore.Invitation) -> Unit,
    onDecline: (BusinessCenterStore.Invitation) -> Unit,
    onOpenDetail: (BusinessCenterStore.Organization) -> Unit
) {
    if (!connected) {
        item(key = "empty_disconnected") {
            ReperaEmptyState(
                title = stringResource(R.string.center_empty_title),
                subtitle = stringResource(R.string.center_empty_subtitle),
                icon = Icons.Outlined.Search
            )
        }
        return
    }
    if (loading) {
        item(key = "loading") {
            Column(modifier = Modifier.fillMaxWidth().padding(8.dp)
                .semantics { liveRegion = LiveRegionMode.Polite },
                horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator()
                Text(stringResource(R.string.center_syncing))
            }
        }
    }
    errorMessage?.let { msg ->
        item(key = "error") {
            Text(msg, color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
        }
    }
    val linkedIds = snapshot?.athleteCenterIds.orEmpty()
    val centers = snapshot?.centers.orEmpty().filter { it.id in linkedIds }
    val invitations = snapshot?.invitations.orEmpty()
    if (centers.isEmpty() && invitations.isEmpty() && !loading) {
        item(key = "empty_connected") {
            ReperaEmptyState(
                title = stringResource(R.string.center_empty_title),
                subtitle = stringResource(R.string.center_empty_subtitle),
                icon = Icons.Outlined.Search
            )
        }
    }
    if (centers.isNotEmpty() || invitations.isNotEmpty()) {
        item(key = "centers_title") {
            ReperaSectionTitle(stringResource(R.string.center_my_centers),
                modifier = Modifier.semantics { heading() })
        }
    }
    items(invitations, key = { "inv_" + it.id }) { invitation ->
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.Outlined.MarkEmailUnread, contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
                    Text(stringResource(R.string.center_invitation_title),
                        style = MaterialTheme.typography.titleSmall)
                }
                Text(stringResource(R.string.center_invitation_body),
                    style = MaterialTheme.typography.bodySmall)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(onClick = { onAccept(invitation) },
                        enabled = !submitting) { Text(stringResource(R.string.center_invitation_accept)) }
                    TextButton(onClick = { onDecline(invitation) },
                        enabled = !submitting) { Text(stringResource(R.string.center_invitation_decline)) }
                }
            }
        }
    }
    items(centers, key = { "center_" + it.id }) { center ->
        val wallets = snapshot?.activePasses(center.id).orEmpty()
        ReperaCard(onClick = { onOpenDetail(center) }, modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(center.name, style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface)
                if (wallets.isEmpty()) {
                    Text(stringResource(R.string.center_no_active_pass),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else {
                    wallets.forEach { pass ->
                        Text(
                            stringResource(R.string.center_pass_credits,
                                pass.remainingCredits, pass.totalCredits, pass.kind),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
    // Privacidad (paridad iOS BusinessCenterViews): consentimiento
    // independiente y revocable por centro, OFF por defecto.
    if (centers.isNotEmpty()) {
        item(key = "privacy_title") {
            ReperaSectionTitle(stringResource(R.string.center_privacy),
                modifier = Modifier.semantics { heading() })
        }
        items(centers, key = { "share_" + it.id }) { center ->
            val title = stringResource(R.string.center_share_results)
            val body = stringResource(R.string.center_share_results_body,
                center.name.ifBlank { stringResource(R.string.center_share_results_fallback) })
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Row(modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(title, style = MaterialTheme.typography.titleSmall)
                        Text(body, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Switch(
                        checked = sharingByCenter[center.id] == true,
                        onCheckedChange = { onSetSharing(center.id, it) },
                        enabled = !sharingUpdating,
                        colors = reperaSwitchColors(),
                        modifier = Modifier.semantics { contentDescription = "$title. $body" })
                }
            }
        }
    }
}

private fun LazyListScope.centerOccurrenceItems(
    snapshot: BusinessCenterStore.Snapshot,
    section: CenterSection,
    now: Instant,
    dayFmt: DateTimeFormatter,
    submitting: Boolean,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit
) {
    val available = snapshot.occurrences.filter {
        it.kind == section.kind &&
            (runCatching { Instant.parse(it.startsAt) }.getOrNull() ?: Instant.EPOCH) > now
    }
    if (available.isEmpty()) {
        item(key = "occ_empty_" + section.name) {
            ReperaEmptyState(
                title = stringResource(when (section) {
                    CenterSection.OPEN_ACCESS -> R.string.center_empty_open_access
                    CenterSection.APPOINTMENTS -> R.string.center_empty_appointments
                    else -> R.string.center_empty_classes
                }),
                subtitle = stringResource(R.string.center_empty_schedule_body),
                icon = Icons.Outlined.EventBusy
            )
        }
        return
    }
    items(available, key = { "occ_" + it.id }) { occurrence ->
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(occurrence.title, style = MaterialTheme.typography.titleSmall)
                Text(snapshot.centerName(occurrence.orgId),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (snapshot.useRooms(occurrence.orgId)) {
                    snapshot.roomName(occurrence)?.let {
                        Text(stringResource(R.string.center_room, it),
                            style = MaterialTheme.typography.bodySmall)
                    }
                }
                if (occurrence.kind == "open_access") {
                    Text(stringResource(R.string.center_open_access_limited),
                        style = MaterialTheme.typography.bodySmall)
                } else if (occurrence.prescription != null ||
                    !occurrence.trainingTitle.isNullOrBlank()) {
                    Text(stringResource(R.string.center_training_published),
                        color = MaterialTheme.colorScheme.primary,
                        style = MaterialTheme.typography.bodySmall)
                }
                runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()
                    ?.let { Text(dayFmt.format(it), style = MaterialTheme.typography.bodySmall) }
                val booking = snapshot.bookingFor(occurrence.id)
                val places = snapshot.remainingPlaces(occurrence)
                when {
                    booking != null -> {
                        Text(
                            stringResource(if (booking.status == "waitlist")
                                R.string.center_waitlist_status else R.string.center_booked_status),
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.bodySmall)
                        TextButton(onClick = { onRequestCancel(booking) }, enabled = !submitting) {
                            Text(stringResource(R.string.center_cancel_booking),
                                color = MaterialTheme.colorScheme.error)
                        }
                        val hours = snapshot.operationSettingsByOrg[occurrence.orgId]
                            ?.cancelCreditHours ?: 12
                        Text(
                            if (booking.status == "waitlist")
                                stringResource(R.string.center_waitlist_no_charge)
                            else stringResource(R.string.center_cancel_refund_hint, hours),
                            style = MaterialTheme.typography.bodySmall)
                    }
                    places == 0 -> {
                        Text(stringResource(R.string.center_full), style = MaterialTheme.typography.bodySmall)
                        Text(stringResource(R.string.center_full_body),
                            style = MaterialTheme.typography.bodySmall)
                        snapshot.availablePasses(occurrence).firstOrNull()?.let { pass ->
                            TextButton(onClick = { onBook(occurrence, pass) }, enabled = !submitting) {
                                Text(stringResource(R.string.center_join_waitlist))
                            }
                        }
                    }
                    places != null -> {
                        Text(if (occurrence.kind == "appointment")
                                stringResource(R.string.center_slot_available)
                            else pluralStringResource(R.plurals.center_places_available, places, places),
                            style = MaterialTheme.typography.bodySmall)
                        val wallets = snapshot.availablePasses(occurrence)
                        if (wallets.isEmpty()) {
                            Text(stringResource(R.string.center_needs_pass),
                                style = MaterialTheme.typography.bodySmall)
                        } else {
                            wallets.forEach { pass ->
                                OutlinedButton(onClick = { onBook(occurrence, pass) }, enabled = !submitting) {
                                    Text(pluralStringResource(R.plurals.center_book_with_credits,
                                        pass.remainingCredits, pass.remainingCredits))
                                }
                            }
                        }
                    }
                    else -> Text(stringResource(R.string.center_capacity_unsynced),
                        style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

private sealed interface AgendaEntry {
    val at: LocalDateTime
    val key: String
    data class Booked(override val at: LocalDateTime, val booking: BusinessCenterStore.Booking,
        val occurrence: BusinessCenterStore.Occurrence) : AgendaEntry {
        override val key get() = "agenda_b_" + booking.id
    }
    data class Prescribed(override val at: LocalDateTime,
        val session: BusinessCenterStore.ProfessionalSession) : AgendaEntry {
        override val key get() = "agenda_s_" + session.id
    }
}

/** iOS CenterView.agendaSection: reservas confirmadas + entrenos prescritos desde hoy, en orden cronológico. */
private fun agendaEntries(snapshot: BusinessCenterStore.Snapshot, now: Instant, zone: ZoneId): List<AgendaEntry> {
    val today = LocalDate.now(zone)
    val booked = snapshot.bookings.filter { it.status == "booked" }.mapNotNull { booking ->
        val occurrence = snapshot.occurrences.firstOrNull { it.id == booking.occurrenceId }
            ?: return@mapNotNull null
        val start = runCatching { Instant.parse(occurrence.startsAt) }.getOrNull() ?: return@mapNotNull null
        val end = occurrence.endsAt?.let { runCatching { Instant.parse(it) }.getOrNull() } ?: start
        if (end < now) null else AgendaEntry.Booked(LocalDateTime.ofInstant(start, zone), booking, occurrence)
    }
    val prescribed = snapshot.trainingSessions.mapNotNull { session ->
        val day = runCatching { LocalDate.parse(session.scheduledDate) }.getOrNull() ?: return@mapNotNull null
        if (day < today) return@mapNotNull null
        val minutes = session.scheduledTimeMinutes?.coerceIn(0, 24 * 60 - 1)
        AgendaEntry.Prescribed(minutes?.let { day.atStartOfDay().plusMinutes(it.toLong()) }
            ?: day.atStartOfDay(), session)
    }
    return (booked + prescribed).sortedBy { it.at }
}

private fun LazyListScope.centerAgendaItems(
    snapshot: BusinessCenterStore.Snapshot,
    now: Instant,
    zone: ZoneId,
    submitting: Boolean,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit
) {
    val entries = agendaEntries(snapshot, now, zone)
    if (entries.isEmpty()) {
        item(key = "agenda_empty") {
            ReperaEmptyState(title = stringResource(R.string.center_agenda_empty),
                icon = Icons.Outlined.EventBusy, modifier = Modifier.testTag("center_agenda_empty"))
        }
        return
    }
    val today = LocalDate.now(zone)
    entries.groupBy { it.at.toLocalDate() }.forEach { (day, dayEntries) ->
        item(key = "agenda_day_$day") {
            val label = when (day) {
                today -> stringResource(R.string.center_agenda_today)
                today.plusDays(1) -> stringResource(R.string.center_agenda_tomorrow)
                else -> remember(day) {
                    DateTimeFormatter.ofPattern("EEEE, d MMM", Locale("es")).format(day)
                        .replaceFirstChar { it.titlecase(Locale("es")) }
                }
            }
            ReperaSectionTitle(label, modifier = Modifier.semantics { heading() })
        }
        items(dayEntries, key = { it.key }) { entry ->
            when (entry) {
                is AgendaEntry.Booked -> AgendaBookingCard(entry, snapshot, submitting, onRequestCancel)
                is AgendaEntry.Prescribed -> Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    ProfessionalSessionCard(entry.session, snapshot.centerName(entry.session.orgId), compact = true)
                    val minutes = entry.session.scheduledTimeMinutes
                    Text(
                        if (minutes == null) stringResource(R.string.center_agenda_no_time)
                        else stringResource(R.string.center_agenda_prescribed_at,
                            entry.at.toLocalTime().format(DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT))),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun AgendaBookingCard(
    entry: AgendaEntry.Booked,
    snapshot: BusinessCenterStore.Snapshot,
    submitting: Boolean,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit
) {
    val occurrence = entry.occurrence
    ReperaCard(modifier = Modifier.fillMaxWidth().testTag("center_agenda_booking")) {
        Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                entry.at.toLocalTime().format(DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(occurrence.title, style = MaterialTheme.typography.titleSmall)
                Text(snapshot.centerName(occurrence.orgId), style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (snapshot.useRooms(occurrence.orgId)) {
                    snapshot.roomName(occurrence)?.let {
                        Text(stringResource(R.string.center_room, it), style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Text(
                    stringResource(when (occurrence.kind) {
                        "class" -> R.string.center_agenda_class_booked
                        "open_access" -> R.string.center_agenda_open_access_booked
                        else -> R.string.center_agenda_appointment_booked
                    }),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                TextButton(onClick = { onRequestCancel(entry.booking) }, enabled = !submitting) {
                    Text(stringResource(R.string.center_cancel_booking), color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}

private sealed interface InvitationLoadState {
    data object Loading : InvitationLoadState
    data class Loaded(val result: BusinessCenterStore.InvitationPreviewResult) : InvitationLoadState
}

/** iOS RootTabView.InvitationDeepLinkSheet: aceptar/rechazar la invitación de `repera://invitation/{id}`. */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
private fun InvitationDeepLinkSheet(
    invitationId: String,
    connected: Boolean,
    submitting: Boolean,
    errorMessage: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    loadPreview: suspend (String) -> BusinessCenterStore.InvitationPreviewResult,
    onRefresh: () -> Unit,
    onAccept: (BusinessCenterStore.Invitation) -> Unit,
    onDecline: (BusinessCenterStore.Invitation) -> Unit,
    onDismiss: () -> Unit
) {
    var retry by remember(invitationId) { mutableIntStateOf(0) }
    var state by remember(invitationId) { mutableStateOf<InvitationLoadState>(InvitationLoadState.Loading) }
    var sentAction by remember(invitationId) { mutableStateOf<Int?>(null) }
    LaunchedEffect(invitationId, connected, retry) {
        if (!connected) return@LaunchedEffect
        state = InvitationLoadState.Loading
        onRefresh()
        state = InvitationLoadState.Loaded(loadPreview(invitationId))
    }
    LaunchedEffect(sentAction, submitting, errorMessage) {
        if (sentAction != null && !submitting && errorMessage == null) onDismiss()
    }
    ReperaModalBottomSheet(onDismissRequest = onDismiss,
        modifier = Modifier.testTag("invitation_sheet")) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(stringResource(R.string.invitation_sheet_title),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.semantics { heading() })
            val current = state
            when {
                !connected -> InvitationMessage(Icons.Outlined.MarkEmailUnread,
                    null, stringResource(R.string.invitation_signed_out))
                current is InvitationLoadState.Loading -> Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.semantics(mergeDescendants = true) {
                        liveRegion = LiveRegionMode.Polite
                    }
                ) {
                    CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
                    Text(stringResource(R.string.invitation_loading),
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                current is InvitationLoadState.Loaded -> when (val result = current.result) {
                    is BusinessCenterStore.InvitationPreviewResult.Found -> {
                        val preview = result.preview
                        val invitation = snapshot?.invitations?.firstOrNull {
                            it.id.equals(preview.invitationId, ignoreCase = true)
                        } ?: BusinessCenterStore.Invitation(preview.invitationId, preview.organizationId,
                            "client", preview.expiresAt, null, null)
                        InvitationFound(preview, submitting, errorMessage,
                            onAccept = { sentAction = 1; onAccept(invitation) },
                            onDecline = { sentAction = 2; onDecline(invitation) })
                    }
                    BusinessCenterStore.InvitationPreviewResult.Unavailable -> InvitationMessage(
                        Icons.Outlined.EventBusy, stringResource(R.string.invitation_unavailable_title),
                        stringResource(R.string.invitation_unavailable_body))
                    BusinessCenterStore.InvitationPreviewResult.Offline -> {
                        InvitationMessage(Icons.Outlined.CloudOff, stringResource(R.string.invitation_offline_title),
                            stringResource(R.string.invitation_offline_body))
                        OutlinedButton(onClick = { retry++ }) { Text(stringResource(R.string.action_retry)) }
                    }
                    BusinessCenterStore.InvitationPreviewResult.Failed -> {
                        InvitationMessage(Icons.Outlined.ErrorOutline, stringResource(R.string.invitation_failed_title),
                            stringResource(R.string.invitation_failed_body))
                        OutlinedButton(onClick = { retry++ }) { Text(stringResource(R.string.action_retry)) }
                    }
                }
            }
            TextButton(onClick = onDismiss, modifier = Modifier.align(Alignment.End)) {
                Text(stringResource(R.string.action_close))
            }
        }
    }
}

@Composable
private fun InvitationFound(
    preview: BusinessCenterStore.InvitationPreview,
    submitting: Boolean,
    errorMessage: String?,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    Text(preview.organizationName.ifBlank { stringResource(R.string.invitation_org_fallback) },
        style = MaterialTheme.typography.headlineSmall, maxLines = 3, overflow = TextOverflow.Ellipsis)
    Text(stringResource(when (preview.organizationKind) {
        "personal_trainer" -> R.string.org_kind_trainer
        "gym" -> R.string.org_kind_gym
        "sports_center" -> R.string.org_kind_sports_center
        else -> R.string.org_kind_other
    }), color = MaterialTheme.colorScheme.onSurfaceVariant)
    preview.organizationTagline?.let {
        Text(it, style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 4, overflow = TextOverflow.Ellipsis)
    }
    preview.expiresAt?.let { raw -> runCatching { Instant.parse(raw) }.getOrNull() }?.let { expires ->
        Text(stringResource(R.string.invitation_expires,
            DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale("es"))
                .withZone(ZoneId.systemDefault()).format(expires)),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    Text(stringResource(R.string.invitation_accept_body), style = MaterialTheme.typography.bodyMedium)
    errorMessage?.let {
        Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
    }
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Button(onClick = onAccept, enabled = !submitting, colors = reperaPrimaryButtonColors(),
            modifier = Modifier.testTag("invitation_accept")) {
            if (submitting) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                color = MaterialTheme.colorScheme.onPrimary)
            else Text(stringResource(R.string.center_invitation_accept))
        }
        TextButton(onClick = onDecline, enabled = !submitting,
            modifier = Modifier.testTag("invitation_decline")) {
            Text(stringResource(R.string.center_invitation_decline), color = MaterialTheme.colorScheme.error)
        }
    }
}

@Composable
private fun InvitationMessage(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String?, body: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite }) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp))
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            title?.let { Text(it, style = MaterialTheme.typography.titleMedium) }
            Text(body, style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
