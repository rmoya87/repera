package dev.repera.mobile

import android.content.ClipData
import android.content.ClipboardManager

import dev.repera.mobile.analytics.ReperaAnalytics
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Pantalla "Acceso IA" (port de AIAccessView.swift): alta/listado/revocación
 * de tokens personales, decisiones sobre cambios solicitados por la IA y
 * estado de los entrenos enviados por la IA. Stateless: el estado y la red
 * viven en MainActivity (AIAccessStore + AIChangeRequestStore + inbox).
 */

internal val aiExpiryOptions = listOf(
    "7d" to "7 días", "30d" to "30 días", "90d" to "90 días",
    "365d" to "1 año", "unlimited" to "Ilimitado")

// Apple lastUseLabel: "Último uso: <fecha abreviada, hora corta>"
internal fun aiLastUseLabel(token: AIAccessStore.TokenInfo): String? {
    val raw = token.lastUsedAt ?: return null
    val date = runCatching { java.time.Instant.parse(raw) }.getOrNull()
        ?: runCatching {
            java.time.OffsetDateTime.parse(raw).toInstant() }.getOrNull()
        ?: return null
    val fmt = java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm",
        java.util.Locale.forLanguageTag("es-ES"))
    return "Último uso: " + fmt.format(
        date.atZone(java.time.ZoneId.systemDefault()))
}

internal fun aiExpiryLabel(token: AIAccessStore.TokenInfo): String {
    if (token.revokedAt != null) return "Revocado"
    val raw = token.expiresAt ?: return "Sin caducidad"
    val instant = AIAccessStore.parseInstant(raw) ?: return "Caducidad: " +
        raw.take(10)
    val day = instant.atZone(ZoneId.systemDefault()).toLocalDate()
    return "Caduca el " + day.format(
        DateTimeFormatter.ofPattern("d MMM yyyy", Locale.forLanguageTag("es-ES")))
}

private fun copyAiPromptToClipboard(context: android.content.Context, text: String) {
    val clipboard = context.getSystemService(ClipboardManager::class.java) ?: return
    clipboard.setPrimaryClip(ClipData.newPlainText("repera-ai", text))
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AIAccessScreen(
    connected: Boolean,
    busy: Boolean,
    tokens: List<AIAccessStore.TokenInfo>?,
    errorMessage: String?,
    successMessage: String?,
    createdToken: String?,
    changes: List<AIChangeRequestStore.Change>,
    changeBusy: Boolean,
    changeError: String?,
    inboxPending: Int,
    inboxConflicts: List<String>,
    onRefresh: () -> Unit,
    onCreate: (String, String, Boolean) -> Unit,
    onRevoke: (String) -> Unit,
    onDelete: (AIAccessStore.TokenInfo) -> Unit,
    onDecide: (AIChangeRequestStore.Change, Boolean) -> Unit,
    onDismissCreated: () -> Unit,
    onCopyCreated: () -> Unit,
    onBack: (() -> Unit)? = null
) {
    if (onBack != null) BackHandler(onBack = onBack)
    var tokenName by remember { mutableStateOf("") }
    var expiry by remember { mutableStateOf("90d") }
    var canWrite by remember { mutableStateOf(false) }
    var expiryMenu by remember { mutableStateOf(false) }
    var showManual by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize()
        .verticalScroll(rememberScrollState())
        .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)) {

        // Conexiones guiadas (port de connectionSection AIAccessView iOS):
        // catálogo público + fallback, logo de marca, verificado inline.
        var providers by remember {
            mutableStateOf<Pair<List<AIAccessStore.AIProvider>, Boolean>?>(null) }
        LaunchedEffect(Unit) {
            providers = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                AIProviderLaunch.fetchProviderCatalog() }
        }
        var instructionsFor by remember {
            mutableStateOf<AIAccessStore.AIProvider?>(null) }
        var disconnectingProvider by remember {
            mutableStateOf<AIAccessStore.AIProvider?>(null) }
        var verifiedTokenIds by remember { mutableStateOf(emptySet<String>()) }
        LaunchedEffect(tokens) {
            val connectedIds = tokens.orEmpty()
                .filter { it.hasConnected }
                .map { it.id }
                .toSet()
            val newly = connectedIds - verifiedTokenIds
            if (newly.isNotEmpty()) {
                ReperaAnalytics.track(
                    ReperaAnalytics.Event.AI_CONNECTION_VERIFIED,
                    mapOf("feature_area" to "ai", "result" to "success")
                )
            }
            verifiedTokenIds = connectedIds
        }
        // R6 P0-2: Volver + título large + tarjeta «Elige tu asistente».
        if (onBack != null) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.ArrowBack,
                contentDescription = "Volver",
                onClick = onBack,
                enabled = !busy,
                modifier = Modifier.testTag("ai_access_back")
            )
        }
        ReperaPageHeader(title = "Conecta tu IA")
        if (providers?.second == true) {
            Text("No se pudo comprobar la disponibilidad de las conexiones.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        ReperaSectionTitle("Elige tu asistente")
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                val context = androidx.compose.ui.platform.LocalContext.current
                var launchHint by remember { mutableStateOf<String?>(null) }
                providers?.first?.forEach { provider ->
                    val verified = provider.oauthClientID != null && tokens.orEmpty().any {
                        it.oauthClientID == provider.oauthClientID && it.hasConnected
                    }
                    OutlinedButton(
                        onClick = {
                            if (verified) disconnectingProvider = provider
                            else {
                                ReperaAnalytics.track(
                                    ReperaAnalytics.Event.AI_CONNECTION_STARTED,
                                    mapOf(
                                        "feature_area" to "ai",
                                        "entry_point" to provider.id,
                                        "result" to "pending"
                                    )
                                )
                                val prompt = AIProviderLaunch.instructions(provider)
                                copyAiPromptToClipboard(context, prompt)
                                val opened = AIProviderLaunch.openProvider(
                                    context, provider.id, prompt
                                )
                                launchHint = if (opened) {
                                    "Abriendo ${provider.name} con las instrucciones en un chat nuevo (también copiadas)."
                                } else {
                                    instructionsFor = provider
                                    "No se pudo abrir ${provider.name}. Las instrucciones permanecen copiadas."
                                }
                            }
                        },
                        enabled = connected,
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(13.dp),
                        modifier = Modifier.fillMaxWidth().height(48.dp)
                    ) {
                        Icon(
                            androidx.compose.ui.res.painterResource(
                                when (provider.id) {
                                    "chatgpt" -> dev.repera.mobile.R.drawable.ai_logo_openai
                                    "claude" -> dev.repera.mobile.R.drawable.ai_logo_claude
                                    else -> dev.repera.mobile.R.drawable.ai_logo_grok
                                }
                            ),
                            contentDescription = null,
                            tint = if (provider.id == "claude")
                                androidx.compose.ui.graphics.Color.Unspecified
                            else androidx.compose.material3.LocalContentColor.current,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(Modifier.width(12.dp))
                        Text(
                            if (verified) "Desactivar ${provider.name}"
                            else "Continuar con ${provider.name}"
                        )
                    }
                }
                // Cuarto botón dentro de «Elige tu asistente».
                OutlinedButton(
                    onClick = { showManual = true },
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(13.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .testTag("ai_manual_connection")
                ) {
                    Icon(
                        Icons.Outlined.Key,
                        contentDescription = null,
                        modifier = Modifier.size(22.dp)
                    )
                    Spacer(Modifier.width(12.dp))
                    Text("Conexión manual")
                }
                if (!connected) {
                    Text(
                        "Inicia sesión en Repera para conectar tu asistente.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                launchHint?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        // Apple 0a640da8: confirmationDialog "Desconectar asistente".
        disconnectingProvider?.let { provider ->
            val token = tokens.orEmpty().firstOrNull {
                it.oauthClientID == provider.oauthClientID &&
                    provider.oauthClientID != null && it.hasConnected }
            DisconnectAssistantDialog(providerName = provider.name,
                onConfirm = {
                    disconnectingProvider = null
                    if (token != null) onRevoke(token.id)
                },
                onDismiss = { disconnectingProvider = null })
        }
        instructionsFor?.let { provider ->
            val text = AIProviderLaunch.instructions(provider)
            val context = androidx.compose.ui.platform.LocalContext.current
            AlertDialog(onDismissRequest = { instructionsFor = null },
                title = { Text(provider.name) },
                text = {
                    Column(Modifier.verticalScroll(rememberScrollState())) {
                        Text(text, style = MaterialTheme.typography.bodySmall)
                    }
                },
                confirmButton = {
                    TextButton(onClick = {
                        copyAiPromptToClipboard(context, text)
                        AIProviderLaunch.openProvider(context, provider.id, text)
                        instructionsFor = null
                    }) { Text("Copiar y abrir ${provider.name}") }
                },
                dismissButton = {
                    TextButton(onClick = { instructionsFor = null }) { Text("Cerrar") }
                })
        }

        // Sheet de conexión manual (abre el 4.º botón de «Elige tu asistente»).
        if (showManual) {
            val context = LocalContext.current
            val canCreate = !busy && connected && tokenName.trim().length >= 3
            ReperaModalBottomSheet(onDismissRequest = { showManual = false }) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 28.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        "Conexión manual",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    ReperaMetaTextField(
                        caption = "Nombre del acceso (ej. Mi entrenador IA)",
                        value = tokenName,
                        onValueChange = { tokenName = it }
                    )
                    ExposedDropdownMenuBox(expanded = expiryMenu,
                        onExpandedChange = { expiryMenu = it }) {
                        OutlinedTextField(
                            value = aiExpiryOptions.first { it.first == expiry }.second,
                            onValueChange = {}, readOnly = true,
                            label = { Text("Caducidad") },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expiryMenu) },
                            modifier = Modifier
                                .menuAnchor(
                                    type = ExposedDropdownMenuAnchorType.PrimaryNotEditable
                                )
                                .fillMaxWidth())
                        ExposedDropdownMenu(expanded = expiryMenu,
                            onDismissRequest = { expiryMenu = false }) {
                            aiExpiryOptions.forEach { (value, label) ->
                                DropdownMenuItem(text = { Text(label) }, onClick = {
                                    expiry = value; expiryMenu = false
                                })
                            }
                        }
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Permitir enviar y editar entrenamientos",
                                style = MaterialTheme.typography.bodyMedium)
                            Text(if (canWrite) "Lectura y escritura" else "Solo lectura",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = canWrite,
                            onCheckedChange = { canWrite = it },
                            colors = reperaSwitchColors()
                        )
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            AIProviderLaunch.PUBLIC_SERVER,
                            style = MaterialTheme.typography.titleMedium,
                            fontFamily = FontFamily.Monospace,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 2,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(
                            onClick = {
                                copyAiPromptToClipboard(
                                    context,
                                    AIProviderLaunch.PUBLIC_SERVER
                                )
                            }
                        ) {
                            Icon(
                                Icons.Outlined.ContentCopy,
                                contentDescription = "Copiar URL del servidor MCP",
                                modifier = Modifier.size(22.dp)
                            )
                        }
                    }
                    if (expiry == "unlimited") {
                        Text("Un token ilimitado seguirá funcionando hasta que lo " +
                            "revoques. Úsalo solo con asistentes de confianza.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Button(
                        onClick = {
                            onCreate(tokenName.trim(), expiry, canWrite)
                            tokenName = ""
                            showManual = false
                        },
                        enabled = canCreate,
                        modifier = Modifier.fillMaxWidth().testTag("ai_create_token"),
                        colors = ButtonDefaults.buttonColors(
                            disabledContainerColor = MaterialTheme.colorScheme
                                .surfaceVariant,
                            disabledContentColor = MaterialTheme.colorScheme
                                .onSurfaceVariant.copy(alpha = 0.55f)
                        )
                    ) { Text(if (busy) "Creando acceso…" else "Crear token") }
                }
            }
        }

        HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))
        Text("Mis conexiones", style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.testTag("ai_tokens_header"))
        when {
            tokens == null -> CircularProgressIndicator()
            tokens.isEmpty() -> Text("No tienes tokens de IA creados.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            else -> tokens.forEach { token ->
                val openProvider = if (token.hasConnected && token.oauthClientID != null)
                    providers?.first?.firstOrNull { it.name == token.label }
                else null
                ReperaSwipeDeleteRow(
                    canDelete = !busy,
                    onDelete = { onDelete(token) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    ReperaCard(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(token.label,
                                    style = MaterialTheme.typography.titleSmall,
                                    modifier = Modifier.weight(1f))
                                Text(if (token.isActive)
                                        (if (token.hasConnected) "Conectado"
                                         else "Pendiente de conexión")
                                     else "Desconectado",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Text(token.tokenPrefix + "…",
                                style = MaterialTheme.typography.bodySmall,
                                fontFamily = FontFamily.Monospace,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(if (token.canWrite) "Puede consultar y preparar entrenamientos"
                                else "Puede consultar tus entrenamientos",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            aiLastUseLabel(token)?.let {
                                Text(it, style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            if (token.oauthClientID == null) {
                                Text(aiExpiryLabel(token),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            if (token.isActive) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    TextButton(
                                        onClick = { onRevoke(token.id) },
                                        enabled = !busy
                                    ) {
                                        Text(
                                            "Desactivar",
                                            color = MaterialTheme.colorScheme.error
                                        )
                                    }
                                    Spacer(Modifier.weight(1f))
                                    if (openProvider != null &&
                                        openProvider.id in listOf("chatgpt", "claude", "grok")
                                    ) {
                                        val context =
                                            androidx.compose.ui.platform.LocalContext.current
                                        TextButton(
                                            onClick = {
                                                val prompt =
                                                    AIProviderLaunch.instructions(openProvider)
                                                copyAiPromptToClipboard(context, prompt)
                                                AIProviderLaunch.openProvider(
                                                    context, openProvider.id, prompt
                                                )
                                            },
                                            enabled = !busy
                                        ) { Text("Abrir " + openProvider.name) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (changes.isNotEmpty()) {
            HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))
            Text("Cambios solicitados por la IA",
                style = MaterialTheme.typography.titleMedium)
            changes.forEach { change ->
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(change.summary,
                            style = MaterialTheme.typography.titleSmall)
                        if (change.operation == "update_workout") {
                            val newTitle = change.payload.optString("title")
                            if (newTitle.isNotBlank()) {
                                Text("Nuevo título: $newTitle",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme
                                        .onSurfaceVariant)
                            }
                            change.payload.optJSONArray("setChanges")?.let { arr ->
                                for (i in 0 until arr.length()) {
                                    Text("Serie " + setChangeLabel(
                                        arr.getJSONObject(i)),
                                        style = MaterialTheme.typography
                                            .bodySmall,
                                        color = MaterialTheme.colorScheme
                                            .onSurfaceVariant)
                                }
                            }
                        }
                        if (change.operation == "delete_workout") {
                            // iOS advierte de la actividad vinculada en Apple
                            // Salud; en Android no se borra nada de Health
                            // Connect: el aviso honesto es la irreversibilidad.
                            Text("La eliminación de un entrenamiento no se " +
                                "puede deshacer.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.reperaColors.warning)
                        }
                        Row {
                            OutlinedButton(
                                onClick = { onDecide(change, false) },
                                enabled = !changeBusy
                            ) { Text("Rechazar") }
                            TextButton(
                                onClick = { onDecide(change, true) },
                                enabled = !changeBusy
                            ) {
                                Text(if (change.isDestructive)
                                    "Confirmar eliminación" else "Aplicar",
                                    color = if (change.isDestructive)
                                        MaterialTheme.colorScheme.error
                                        else brandGreen)
                            }
                        }
                    }
                }
            }
        }
        changeError?.let {
            Text(it, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.reperaColors.warning)
        }

        if (inboxPending > 0 || inboxConflicts.isNotEmpty()) {
            HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))
            Text("Entrenamientos enviados por la IA",
                style = MaterialTheme.typography.titleMedium)
            if (inboxPending > 0) {
                Text("$inboxPending entrenamientos pendientes",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            inboxConflicts.forEach { issue ->
                Text(issue, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.reperaColors.warning)
            }
        }

        errorMessage?.let {
            Text(it, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error)
        }
        successMessage?.let {
            Text(it, style = MaterialTheme.typography.bodySmall,
                color = brandGreen)
        }
        if (!connected) {
            Text("Inicia sesión con tu cuenta para gestionar el acceso IA.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        // R5 P2.8: iOS no muestra botón «Actualizar» suelto; refresco al abrir.
        LaunchedEffect(connected) {
            if (connected) onRefresh()
        }
    }

    if (createdToken != null) {
        Dialog(onDismissRequest = onDismissCreated) {
            Card {
                Column(modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Token creado",
                        style = MaterialTheme.typography.titleLarge,
                        color = brandGreen)
                    Text("Cópialo y guárdalo en tu asistente. Por seguridad " +
                        "no volverá a mostrarse.",
                        style = MaterialTheme.typography.bodyMedium)
                    SelectionContainer {
                        Text(createdToken,
                            style = MaterialTheme.typography.bodySmall,
                            fontFamily = FontFamily.Monospace)
                    }
                    Button(onClick = onCopyCreated,
                        modifier = Modifier.fillMaxWidth()) {
                        Text("Copiar token")
                    }
                    Text("Este token permite que quien lo conozca consulte " +
                        "tu historial deportivo y envíe entrenamientos. No " +
                        "lo publiques ni lo compartas en capturas.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    TextButton(onClick = onDismissCreated,
                        modifier = Modifier.align(Alignment.End)) {
                        Text("Cerrar")
                    }
                }
            }
        }
    }
}

private fun setChangeLabel(change: JSONObject): String {
    val parts = mutableListOf<String>()
    if (change.has("reps")) parts.add("${change.getInt("reps")} reps")
    if (change.has("weightKg")) parts.add("${dev.repera.domain.ReperaNumberFormat.decimal(change.getDouble("weightKg"))} kg")
    if (change.has("rir")) parts.add("RIR ${dev.repera.domain.ReperaNumberFormat.decimal(change.getDouble("rir"))}")
    if (change.optBoolean("clearWeight")) parts.add("sin peso")
    if (change.optBoolean("clearRir")) parts.add("sin RIR")
    return change.getString("loggedSetId").take(8) + ": " +
        parts.joinToString(" · ")
}

/** confirmationDialog «Desactivar asistente» (paridad iOS). */
@Composable
internal fun DisconnectAssistantDialog(providerName: String,
                                       onConfirm: () -> Unit,
                                       onDismiss: () -> Unit) {
    AlertDialog(onDismissRequest = onDismiss,
        title = { Text("Desactivar asistente") },
        text = { Text("Se revocará el acceso del asistente a tu cuenta de Repera.") },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Desactivar " + providerName,
                    color = MaterialTheme.colorScheme.error)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        })
}
