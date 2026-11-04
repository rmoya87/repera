package dev.repera.mobile

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.SystemClock

/**
 * Lock-screen / headphone controls for strength rest countdown only.
 * Never writes Health Connect or confirms sets.
 */
internal class RestMediaSessionController(
    private val context: Context,
    private val onSkip: () -> Unit,
    private val onPauseToggle: () -> Unit
) {
    private var session: MediaSession? = null
    private var paused = false

    fun ensure() {
        if (session != null) return
        val media = MediaSession(context, "repera.rest")
        media.setCallback(object : MediaSession.Callback() {
            override fun onPlay() {
                paused = false
                onPauseToggle()
            }

            override fun onPause() {
                paused = true
                onPauseToggle()
            }

            override fun onSkipToNext() {
                onSkip()
            }

            override fun onStop() {
                onSkip()
            }
        })
        media.isActive = true
        session = media
    }

    fun update(exerciseName: String, remainingSec: Int, totalSec: Int, isPaused: Boolean) {
        ensure()
        paused = isPaused
        val title = if (exerciseName.isBlank()) "Descanso Repera" else "Descanso · $exerciseName"
        session?.setMetadata(
            MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, title)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, "Repera")
                .putLong(MediaMetadata.METADATA_KEY_DURATION, totalSec.coerceAtLeast(remainingSec) * 1000L)
                .build()
        )
        val elapsed = (totalSec - remainingSec).coerceAtLeast(0) * 1000L
        val state = if (isPaused) PlaybackState.STATE_PAUSED else PlaybackState.STATE_PLAYING
        session?.setPlaybackState(
            PlaybackState.Builder()
                .setActions(
                    PlaybackState.ACTION_PLAY
                        or PlaybackState.ACTION_PAUSE
                        or PlaybackState.ACTION_SKIP_TO_NEXT
                        or PlaybackState.ACTION_STOP
                        or PlaybackState.ACTION_PLAY_PAUSE
                )
                .setState(state, elapsed, if (isPaused) 0f else 1f, SystemClock.elapsedRealtime())
                .build()
        )
        val open = PendingIntent.getActivity(
            context, 42, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        session?.setSessionActivity(open)
    }

    fun release() {
        session?.isActive = false
        session?.release()
        session = null
    }
}
