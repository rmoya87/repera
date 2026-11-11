package dev.repera.mobile

import android.content.ClipData
import android.content.ClipboardManager

import dev.repera.mobile.analytics.ReperaAnalytics
import androidx.activity.compose.BackHandler
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Close
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
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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

internal fun copyAiPromptToClipboard(context: android.content.Context, text: String) {
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
    createdSetupUrl: String? = null,
    changes: List<AIChangeRequestStore.Change>,
    changeBusy: Boolean,
    changeError: String?,
    inboxPending: Int,
    inboxConflicts: List<String>,
    onRefresh: () -> Unit,
    onCreate: (String, String, Boolean, Boolean) -> Unit,
    onContinueProvider: (AIAccessStore.AIProvider) -> Unit = {},
    onUpdate: (AIAccessStore.TokenInfo, String, Boolean, Boolean) -> Unit = { _, _, _, _ -> },
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
    var canDelete by remember { mutableStateOf(false) }
    var expiryMenu by remember { mutableStateOf(false) }
    var showManual by remember { mutableStateOf(false) }
    var editingToken by remember { mutableStateOf<AIAccessStore.TokenInfo?>(null) }
    var editLabel by remember { mutableStateOf("") }
    var editCanWrite by remember { mutableStateOf(false) }
    var editCanDelete by remember { mutableStateOf(false) }

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
        var lastInstructions by remember { mutableStateOf<String?>(null) }
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
                providers?.first?.forEach { provider ->
                    OutlinedButton(
                        onClick = {
                            ReperaAnalytics.track(
                                ReperaAnalytics.Event.AI_CONNECTION_STARTED,
                                mapOf(
                                    "feature_area" to "ai",
                                    "entry_point" to provider.id,
                                    "result" to "pending"
                                )
                            )
                            // Multi-cuenta: siempre Continuar (crea otra conexión).
                            onContinueProvider(provider)
                        },
                        enabled = connected && !busy,
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(13.dp),
                        modifier = Modifier.fillMaxWidth().height(48.dp)
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
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
                            Spacer(Modifier.width(10.dp))
                            Text("Continuar con ${provider.name}")
                        }
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
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            Icons.Outlined.Key,
                            contentDescription = null,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(Modifier.width(10.dp))
                        Text("Conexión manual")
                    }
                }
                if (!connected) {
                    Text(
                        "Inicia sesión en Repera para conectar tu asistente.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        instructionsFor?.let { provider ->
            val text = lastInstructions
                ?: AIProviderLaunch.reopenInstructions(provider)
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
        // skipPartiallyExpanded: alto = contenido (paridad ogFittedSheet iOS).
        if (showManual) {
            val context = LocalContext.current
            val canCreate = !busy && connected && tokenName.trim().length >= 3
            val manualSheetState = rememberModalBottomSheetState(
                skipPartiallyExpanded = true
            )
            ReperaModalBottomSheet(
                onDismissRequest = { showManual = false },
                sheetState = manualSheetState
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 28.dp)
                        .verticalScroll(rememberScrollState())
                        .testTag("ai_manual_sheet"),
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
                        Text("Lectura", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(checked = true, onCheckedChange = null,
                            enabled = false, colors = reperaSwitchColors())
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Editar", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(checked = canWrite, onCheckedChange = { canWrite = it },
                            colors = reperaSwitchColors())
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Borrar", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(checked = canDelete, onCheckedChange = { canDelete = it },
                            colors = reperaSwitchColors())
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
                            onCreate(tokenName.trim(), expiry, canWrite, canDelete)
                            tokenName = ""
                            canWrite = false
                            canDelete = false
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

        editingToken?.let { token ->
            val editSheetState = rememberModalBottomSheetState(
                skipPartiallyExpanded = true
            )
            ReperaModalBottomSheet(
                onDismissRequest = { editingToken = null },
                sheetState = editSheetState
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 16.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(
                        "Editar conexión",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    ReperaMetaTextField(
                        caption = "Nombre",
                        value = editLabel,
                        onValueChange = { editLabel = it }
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Lectura", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(checked = true, onCheckedChange = null,
                            enabled = false, colors = reperaSwitchColors())
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Editar", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(
                            checked = editCanWrite,
                            onCheckedChange = { editCanWrite = it },
                            colors = reperaSwitchColors()
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Borrar", modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium)
                        Switch(
                            checked = editCanDelete,
                            onCheckedChange = { editCanDelete = it },
                            colors = reperaSwitchColors()
                        )
                    }
                    Button(
                        onClick = {
                            onUpdate(token, editLabel.trim(), editCanWrite, editCanDelete)
                            editingToken = null
                        },
                        enabled = !busy && editLabel.trim().isNotEmpty(),
                        modifier = Modifier.fillMaxWidth()
                    ) { Text(if (busy) "Guardando…" else "Guardar") }
                    TextButton(
                        onClick = {
                            editingToken = null
                            onDelete(token)
                        },
                        enabled = !busy,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            "Borrar conexión",
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
        }

        Text(
            "Mis conexiones",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier
                .padding(top = 10.dp)
                .testTag("ai_tokens_header")
        )
        when {
            tokens == null -> CircularProgressIndicator()
            tokens.isEmpty() -> Text("No tienes tokens de IA creados.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            else -> ReperaCard(
                // animateContentSize: al quitar una fila el resto sube (paridad iOS Form).
                modifier = Modifier.fillMaxWidth().animateContentSize()
            ) {
                tokens.forEachIndexed { index, token ->
                    key(token.id) {
                        if (index > 0) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 14.dp)
                            )
                        }
                        ReperaSwipeDeleteRow(
                            canDelete = !busy,
                            onDelete = { onDelete(token) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp)
                            ) {
                                Column(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(end = 88.dp),
                                    verticalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Text(
                                        token.label,
                                        style = MaterialTheme.typography.titleSmall
                                    )
                                    // Orden iOS: permisos → último uso → caducidad (sin tokenPrefix).
                                    Text(
                                        token.permissionSummary,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    aiLastUseLabel(token)?.let {
                                        Text(
                                            it,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    if (token.oauthClientID == null) {
                                        Text(
                                            aiExpiryLabel(token),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                                Text(
                                    if (token.isActive)
                                        (if (token.hasConnected) "Conectado"
                                         else "Pendiente de conexión")
                                    else "Desconectado",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    textAlign = TextAlign.End,
                                    modifier = Modifier.align(Alignment.TopEnd)
                                )
                                if (token.isActive) {
                                    Text(
                                        "Editar",
                                        style = MaterialTheme.typography.bodyMedium.copy(
                                            fontWeight = FontWeight.SemiBold
                                        ),
                                        color = if (busy)
                                            MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                                        else MaterialTheme.colorScheme.primary,
                                        modifier = Modifier
                                            .align(Alignment.BottomEnd)
                                            .clickable(enabled = !busy) {
                                                editLabel = token.label
                                                editCanWrite = token.canWrite
                                                editCanDelete = token.canDelete
                                                editingToken = token
                                            }
                                    )
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
        val setupContext = LocalContext.current
        var remainingSec by remember(createdToken) { mutableStateOf(15 * 60) }
        LaunchedEffect(createdToken) {
            remainingSec = 15 * 60
            while (remainingSec > 0) {
                kotlinx.coroutines.delay(1_000)
                remainingSec -= 1
            }
        }
        // Misma sheet de abajo que Conexión manual / Editar (no Dialog centrado).
        val createdSheetState = rememberModalBottomSheetState(
            skipPartiallyExpanded = true
        )
        ReperaModalBottomSheet(
            onDismissRequest = onDismissCreated,
            sheetState = createdSheetState
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "Nuevo token",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = onDismissCreated) {
                        Icon(
                            Icons.Outlined.Close,
                            contentDescription = "Cerrar"
                        )
                    }
                }
                Text(
                    "%d:%02d".format(remainingSec / 60, remainingSec % 60),
                    style = MaterialTheme.typography.displaySmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
                Text("Enlace del MCP", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        AIProviderLaunch.PUBLIC_SERVER,
                        style = MaterialTheme.typography.titleSmall,
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(
                        onClick = {
                            copyAiPromptToClipboard(
                                setupContext,
                                AIProviderLaunch.PUBLIC_SERVER
                            )
                        }
                    ) {
                        Icon(
                            Icons.Outlined.ContentCopy,
                            contentDescription = "Copiar enlace del MCP"
                        )
                    }
                }
                SelectionContainer {
                    Text(
                        createdToken,
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace
                    )
                }
                Button(
                    onClick = onCopyCreated,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Copiar token")
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
