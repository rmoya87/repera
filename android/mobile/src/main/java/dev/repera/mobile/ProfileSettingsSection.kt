package dev.repera.mobile

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

@Composable internal fun SettingsListRow(
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
    trailingColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
    showChevron: Boolean = true,
    enabled: Boolean = true,
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val clickable = onClick != null && enabled
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (clickable) Modifier.clickable(onClick = onClick!!)
                else Modifier
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        leadingIcon?.let {
            Icon(
                it,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(22.dp)
            )
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                color = if (enabled) MaterialTheme.colorScheme.onSurface
                else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
            )
            subtitle?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        trailing?.let {
            Text(
                it,
                style = MaterialTheme.typography.bodyMedium,
                color = trailingColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        trailingIcon?.let {
            Icon(
                it,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(22.dp)
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

@Composable internal fun SettingsTextActionRow(
    text: String,
    enabled: Boolean = true,
    destructive: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    TextButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text,
            modifier = Modifier.fillMaxWidth(),
            style = MaterialTheme.typography.bodyLarge,
            color = when {
                !enabled -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                destructive -> MaterialTheme.colorScheme.error
                else -> MaterialTheme.colorScheme.primary
            }
        )
    }
}

@Composable internal fun SettingsCardDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(horizontal = 16.dp),
        color = MaterialTheme.colorScheme.outlineVariant
    )
}

@Composable internal fun ProfileSettingsSection(
    value: ProfileSettings,
    busy: Boolean,
    onChange: (ProfileSettings) -> Unit,
    onRequestSignOut: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val sessionStore = remember(context) { SessionStore(context) }
    val googleName = remember(sessionStore) {
        sessionStore.load()?.displayName?.trim()?.takeIf { it.isNotEmpty() }
    }
    var name by remember(value.displayName, googleName) {
        mutableStateOf(value.displayName?.takeIf { it.isNotBlank() } ?: googleName.orEmpty())
    }
    var error by remember { mutableStateOf<String?>(null) }
    val latestValue by rememberUpdatedState(value)
    val latestOnChange by rememberUpdatedState(onChange)
    var pickerRevision by remember { mutableStateOf<String?>(null) }
    var pickerPending by remember { mutableStateOf(false) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        val expected = pickerRevision
        val valid = pickerPending && sessionStore.identityRevision() == expected
        pickerPending = false
        pickerRevision = null
        if (uri != null && valid) {
            runCatching {
                val bytes = ProfilePhotoCodec.jpeg(context.contentResolver, uri)
                check(sessionStore.identityRevision() == expected) { "La cuenta cambió al leer la foto" }
                latestOnChange(
                    latestValue.copy(
                        avatarJPEG = android.util.Base64.encodeToString(
                            bytes,
                            android.util.Base64.NO_WRAP
                        )
                    )
                )
                error = null
            }.onFailure { error = "No se pudo leer la foto. Prueba otra imagen." }
        }
    }
    val avatar = remember(value.avatarJPEG) {
        runCatching {
            value.avatarJPEG?.let { android.util.Base64.decode(it, android.util.Base64.DEFAULT) }
                ?.let { android.graphics.BitmapFactory.decodeByteArray(it, 0, it.size) }
        }.getOrNull()
    }
    fun persistName() {
        latestOnChange(latestValue.copy(displayName = name.trim().takeIf { it.isNotEmpty() }))
    }
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier.clickable(enabled = !busy && !pickerPending) {
                pickerRevision = sessionStore.identityRevision()
                pickerPending = true
                picker.launch("image/*")
            }
        ) {
            if (avatar != null) {
                Image(
                    avatar.asImageBitmap(),
                    "Foto de perfil",
                    Modifier.size(52.dp).clip(CircleShape)
                )
            } else {
                Surface(
                    modifier = Modifier.size(52.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {}
            }
            Surface(
                modifier = Modifier.align(Alignment.BottomEnd).size(20.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surface,
                border = BorderStroke(2.dp, MaterialTheme.colorScheme.background)
            ) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        "G",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            BasicTextField(
                value = name,
                onValueChange = { name = it },
                enabled = !busy,
                singleLine = true,
                textStyle = MaterialTheme.typography.titleMedium.copy(
                    color = MaterialTheme.colorScheme.onSurface
                ),
                cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { persistName() }),
                modifier = Modifier.fillMaxWidth(),
                decorationBox = { inner ->
                    Box {
                        if (name.isEmpty()) {
                            Text(
                                "Tu nombre",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        inner()
                    }
                }
            )
            sessionStore.load()?.email?.takeIf { it.isNotBlank() }?.let { email ->
                Text(
                    email,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            if (onRequestSignOut != null) {
                TextButton(
                    onClick = onRequestSignOut,
                    enabled = !busy,
                    contentPadding = PaddingValues(0.dp)
                ) {
                    Text("Cerrar sesión", color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
    error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
}
