package dev.repera.mobile

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Avatar local o foto de Google; toque abre Ajustes. */
@Composable
internal fun HomeProfileButton(profile: ProfileSettings, onOpenSettings: () -> Unit) {
    val context = LocalContext.current
    val localBitmap = remember(profile.avatarJPEG) {
        runCatching {
            profile.avatarJPEG?.let { encoded ->
                val bytes = android.util.Base64.decode(encoded, android.util.Base64.DEFAULT)
                android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }
        }.getOrNull()
    }
    val googleUrl = remember {
        runCatching { SessionStore(context).googlePhotoUrl() }.getOrNull()
    }
    val googleBitmap by produceState<android.graphics.Bitmap?>(null, googleUrl) {
        val url = googleUrl
        if (url.isNullOrBlank()) {
            value = null
            return@produceState
        }
        value = withContext(Dispatchers.IO) {
            runCatching {
                java.net.URL(url).openStream().use { stream ->
                    android.graphics.BitmapFactory.decodeStream(stream)
                }
            }.getOrNull()
        }
    }
    val bitmap = localBitmap ?: googleBitmap
    if (bitmap != null) {
        IconButton(onClick = onOpenSettings, modifier = Modifier.size(48.dp)) {
            Image(
                bitmap.asImageBitmap(),
                "Ajustes y cuenta",
                Modifier.size(44.dp).clip(CircleShape),
                contentScale = ContentScale.Crop
            )
        }
    } else {
        // Sin foto: silueta de persona (no engranaje / nube).
        Box(Modifier.size(48.dp), contentAlignment = Alignment.Center) {
            Surface(
                onClick = onOpenSettings,
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant,
                modifier = Modifier.size(44.dp)
            ) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Outlined.Person,
                        contentDescription = "Ajustes y cuenta",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }
}
