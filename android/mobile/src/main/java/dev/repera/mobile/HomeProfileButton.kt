package dev.repera.mobile
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp

/** Local saved image only. Rendering never publishes the photo. */
@Composable internal fun HomeProfileButton(profile:ProfileSettings,onOpenSettings:()->Unit) {
 val bitmap=remember(profile.avatarJPEG) {runCatching {profile.avatarJPEG?.let {encoded ->
  val bytes=android.util.Base64.decode(encoded,android.util.Base64.DEFAULT)
  android.graphics.BitmapFactory.decodeByteArray(bytes,0,bytes.size)
 }}.getOrNull()}
 IconButton(onClick=onOpenSettings) {
  if(bitmap==null) Icon(Icons.Outlined.Settings,"Ajustes y cuenta")
  else Image(bitmap.asImageBitmap(),"Ajustes y cuenta",Modifier.size(40.dp).clip(CircleShape),contentScale=ContentScale.Crop)
 }
}
