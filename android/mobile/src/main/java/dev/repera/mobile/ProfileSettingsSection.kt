package dev.repera.mobile
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp

@Composable internal fun ProfileSettingsSection(
    value: ProfileSettings,
    busy: Boolean,
    onChange: (ProfileSettings) -> Unit,
    onRequestSignOut: (() -> Unit)? = null
) {
    val context=LocalContext.current
    var name by remember(value.displayName) {mutableStateOf(value.displayName.orEmpty())}
    var error by remember {mutableStateOf<String?>(null)}
    val latestValue by rememberUpdatedState(value)
    val latestOnChange by rememberUpdatedState(onChange)
    val sessionStore=remember(context) {SessionStore(context)}
    var pickerRevision by remember {mutableStateOf<String?>(null)}
    var pickerPending by remember {mutableStateOf(false)}
    val picker=rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) {uri ->
        val expected=pickerRevision
        val valid=pickerPending && sessionStore.identityRevision()==expected
        pickerPending=false;pickerRevision=null
        if(uri!=null && valid) runCatching {
            val bytes=ProfilePhotoCodec.jpeg(context.contentResolver,uri)
            check(sessionStore.identityRevision()==expected) {"La cuenta cambió al leer la foto"}
            latestOnChange(latestValue.copy(avatarJPEG=android.util.Base64.encodeToString(bytes,android.util.Base64.NO_WRAP)))
            error=null
        }.onFailure {error="No se pudo leer la foto. Prueba otra imagen."}
    }
    val avatar=remember(value.avatarJPEG) {runCatching {value.avatarJPEG?.let {android.util.Base64.decode(it,android.util.Base64.DEFAULT)}?.let {android.graphics.BitmapFactory.decodeByteArray(it,0,it.size)}}.getOrNull()}
    fun persistName() {
        latestOnChange(latestValue.copy(displayName = name.trim().takeIf { it.isNotEmpty() }))
    }
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(modifier = Modifier.clickable(enabled = !busy && !pickerPending) {
            pickerRevision = sessionStore.identityRevision()
            pickerPending = true
            picker.launch("image/*")
        }) {
            if (avatar != null) {
                Image(avatar.asImageBitmap(), "Foto de perfil", Modifier.size(52.dp).clip(CircleShape))
            } else {
                Surface(modifier = Modifier.size(52.dp), shape = CircleShape, color = MaterialTheme.colorScheme.surfaceVariant) {}
            }
            Surface(
                modifier = Modifier.align(Alignment.BottomEnd).size(20.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surface,
                border = BorderStroke(2.dp, MaterialTheme.colorScheme.background)
            ) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("G", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text("Tu nombre") },
                enabled = !busy,
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                textStyle = MaterialTheme.typography.titleMedium,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { persistName() })
            )
            sessionStore.load()?.email?.takeIf { it.isNotBlank() }?.let { email ->
                Text(
                    email,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1
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
    ManualMirrorSyncRow()
}
