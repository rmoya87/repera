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
    val picker=rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) {uri ->
        if(uri!=null) runCatching {
            // ImageDecoder honors camera EXIF orientation and downsamples before allocation.
            val source=android.graphics.ImageDecoder.createSource(context.contentResolver,uri)
            val bitmap=android.graphics.ImageDecoder.decodeBitmap(source) {decoder,info,_ ->
                val scale=minOf(1.0,256.0/maxOf(info.size.width,info.size.height))
                decoder.setTargetSize(maxOf(1,(info.size.width*scale).toInt()),maxOf(1,(info.size.height*scale).toInt()))
                decoder.allocator=android.graphics.ImageDecoder.ALLOCATOR_SOFTWARE
            }
            val bytes=java.io.ByteArrayOutputStream().also {bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG,82,it)}.toByteArray()
            require(bytes.size<=200_000)
            onChange(value.copy(avatarJPEG=android.util.Base64.encodeToString(bytes,android.util.Base64.NO_WRAP)))
            error=null
        }.onFailure {error="No se pudo leer la foto. Prueba otra imagen."}
    }
    Text("Perfil",style=MaterialTheme.typography.titleMedium)
    val avatar=remember(value.avatarJPEG) {runCatching {value.avatarJPEG?.let {android.util.Base64.decode(it,android.util.Base64.DEFAULT)}?.let {android.graphics.BitmapFactory.decodeByteArray(it,0,it.size)}}.getOrNull()}
    avatar?.let {Image(it.asImageBitmap(),"Foto de perfil",Modifier.size(72.dp))}
    OutlinedTextField(value=name,onValueChange={name=it.take(100)},label={Text("Tu nombre")},enabled=!busy,singleLine=true,modifier=Modifier.fillMaxWidth())
    OutlinedButton(onClick={onChange(value.copy(displayName=name.trim().takeIf {it.isNotEmpty()}))},enabled=!busy) {Text("Guardar nombre")}
    OutlinedButton(onClick={picker.launch("image/*")},enabled=!busy) {Text("Cambiar foto de perfil")}
    Text("Foto guardada en tus datos. No se publica en el perfil del centro desde aquí.",style=MaterialTheme.typography.bodySmall)
    error?.let {Text(it,color=MaterialTheme.colorScheme.error)}
}
