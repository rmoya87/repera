package dev.repera.mobile

import androidx.compose.ui.res.stringResource
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
internal fun CenterMessagesScreen(
    connected: Boolean,
    loading: Boolean,
    submitting: Boolean,
    error: String?,
    snapshot: BusinessCenterStore.Snapshot?,
    thread: List<BusinessCenterStore.ChatMessage>,
    selectedOrgId: String?,
    onSelectOrg: (String) -> Unit,
    onRefresh: () -> Unit,
    onSendChat: (String, String) -> Unit,
) {
    var draft by androidx.compose.runtime.saveable.rememberSaveable { mutableStateOf("") }
    val linked = snapshot?.centers.orEmpty().filter { it.id in snapshot?.athleteCenterIds.orEmpty() }
    val orgId = selectedOrgId ?: linked.firstOrNull()?.id
    val clientId = orgId?.let { snapshot?.clientIdFor(it) }

    Column(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.weight(1f).fillMaxWidth(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item { ReperaPageHeader(title = stringResource(R.string.home_tab_mensajes)) }
            if (!connected || linked.isEmpty()) {
                item {
                    Text(
                        if (linked.isEmpty())
                            "Vincúlate a un centro o entrenador en Ajustes para chatear."
                        else "Conecta tu cuenta para ver mensajes."
                    )
                }
            } else {
                if (linked.size > 1) {
                    item {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            linked.forEach { org ->
                                ReperaFilterChip(
                                    selected = orgId == org.id,
                                    enabled = !submitting,
                                    onClick = { onSelectOrg(org.id) },
                                    label = { Text(org.name) }
                                )
                            }
                        }
                    }
                }
                item {
                    OutlinedButton(onClick = onRefresh, enabled = !loading) { Text(stringResource(R.string.action_refresh)) }
                }
                error?.let { item { Text(it, color = MaterialTheme.colorScheme.error) } }
                if (thread.isEmpty()) {
                    item { Text(stringResource(R.string.center_messages_screen_todavia_no_hay_mensajes_escribe_el)) }
                }
                items(thread, key = { it.id }) { message ->
                    val mine = message.senderRole != "staff"
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start
                    ) {
                        Column(
                            Modifier
                                .widthIn(max = 280.dp)
                                .background(
                                    if (mine) MaterialTheme.colorScheme.primary
                                    else MaterialTheme.colorScheme.surfaceVariant,
                                    RoundedCornerShape(16.dp)
                                )
                                .padding(horizontal = 12.dp, vertical = 8.dp)
                        ) {
                            Text(
                                message.body,
                                color = if (mine) MaterialTheme.colorScheme.onPrimary
                                else MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                buildString {
                                    if (message.batchId != null) append("Aviso · ")
                                    append(noticeTime(message.createdAt))
                                },
                                style = MaterialTheme.typography.labelSmall,
                                color = if (mine) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                                else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
        if (connected && linked.isNotEmpty() && orgId != null && clientId != null) {
            Row(
                Modifier.fillMaxWidth()
                    .navigationBarsPadding()
                    .imePadding()
                    .padding(12.dp),
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text(stringResource(R.string.center_messages_screen_mensaje)) },
                    enabled = !submitting,
                    maxLines = 4
                )
                Button(
                    enabled = !submitting && draft.trim().isNotEmpty(),
                    onClick = {
                        val body = draft.trim()
                        draft = ""
                        onSendChat(orgId, body)
                    }
                ) { Text(if (submitting) "…" else "Enviar") }
            }
        }
    }
}

private fun noticeTime(raw: String): String = runCatching {
    java.time.Instant.parse(raw).atZone(java.time.ZoneId.systemDefault()).format(
        java.time.format.DateTimeFormatter.ofPattern("d MMM, HH:mm", java.util.Locale("es"))
    )
}.getOrElse { raw }
