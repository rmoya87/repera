package dev.repera.mobile

import androidx.compose.foundation.layout.heightIn
import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
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
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

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
    /** Materializa la prescripción y abre preview/Play (id de rutina). */
    onStartClassPlan: (BusinessCenterStore.ProfessionalSession) -> Unit = {},
    /** Clase/cita sin bloques: Comenzar como gimnasio o HIIT según el título. */
    onStartClassWithoutPlan: (title: String) -> Unit = {},
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    onOpenExercise: (String) -> Unit = {},
) {
    var hubTab by remember { mutableStateOf(0) } // 0 clases, 1 centro
    var selectedDay by remember { mutableStateOf(LocalDate.now()) }
    var detailOccurrence by remember {
        mutableStateOf<BusinessCenterStore.Occurrence?>(null)
    }
    var paymentsCenterId by remember { mutableStateOf<String?>(null) }
    var historyCenterId by remember { mutableStateOf<String?>(null) }
    var pendingCancellation by remember {
        mutableStateOf<BusinessCenterStore.Booking?>(null)
    }
    val zone = remember { ZoneId.systemDefault() }
    val es = remember { Locale("es", "ES") }
    val dayFmt = remember {
        DateTimeFormatter.ofPattern("H:mm", es).withZone(zone)
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
                        Text(stringResource(R.string.plus_hub_tab_conecta_tu_cuenta), style = MaterialTheme.typography.titleSmall)
                        Text(
                            stringResource(R.string.plus_hub_tab_inicia_sesion_para_ver_clases_del),
                            style = MaterialTheme.typography.bodySmall
                        )
                        TextButton(onClick = onRefresh) { Text(stringResource(R.string.action_retry)) }
                    }
                }
            }
            hubTab == 0 -> ClassesPane(
                loading = loading,
                errorMessage = errorMessage,
                snapshot = snapshot,
                selectedDay = selectedDay,
                onSelectDay = { selectedDay = it },
                dayFmt = dayFmt,
                zone = zone,
                submitting = submitting,
                onBook = onBook,
                onRequestCancel = { pendingCancellation = it },
                onOpenDetail = { detailOccurrence = it },
                loadRoster = loadRoster
            )
            else -> CenterPane(
                snapshot = snapshot,
                dayFmt = dayFmt,
                onOpenDetail = { detailOccurrence = it },
                onOpenPayments = { paymentsCenterId = it },
                onOpenClassHistory = { historyCenterId = it }
            )
        }
    }

    paymentsCenterId?.let { centerId ->
        CenterPaymentsFullPage(
            snapshot = snapshot,
            centerId = centerId,
            onClose = { paymentsCenterId = null }
        )
    }
    historyCenterId?.let { centerId ->
        CenterClassHistoryFullPage(
            snapshot = snapshot,
            centerId = centerId,
            dayFmt = dayFmt,
            onClose = { historyCenterId = null }
        )
    }

    detailOccurrence?.let { occurrence ->
        ClassDetailPage(
            occurrence = occurrence,
            snapshot = snapshot,
            dayFmt = dayFmt,
            submitting = submitting,
            loadRoster = loadRoster,
            onBook = onBook,
            onRequestCancel = { pendingCancellation = it },
            onStartClassPlan = onStartClassPlan,
            onStartClassWithoutPlan = onStartClassWithoutPlan,
            exerciseCatalog = exerciseCatalog,
            onOpenExercise = onOpenExercise,
            onClose = { detailOccurrence = null }
        )
    }

    pendingCancellation?.let { booking ->
        ReperaConfirmSheet(
            title = stringResource(R.string.center_cancel_title),
            message = stringResource(R.string.plus_hub_tab_se_te_desapunta_y_si_tenias),
            confirmTitle = stringResource(R.string.center_cancel_confirm),
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
    dayFmt: DateTimeFormatter,
    zone: ZoneId,
    submitting: Boolean,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
    loadRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)?,
) {
    val classDays = remember(snapshot) {
        (snapshot?.occurrences.orEmpty())
            .filter { it.kind == "class" && it.status == "active" }
            .mapNotNull { occurrence ->
                runCatching { Instant.parse(occurrence.startsAt).atZone(zone).toLocalDate() }.getOrNull()
            }
            .toSet()
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
            WeekCalendarStrip(
                selected = selectedDay,
                monday = true,
                completedDays = classDays,
                returnToDay = LocalDate.now(),
                dotDescription = "Clase programada",
                onSelect = onSelectDay
            )
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
                        Text(stringResource(R.string.plus_hub_tab_sin_clases_este_dia), style = MaterialTheme.typography.titleSmall)
                        Text(
                            stringResource(R.string.plus_hub_tab_cuando_tu_gimnasio_publique_horarios_apareceran),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }
        items(dayClasses, key = { it.id }) { occurrence ->
            val availability = snapshot?.availability?.get(occurrence.id)
            val booking = snapshot?.bookingFor(occurrence.id)
            ClassDayCard(
                occurrence = occurrence,
                centerName = snapshot?.centerName(occurrence.orgId).orEmpty(),
                booking = booking,
                places = snapshot?.remainingPlaces(occurrence),
                capacity = availability?.capacity ?: occurrence.capacity,
                reserved = availability?.reserved,
                passes = snapshot?.availablePasses(occurrence).orEmpty(),
                canBook = snapshot?.canBookNow(occurrence) == true,
                opensAt = snapshot?.bookingOpensAt(occurrence),
                dayFmt = dayFmt,
                submitting = submitting,
                onBook = onBook,
                onRequestCancel = onRequestCancel,
                onOpenDetail = onOpenDetail,
                loadRoster = loadRoster
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
    capacity: Int?,
    reserved: Int?,
    passes: List<BusinessCenterStore.Pass>,
    canBook: Boolean,
    opensAt: Instant?,
    dayFmt: DateTimeFormatter,
    submitting: Boolean,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
    loadRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)?,
) {
    // Mismo RPC de ocupación que en el detalle, solo cuando falta el agregado.
    var rosterCount by remember(occurrence.id, booking?.id, booking?.status) {
        mutableStateOf<Pair<Int, Int?>?>(null)
    }
    LaunchedEffect(occurrence.id, booking?.id, booking?.status, reserved) {
        if (reserved == null) {
            val result = loadRoster?.invoke(occurrence.id)
            // La tarjeta solo necesita las cifras: no conservar el roster personal.
            rosterCount = result?.reserved?.let { occupied -> occupied to result.capacity }
        }
    }
    val actualCapacity = if (reserved == null) rosterCount?.second ?: capacity else capacity
    val actualReserved = reserved ?: rosterCount?.first
    val actualRemaining = places ?: if (actualCapacity != null && actualReserved != null) {
        (actualCapacity - actualReserved).coerceAtLeast(0)
    } else null
    val accent = parseClassColor(occurrence.color)
    val full = (actualRemaining ?: 1) == 0
    val canTap = canBook && !full && passes.isNotEmpty()
    val aforo = aforoLabel(capacity = actualCapacity, remaining = actualRemaining, reserved = actualReserved)
    ReperaCard(Modifier.fillMaxWidth()) {
        Row(
            Modifier
                .fillMaxWidth()
                .height(IntrinsicSize.Min)
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
                    if (aforo != null) {
                        Text(
                            aforo,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
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
                            Text(stringResource(R.string.action_cancel), color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.SemiBold)
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
                    if (opensAt != null) {
                        Text(
                            "Inscripción desde ${dayFmt.format(opensAt)}",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
internal fun ClassDetailPage(
    occurrence: BusinessCenterStore.Occurrence,
    snapshot: BusinessCenterStore.Snapshot?,
    dayFmt: DateTimeFormatter,
    submitting: Boolean,
    loadRoster: (suspend (String) -> BusinessCenterStore.ClassRoster?)?,
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onRequestCancel: (BusinessCenterStore.Booking) -> Unit,
    onStartClassPlan: (BusinessCenterStore.ProfessionalSession) -> Unit = {},
    onStartClassWithoutPlan: (title: String) -> Unit = {},
    exerciseCatalog: List<ExerciseEntry> = emptyList(),
    onOpenExercise: (String) -> Unit = {},
    onClose: () -> Unit,
) {
    var roster by remember { mutableStateOf<BusinessCenterStore.ClassRoster?>(null) }
    var loadingRoster by remember { mutableStateOf(true) }
    val booking = snapshot?.bookingFor(occurrence.id)
    val places = snapshot?.remainingPlaces(occurrence)
    val open = snapshot?.canBookNow(occurrence) == true
    val full = (places ?: 1) == 0
    val passes = snapshot?.availablePasses(occurrence).orEmpty()
    val start = runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()
    val end = occurrence.endsAt?.let { runCatching { Instant.parse(it) }.getOrNull() }
    val canTap = open && !full && passes.isNotEmpty()
    val associatedSession = remember(snapshot, occurrence.id, booking?.clientId, occurrence.prescription) {
        snapshot?.asClassPlanSession(occurrence, booking?.clientId)
    }
    val planInfos = remember(associatedSession?.prescription) {
        associatedSession?.prescription
            ?.takeIf { BusinessCenterStore.isCanonicalPrescription(it) }
            ?.let { prescriptionToRoutineBlocks(it) }
            .orEmpty()
    }
    val hasPlan = planInfos.isNotEmpty() && associatedSession != null
    val shortDateFmt = remember {
        DateTimeFormatter.ofPattern("d MMM yyyy", Locale("es", "ES")).withZone(ZoneId.systemDefault())
    }
    val subtitle = if (start != null) {
        "${shortDateFmt.format(start)} · ${dayFmt.format(start)}"
    } else {
        ""
    }

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
                TextButton(onClick = onClose) { Text(stringResource(R.string.action_close)) }
                Spacer(Modifier.weight(1f))
                // Play siempre: con plan → preview; sin bloques → Comenzar gym/HIIT.
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .padding(end = 8.dp)
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary)
                        .clickable(role = androidx.compose.ui.semantics.Role.Button) {
                            if (hasPlan && associatedSession != null) {
                                onStartClassPlan(associatedSession)
                            } else {
                                val training = occurrence.trainingTitle?.trim().orEmpty()
                                val title = training.ifEmpty { occurrence.title }
                                onStartClassWithoutPlan(title)
                            }
                        }
                ) {
                    Icon(
                        imageVector = Icons.Filled.PlayArrow,
                        contentDescription = stringResource(R.string.plus_start_class_plan),
                        tint = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }
            Column(
                Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .padding(bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        occurrence.title,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    if (subtitle.isNotBlank()) {
                        Text(
                            subtitle,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                ReperaCard(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        if (booking != null) {
                            Text(
                                if (booking.status == "waitlist") "Lista de espera" else "Apuntado",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = if (booking.status == "waitlist") {
                                    MaterialTheme.colorScheme.onSurfaceVariant
                                } else {
                                    MaterialTheme.colorScheme.primary
                                }
                            )
                        }
                        if (start != null) {
                            DetailRow("Fecha", shortDateFmt.format(start), singleLine = true)
                            DetailRow(
                                "Hora",
                                buildString {
                                    append(dayFmt.format(start))
                                    if (end != null) {
                                        append(" – ")
                                        append(dayFmt.format(end))
                                    }
                                }
                            )
                            if (end != null) DetailRow("Duración", durationLabel(start, end))
                        }
                        val reserved = roster?.reserved ?: places?.let { (occurrence.capacity ?: 0) - it }
                        val capacity = roster?.capacity ?: occurrence.capacity
                        if (reserved != null && capacity != null) {
                            DetailRow("Plazas", "$reserved / $capacity")
                        }
                        occurrence.location?.takeIf { it.isNotBlank() }?.let {
                            DetailRow("Sala", it)
                        }
                    }
                }

                // Bloques como entreno programado (RoutinePlanBreakdown); solo si hay ejercicios.
                if (hasPlan) {
                    associatedSession?.instructions?.takeIf { it.isNotBlank() }?.let { notes ->
                        Text(
                            notes,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    RoutinePlanBreakdown(
                        blocks = planInfos,
                        exerciseCatalog = exerciseCatalog,
                        onOpenExercise = onOpenExercise
                    )
                }

                if (!loadingRoster && roster?.coach != null) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            stringResource(R.string.org_kind_trainer),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        ReperaCard(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                PersonRow(
                                    name = roster!!.coach!!.displayName,
                                    avatarUrl = roster!!.coach!!.avatarUrl,
                                    subtitle = stringResource(R.string.plus_hub_tab_impartira_la_clase)
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
                            Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            when {
                                loadingRoster -> CircularProgressIndicator(Modifier.size(24.dp))
                                roster?.attendees.isNullOrEmpty() -> Text(
                                    stringResource(R.string.plus_hub_tab_todavia_no_hay_nadie_apuntado_se),
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
            Box(
                Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Button(
                    onClick = {
                        if (booking != null) {
                            onRequestCancel(booking)
                        } else {
                            val pass = passes.firstOrNull() ?: return@Button
                            onBook(occurrence, pass)
                        }
                    },
                    enabled = !submitting && (booking != null || canTap),
                    modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (booking != null) MaterialTheme.colorScheme.error
                            else MaterialTheme.colorScheme.primary,
                        contentColor = if (booking != null) MaterialTheme.colorScheme.onError
                            else MaterialTheme.colorScheme.onPrimary,
                        disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Text(
                        if (booking != null) "Cancelar clase" else "Apuntarme",
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

/** Prescripción canónica → bloques del preview de entreno programado. */
internal fun prescriptionToRoutineBlocks(prescription: JSONObject): List<RoutineBlockInfo> {
    val blocks = prescription.optJSONArray("blocks") ?: return emptyList()
    return (0 until blocks.length()).mapNotNull { i ->
        val b = blocks.optJSONObject(i) ?: return@mapNotNull null
        val wod = b.optString("kind") == "wod"
        val raw = b.optJSONArray(if (wod) "movements" else "exercises") ?: JSONArray()
        val entries = (0 until raw.length()).mapNotNull { j ->
            val e = raw.optJSONObject(j) ?: return@mapNotNull null
            val sets = e.optJSONArray("plannedSets")
            val setCount = sets?.length()?.takeIf { it > 0 } ?: 1
            val quantity = when {
                sets != null && sets.length() > 0 -> sets.getJSONObject(0).optInt("targetReps", 0)
                e.has("reps") && !e.isNull("reps") -> e.optInt("reps")
                else -> 0
            }
            val catalogKey = e.optString("catalogKey").removePrefix("catalog:")
            RoutineBlockEntryInfo(
                exerciseId = catalogKey,
                name = e.optString("name").ifBlank { "Ejercicio" },
                quantity = quantity,
                sets = setCount,
                weightKg = sets?.optJSONObject(0)?.takeIf {
                    it.has("targetWeightKg") && !it.isNull("targetWeightKg")
                }?.optDouble("targetWeightKg"),
                id = e.optString("id").ifBlank { null }
            )
        }
        if (entries.isEmpty()) return@mapNotNull null
        RoutineBlockInfo(
            title = b.optString("title").ifBlank {
                if (wod) "WOD" else "Fuerza"
            },
            format = if (wod) b.optString("wodFormat", "emom") else "",
            timeCapMinutes = b.optInt("timeCapMinutes", 12).takeIf { it > 0 } ?: 12,
            rounds = b.optInt("rounds", 1).coerceAtLeast(1),
            entries = entries,
            id = b.optString("id").ifBlank { null }
        )
    }
}

@Composable
private fun DetailRow(title: String, value: String, singleLine: Boolean = false) {
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
            modifier = Modifier.padding(start = 12.dp),
            maxLines = if (singleLine) 1 else Int.MAX_VALUE,
            softWrap = !singleLine
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
    val avatarUrl = center?.avatarUrl
    val remote by produceState<android.graphics.Bitmap?>(null, avatarUrl) {
        val url = avatarUrl?.takeIf { it.startsWith("https://") }
        if (url.isNullOrBlank()) {
            value = null
            return@produceState
        }
        value = withContext(Dispatchers.IO) {
            runCatching {
                java.net.URL(url).openStream().use { android.graphics.BitmapFactory.decodeStream(it) }
            }.getOrNull()
        }
    }
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
        if (remote != null) {
            Image(
                bitmap = remote!!.asImageBitmap(),
                contentDescription = name,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
        } else {
            Text(
                initials,
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = (size.value * 0.32f).sp
            )
        }
    }
}

@Composable
private fun CenterPane(
    snapshot: BusinessCenterStore.Snapshot?,
    dayFmt: DateTimeFormatter,
    onOpenDetail: (BusinessCenterStore.Occurrence) -> Unit,
    onOpenPayments: (String) -> Unit,
    onOpenClassHistory: (String) -> Unit,
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
                        stringResource(R.string.plus_hub_tab_todavia_no_perteneces_a_ningun_centro),
                        modifier = Modifier.padding(16.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
        centers.forEach { center ->
            val upcoming = upcomingBookings(snapshot, center.id)
            item(key = "hero-${center.id}") {
                CenterHeroCard(center = center)
            }
            item(key = "plan-title-${center.id}") {
                Text(
                    stringResource(R.string.plus_hub_tab_plan),
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
                            Text(stringResource(R.string.plus_hub_tab_sin_plan_activo), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                            Text(
                                stringResource(R.string.plus_hub_tab_pide_a_tu_centro_que_te),
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
                        stringResource(R.string.plus_hub_tab_proximas_reservas),
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
                PaymentsCard(
                    snapshot = snapshot,
                    centerId = center.id,
                    onOpenAll = { onOpenPayments(center.id) }
                )
            }
            item(key = "history-${center.id}") {
                ClassHistoryCard(
                    snapshot = snapshot,
                    centerId = center.id,
                    dayFmt = dayFmt,
                    onOpenAll = { onOpenClassHistory(center.id) }
                )
            }
        }
    }
}

@Composable
private fun PaymentsCard(
    snapshot: BusinessCenterStore.Snapshot?,
    centerId: String,
    onOpenAll: () -> Unit,
) {
    val all = snapshot?.paymentHistory(centerId).orEmpty()
    val payments = all.take(3)
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            stringResource(R.string.plus_hub_tab_ultimos_pagos),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp)
        )
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (payments.isEmpty()) {
                    Text(
                        stringResource(R.string.plus_hub_tab_todavia_no_hay_pagos_registrados_con),
                        style = MaterialTheme.typography.bodySmall
                    )
                } else {
                    payments.forEach { pass ->
                        PaymentRow(snapshot = snapshot, pass = pass)
                    }
                    if (all.size > 3) {
                        Text(
                            stringResource(R.string.plus_hub_tab_ver_mas),
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clickable(onClick = onOpenAll)
                        )
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
    onOpenAll: () -> Unit,
) {
    val all = snapshot?.pastBookings(centerId).orEmpty()
    val history = all.take(3)
    val occById = snapshot?.occurrences.orEmpty().associateBy { it.id }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            stringResource(R.string.plus_hub_tab_historial_de_clases),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp)
        )
        ReperaCard(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (history.isEmpty()) {
                    Text(
                        stringResource(R.string.plus_hub_tab_aun_no_has_asistido_ni_reservado),
                        style = MaterialTheme.typography.bodySmall
                    )
                } else {
                    history.forEach { booking ->
                        ClassHistoryRow(
                            booking = booking,
                            occurrence = occById[booking.occurrenceId],
                            dayFmt = dayFmt
                        )
                    }
                    if (all.size > 3) {
                        Text(
                            stringResource(R.string.plus_hub_tab_ver_mas),
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clickable(onClick = onOpenAll)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PaymentRow(snapshot: BusinessCenterStore.Snapshot?, pass: BusinessCenterStore.Pass) {
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

@Composable
private fun ClassHistoryRow(
    booking: BusinessCenterStore.Booking,
    occurrence: BusinessCenterStore.Occurrence?,
    dayFmt: DateTimeFormatter,
) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Column(Modifier.weight(1f)) {
            Text(occurrence?.title ?: "Clase", fontWeight = FontWeight.SemiBold)
            occurrence?.startsAt?.let { raw ->
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

@Composable
private fun CenterHeroCard(center: BusinessCenterStore.Organization) {
    val email = center.publicEmail?.trim().orEmpty()
    val phone = center.phone?.trim().orEmpty()
    val context = androidx.compose.ui.platform.LocalContext.current
    ReperaCard(Modifier.fillMaxWidth()) {
        Row(
            Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            CenterAvatar(center = center, size = 64.dp)
            Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.weight(1f)) {
                Text(center.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                center.tagline?.takeIf { it.isNotBlank() }?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall)
                }
                if (email.isNotBlank()) {
                    Text(
                        email,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                val intent = android.content.Intent(
                                    android.content.Intent.ACTION_SENDTO,
                                    android.net.Uri.parse("mailto:${android.net.Uri.encode(email)}")
                                )
                                runCatching { context.startActivity(intent) }
                            }
                    )
                }
                if (phone.isNotBlank()) {
                    val digits = phone.filter { it.isDigit() || it == '+' }
                    Text(
                        phone,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(enabled = digits.isNotBlank()) {
                                val intent = android.content.Intent(
                                    android.content.Intent.ACTION_DIAL,
                                    android.net.Uri.parse("tel:$digits")
                                )
                                runCatching { context.startActivity(intent) }
                            }
                    )
                }
            }
        }
    }
}

@Composable
private fun CenterPaymentsFullPage(
    snapshot: BusinessCenterStore.Snapshot?,
    centerId: String,
    onClose: () -> Unit,
) {
    val payments = snapshot?.paymentHistory(centerId).orEmpty()
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
                Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = onClose) { Text(stringResource(R.string.action_close)) }
                Text(
                    stringResource(R.string.plus_hub_tab_pagos),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                if (payments.isEmpty()) {
                    item {
                        Text(
                            stringResource(R.string.plus_hub_tab_todavia_no_hay_pagos_registrados_con),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                } else {
                    items(payments, key = { it.id }) { pass ->
                        ReperaCard(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                PaymentRow(snapshot = snapshot, pass = pass)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CenterClassHistoryFullPage(
    snapshot: BusinessCenterStore.Snapshot?,
    centerId: String,
    dayFmt: DateTimeFormatter,
    onClose: () -> Unit,
) {
    val history = snapshot?.pastBookings(centerId).orEmpty()
    val occById = snapshot?.occurrences.orEmpty().associateBy { it.id }
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
                Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = onClose) { Text(stringResource(R.string.action_close)) }
                Text(
                    stringResource(R.string.plus_hub_tab_historial_de_clases),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                if (history.isEmpty()) {
                    item {
                        Text(
                            stringResource(R.string.plus_hub_tab_aun_no_has_asistido_ni_reservado),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                } else {
                    items(history, key = { it.id }) { booking ->
                        ReperaCard(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                ClassHistoryRow(
                                    booking = booking,
                                    occurrence = occById[booking.occurrenceId],
                                    dayFmt = dayFmt
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
                    stringResource(R.string.plus_hub_tab_acceso_ilimitado),
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
        val occ = snapshot?.occurrences?.firstOrNull { it.id == booking.occurrenceId } ?: return@mapNotNull null
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

/** Aforo siempre visible (también si ya estás apuntado): ocupadas/capacidad. */
internal fun aforoLabel(capacity: Int?, remaining: Int?, reserved: Int?): String? {
    val cap = capacity?.takeIf { it > 0 } ?: return null
    val used = reserved ?: remaining?.let { (cap - it).coerceAtLeast(0) }
    return if (used != null) "$used/$cap" else "—/$cap"
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
