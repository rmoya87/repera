package dev.repera.mobile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Center: clases y citas reales desde Supabase (paridad con CenterView iOS).
 * Nunca inventa horarios ni plazas. Reservas/cancelaciones van por RPC
 * server-side con bono compatible.
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
    onBook: (BusinessCenterStore.Occurrence, BusinessCenterStore.Pass) -> Unit,
    onCancel: (BusinessCenterStore.Booking) -> Unit,
    sharingByCenter: Map<String, Boolean> = emptyMap(),
    sharingUpdating: Boolean = false,
    onSetSharing: (String, Boolean) -> Unit = { _, _ -> }
) {
    var section by remember { mutableStateOf("class") }
    var pendingCancellation by remember {
        mutableStateOf<BusinessCenterStore.Booking?>(null)
    }
    val now = remember { Instant.now() }
    val available = (snapshot?.occurrences ?: emptyList()).filter {
        it.kind == section &&
            (runCatching { Instant.parse(it.startsAt) }.getOrNull()
                ?: Instant.EPOCH) > now
    }
    val dayFmt = remember {
        DateTimeFormatter.ofPattern("d MMM, HH:mm", Locale("es"))
            .withZone(ZoneId.systemDefault())
    }
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Center", style = MaterialTheme.typography.headlineMedium) }
        item { Text("Mis centros y entrenadores",
            style = MaterialTheme.typography.titleMedium) }
        if (!connected) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("No se han podido cargar tus centros",
                            style = MaterialTheme.typography.titleSmall)
                        OutlinedButton(onClick = onRefresh) { Text("Reintentar") }
                    }
                }
            }
        } else {
            if (loading) {
                item {
                    Column(modifier = Modifier.fillMaxWidth().padding(8.dp),
                        horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator()
                        Text("Sincronizando centros…")
                    }
                }
            }
            errorMessage?.let { msg ->
                item { Text(msg, color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall) }
            }
            val centers = snapshot?.centers ?: emptyList()
            val invitations = snapshot?.invitations ?: emptyList()
            if (centers.isEmpty() && invitations.isEmpty() && !loading) {
                item {
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Text("Todavía no perteneces a ningún centro. Tu entrenador o " +
                            "gimnasio puede invitarte al correo de tu cuenta.",
                            modifier = Modifier.padding(16.dp),
                            style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
            items(invitations) { invitation ->
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Invitación a un centro",
                            style = MaterialTheme.typography.titleSmall)
                        Text("Perfil: ${invitation.invitedRole}. Aceptar la invitación " +
                            "vinculará tu cuenta, pero no compartirá tu historial " +
                            "deportivo personal.",
                            style = MaterialTheme.typography.bodySmall)
                        OutlinedButton(onClick = { onAccept(invitation) },
                            enabled = !submitting) { Text("Aceptar invitación") }
                    }
                }
            }
            items(centers) { center ->
                Card(modifier = Modifier.fillMaxWidth()) {
                    Text(center.name, modifier = Modifier.padding(16.dp),
                        style = MaterialTheme.typography.titleSmall)
                }
            }
            // Privacidad (paridad iOS BusinessCenterViews): consentimiento
            // independiente y revocable por centro, OFF por defecto.
            val linked = centers.filter {
                snapshot?.athleteCenterIds?.contains(it.id) == true
            }
            if (linked.isNotEmpty()) {
                item { Text("Privacidad",
                    style = MaterialTheme.typography.titleMedium) }
                items(linked) { center ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Row(modifier = Modifier.fillMaxWidth().padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Compartir resultados",
                                    style = MaterialTheme.typography.titleSmall)
                                Text("Series, repeticiones y marcas con " +
                                    (center.name.ifBlank { "el centro" }) +
                                    ". Puedes desactivarlo.",
                                    style = MaterialTheme.typography.bodySmall)
                            }
                            Switch(
                                checked = sharingByCenter[center.id] == true,
                                onCheckedChange = {
                                    onSetSharing(center.id, it) },
                                enabled = !sharingUpdating)
                        }
                    }
                }
            }
        }
        if(connected) items(snapshot?.trainingSessions.orEmpty()) {session ->
            ProfessionalSessionCard(session,snapshot?.centerName(session.orgId) ?: "Centro",false)
        }
        item { Text("Reservas", style = MaterialTheme.typography.titleMedium) }
        item {
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = section == "class",
                    onClick = { section = "class" },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2)
                ) { Text("Clases") }
                SegmentedButton(
                    selected = section == "appointment",
                    onClick = { section = "appointment" },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2)
                ) { Text("Citas") }
            }
        }
        if (available.isEmpty()) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(if (section == "class") "Sin clases disponibles"
                            else "Sin citas disponibles",
                            style = MaterialTheme.typography.titleSmall)
                        Text("Se mostrarán aquí los horarios reales que publique " +
                            "tu centro o entrenador.",
                            style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
        items(available) { occurrence ->
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(occurrence.title, style = MaterialTheme.typography.titleSmall)
                    Text(snapshot?.centerName(occurrence.orgId) ?: "",
                        style = MaterialTheme.typography.bodySmall)
                    runCatching { Instant.parse(occurrence.startsAt) }.getOrNull()
                        ?.let { Text(dayFmt.format(it),
                            style = MaterialTheme.typography.bodySmall) }
                    val booking = snapshot?.bookingFor(occurrence.id)
                    val places = snapshot?.remainingPlaces(occurrence)
                    when {
                        booking != null -> {
                            Text("Reservado · Aparece también en Inicio",
                                color = MaterialTheme.colorScheme.primary,
                                style = MaterialTheme.typography.bodySmall)
                            TextButton(onClick = { pendingCancellation = booking },
                                enabled = !submitting) {
                                Text("Cancelar reserva",
                                    color = MaterialTheme.colorScheme.error)
                            }
                            Text("Política provisional: cancelaciones con más de " +
                                "12 horas de antelación recuperan el crédito.",
                                style = MaterialTheme.typography.bodySmall)
                        }
                        places == 0 -> {
                            Text("Completo", style = MaterialTheme.typography.bodySmall)
                            Text("No quedan plazas. La lista de espera aún no está habilitada.",
                                style = MaterialTheme.typography.bodySmall)
                        }
                        places != null -> {
                            Text(if (occurrence.kind == "appointment") "Horario disponible"
                                else "$places plaza${if (places == 1) "" else "s"} " +
                                    "disponible${if (places == 1) "" else "s"}",
                                style = MaterialTheme.typography.bodySmall)
                            val wallets = snapshot.availablePasses(occurrence)
                            if (wallets.isEmpty()) {
                                Text("Necesitas un bono vigente de este servicio para reservar.",
                                    style = MaterialTheme.typography.bodySmall)
                            } else {
                                wallets.forEach { pass ->
                                    OutlinedButton(
                                        onClick = { onBook(occurrence, pass) },
                                        enabled = !submitting) {
                                        Text("Reservar · ${pass.remainingCredits} " +
                                            "sesiones disponibles")
                                    }
                                }
                            }
                        }
                        else -> Text("El aforo no está sincronizado. Actualiza Center " +
                            "antes de reservar.", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
    val cancelling = pendingCancellation
    if (cancelling != null) {
        AlertDialog(
            onDismissRequest = { pendingCancellation = null },
            title = { Text("¿Cancelar la reserva?") },
            text = { Text("Política provisional: cancelaciones con más de 12 horas " +
                "de antelación recuperan el crédito.") },
            confirmButton = {
                TextButton(onClick = {
                    pendingCancellation = null
                    onCancel(cancelling)
                }) { Text("Confirmar cancelación",
                    color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { pendingCancellation = null }) { Text("Volver") }
            }
        )
    }
}
