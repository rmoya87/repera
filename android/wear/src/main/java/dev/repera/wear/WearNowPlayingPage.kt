package dev.repera.wear

import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.FilledIconButton
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.IconButtonDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.touchTargetAwareSize

/**
 * Página lateral de audio durante un entreno/temporizador.
 * Despacha teclas multimedia del sistema (API pública) — sin
 * permiso privilegiado de sesión ni lanzadores privados de OEM.
 */
@Composable
internal fun WearNowPlayingPage(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val btn = IconButtonDefaults.DefaultButtonSize
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically)
    ) {
        Text(
            text = stringResource(R.string.wear_now_playing_title),
            style = MaterialTheme.typography.titleSmall,
            textAlign = TextAlign.Center,
            maxLines = 1
        )
        Text(
            text = stringResource(R.string.wear_now_playing_subtitle),
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            maxLines = 2
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilledIconButton(
                onClick = { context.dispatchWearMediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS) },
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = Icons.Filled.SkipPrevious,
                    contentDescription = stringResource(R.string.wear_cd_media_previous)
                )
            }
            FilledIconButton(
                onClick = { context.dispatchWearMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE) },
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = Icons.Filled.PlayArrow,
                    contentDescription = stringResource(R.string.wear_cd_media_play_pause)
                )
            }
            FilledIconButton(
                onClick = { context.dispatchWearMediaKey(KeyEvent.KEYCODE_MEDIA_NEXT) },
                modifier = Modifier.touchTargetAwareSize(btn),
                colors = IconButtonDefaults.filledIconButtonColors()
            ) {
                Icon(
                    imageVector = Icons.Filled.SkipNext,
                    contentDescription = stringResource(R.string.wear_cd_media_next)
                )
            }
        }
    }
}

/** Envía down+up de una tecla multimedia a la sesión activa del sistema. */
internal fun Context.dispatchWearMediaKey(keyCode: Int) {
    val audio = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
    audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
    audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
}
