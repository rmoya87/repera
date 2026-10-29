package dev.repera.mobile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp

/** Local saved image only. Rendering never publishes the photo. */
@Composable
internal fun HomeProfileButton(profile: ProfileSettings, onOpenSettings: () -> Unit) {
    val bitmap = remember(profile.avatarJPEG) {
        runCatching {
            profile.avatarJPEG?.let { encoded ->
                val bytes = android.util.Base64.decode(encoded, android.util.Base64.DEFAULT)
                android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }
        }.getOrNull()
    }
    if (bitmap == null) {
        Surface(
            onClick = onOpenSettings,
            shape = CircleShape,
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
            border = BorderStroke(
                0.7.dp,
                MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.75f)
            ),
            modifier = Modifier.size(40.dp)
        ) {
            Box(Modifier.size(40.dp), contentAlignment = Alignment.Center) {
                Icon(
                    Icons.Outlined.Settings,
                    "Ajustes y cuenta",
                    modifier = Modifier.size(22.dp),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    } else {
        IconButton(onClick = onOpenSettings) {
            Image(
                bitmap.asImageBitmap(),
                "Ajustes y cuenta",
                Modifier.size(40.dp).clip(CircleShape),
                contentScale = ContentScale.Crop
            )
        }
    }
}
