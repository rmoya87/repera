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
import androidx.compose.material.icons.outlined.CloudOff
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable internal fun SettingsListRow(
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
    trailingColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
    showChevron: Boolean = true,
    titleBold: Boolean = false,
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
                fontWeight = if (titleBold) androidx.compose.ui.text.font.FontWeight.SemiBold
                else androidx.compose.ui.text.font.FontWeight.Normal,
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
    onRequestSignOut: (() -> Unit)? = null,
    /** Editar nombre/foto exige estado local; cerrar sesión solo mira [busy]. */
    profileEditable: Boolean = !busy,
) {
    val context = LocalContext.current
    val sessionStore = remember(context) { SessionStore(context) }
    val googleName = remember(sessionStore) {
        sessionStore.load()?.displayName?.trim()?.takeIf { it.isNotEmpty() }
    }
    val googlePhotoUrl = remember(sessionStore) { sessionStore.googlePhotoUrl() }
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
    val localAvatar = remember(value.avatarJPEG) {
        runCatching {
            value.avatarJPEG?.let { android.util.Base64.decode(it, android.util.Base64.DEFAULT) }
                ?.let { android.graphics.BitmapFactory.decodeByteArray(it, 0, it.size) }
        }.getOrNull()
    }
    val googleAvatar by produceState<android.graphics.Bitmap?>(
        initialValue = null,
        key1 = googlePhotoUrl
    ) {
        val url = googlePhotoUrl
        if (url.isNullOrBlank()) {
            this.value = null
            return@produceState
        }
        this.value = withContext(Dispatchers.IO) {
            runCatching {
                java.net.URL(url).openStream().use { stream ->
                    android.graphics.BitmapFactory.decodeStream(stream)
                }
            }.getOrNull()
        }
    }
    val avatar = localAvatar ?: googleAvatar
    fun persistName() {
        latestOnChange(latestValue.copy(displayName = name.trim().takeIf { it.isNotEmpty() }))
    }
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .height(56.dp)
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clickable(enabled = profileEditable && !pickerPending) {
                    pickerRevision = sessionStore.identityRevision()
                    pickerPending = true
                    picker.launch("image/*")
                }
        ) {
            if (avatar != null) {
                Image(
                    avatar.asImageBitmap(),
                    "Foto de perfil",
                    Modifier.fillMaxSize().clip(CircleShape)
                )
            } else {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            Icons.Outlined.CloudOff,
                            contentDescription = "Añadir foto de perfil",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
            }
            Surface(
                modifier = Modifier.align(Alignment.BottomEnd).size(18.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surface,
                border = BorderStroke(1.5.dp, MaterialTheme.colorScheme.background)
            ) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Icon(
                        painter = painterResource(R.drawable.ic_google_g),
                        contentDescription = "Google",
                        tint = Color.Unspecified,
                        modifier = Modifier.size(11.dp)
                    )
                }
            }
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight(),
            verticalArrangement = Arrangement.SpaceEvenly,
            horizontalAlignment = Alignment.Start
        ) {
            BasicTextField(
                value = name,
                onValueChange = { name = it },
                enabled = profileEditable,
                singleLine = true,
                textStyle = MaterialTheme.typography.titleSmall.copy(
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
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
                                style = MaterialTheme.typography.titleSmall,
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
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            if (onRequestSignOut != null) {
                Text(
                    "Cerrar sesión",
                    style = MaterialTheme.typography.labelMedium,
                    color = Color(0xFFFF453A).copy(alpha = if (busy) 0.38f else 1f),
                    modifier = Modifier.clickable(enabled = !busy, onClick = onRequestSignOut)
                )
            }
        }
    }
    error?.let {
        Text(
            it,
            color = MaterialTheme.colorScheme.error,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
    }
}
