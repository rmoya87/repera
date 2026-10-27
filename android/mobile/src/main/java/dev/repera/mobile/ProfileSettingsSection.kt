package dev.repera.mobile
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
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
    avatar?.let {Image(it.asImageBitmap(),"Foto de perfil",Modifier.size(72.dp))}
    OutlinedTextField(value=name,onValueChange={name=it},label={Text("Tu nombre")},enabled=!busy,singleLine=true,modifier=Modifier.fillMaxWidth())
    OutlinedButton(onClick={onChange(value.copy(displayName=name.trim().takeIf {it.isNotEmpty()}))},enabled=!busy) {Text("Guardar nombre")}
    OutlinedButton(onClick={pickerRevision=sessionStore.identityRevision();pickerPending=true;picker.launch("image/*")},enabled=!busy && !pickerPending) {Text("Cambiar foto de perfil")}
    Text("Foto guardada en tus datos. No se publica en el perfil del centro desde aquí.",style=MaterialTheme.typography.bodySmall)
    error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
    ManualMirrorSyncRow()
}
