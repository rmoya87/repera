package dev.repera.mobile
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

@Composable internal fun ProfileSettingsSection(value:ProfileSettings,busy:Boolean,onChange:(ProfileSettings)->Unit) {
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
    Text("Perfil",style=MaterialTheme.typography.titleMedium)
    val avatar=remember(value.avatarJPEG) {runCatching {value.avatarJPEG?.let {android.util.Base64.decode(it,android.util.Base64.DEFAULT)}?.let {android.graphics.BitmapFactory.decodeByteArray(it,0,it.size)}}.getOrNull()}
    // Identidad Google (paridad badge SettingsView iOS 619888f2): en Android
    // la cuenta verificada es siempre Google Sign-In.
    Row(horizontalArrangement=Arrangement.spacedBy(12.dp),verticalAlignment=Alignment.CenterVertically) {
        Box {
            if (avatar != null) {
                Image(avatar.asImageBitmap(),"Foto de perfil",Modifier.size(72.dp))
            } else {
                Surface(modifier=Modifier.size(72.dp),shape=CircleShape,color=MaterialTheme.colorScheme.surfaceVariant) {}
            }
            Surface(
                modifier=Modifier.align(Alignment.BottomEnd).size(22.dp),
                shape=CircleShape,
                color=MaterialTheme.colorScheme.surface,
                border=BorderStroke(2.dp,MaterialTheme.colorScheme.background)
            ) {
                Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center) {
                    Text("G",style=MaterialTheme.typography.labelSmall,color=MaterialTheme.colorScheme.primary)
                }
            }
        }
        Text("Cuenta Google",style=MaterialTheme.typography.bodyMedium)
    }
    OutlinedTextField(value=name,onValueChange={name=it},label={Text("Tu nombre")},enabled=!busy,singleLine=true,modifier=Modifier.fillMaxWidth())
    OutlinedButton(onClick={onChange(value.copy(displayName=name.trim().takeIf {it.isNotEmpty()}))},enabled=!busy) {Text("Guardar nombre")}
    OutlinedButton(onClick={pickerRevision=sessionStore.identityRevision();pickerPending=true;picker.launch("image/*")},enabled=!busy && !pickerPending) {Text("Cambiar foto de perfil")}
    Text("Foto guardada en tus datos. No se publica en el perfil del centro desde aquí.",style=MaterialTheme.typography.bodySmall)
    error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    ManualMirrorSyncRow()
}
