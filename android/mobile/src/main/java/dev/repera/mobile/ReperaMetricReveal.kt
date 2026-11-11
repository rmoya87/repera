package dev.repera.mobile

import android.provider.Settings
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import kotlinx.coroutines.yield

/** Gate de proceso: Progreso solo revela números la 1.ª visita (paridad iOS). */
internal object ReperaMetricRevealSession {
    @Volatile var progressHubPlayed: Boolean = false
}

/** `false` = valor final al instante (revisitas de Progreso). */
internal val LocalMetricRevealPlay = compositionLocalOf { true }

/**
 * Solo `true` bajo el hub Progreso (`ProvideMetricRevealPlay`).
 * Fuera (Recuperación, detalle, tests): `progressChartReveal` pinta completo
 * sin delay 220 ms — el default `LocalMetricRevealPlay=true` no implica 1.ª visita.
 */
internal val LocalProgressChartRevealActive = compositionLocalOf { false }

internal fun reperaReduceMotion(context: android.content.Context): Boolean =
    runCatching {
        Settings.Global.getFloat(
            context.contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            1f
        ) == 0f
    }.getOrDefault(false)

/**
 * Como Pasos/Tiempo en Inicio (iOS `OGMetricRevealText`): parte de «—» y llega
 * al valor. Por defecto, tras el primer revelado los cambios son instantáneos
 * (Progreso). Con [animateValueChanges] (Comenzar / cuenta atrás) cada dígito
 * sigue animando. Morph barato: un solo Text + opacidad (composite), sin
 * `AnimatedContent`.
 */
@Composable
internal fun ReperaMetricRevealText(
    value: String,
    modifier: Modifier = Modifier,
    style: TextStyle = LocalTextStyle.current,
    color: androidx.compose.ui.graphics.Color = androidx.compose.ui.graphics.Color.Unspecified,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    overflow: TextOverflow = TextOverflow.Clip,
    animateValueChanges: Boolean = false,
) {
    val context = LocalContext.current
    val reduceMotion = remember(context) { reperaReduceMotion(context) }
    val playReveal = LocalMetricRevealPlay.current
    val shouldAnimate = playReveal && !reduceMotion
    var displayed by remember { mutableStateOf<String?>(null) }
    var didInitialReveal by remember { mutableStateOf(false) }
    val alpha = remember { Animatable(1f) }

    LaunchedEffect(value, playReveal, reduceMotion, animateValueChanges) {
        if (!shouldAnimate) {
            displayed = value
            didInitialReveal = true
            alpha.snapTo(1f)
            return@LaunchedEffect
        }
        if (displayed == value) {
            didInitialReveal = true
            alpha.snapTo(1f)
            return@LaunchedEffect
        }
        if (didInitialReveal && !animateValueChanges) {
            displayed = value
            alpha.snapTo(1f)
            return@LaunchedEffect
        }
        val isInitial = !didInitialReveal
        if (isInitial && displayed == null) {
            displayed = "—"
            alpha.snapTo(1f)
            yield()
        }
        if (animateValueChanges || isInitial) {
            alpha.animateTo(0.35f, animationSpec = tween(70))
            displayed = value
            alpha.animateTo(1f, animationSpec = tween(110))
        } else {
            displayed = value
            alpha.snapTo(1f)
        }
        didInitialReveal = true
    }

    val shown = displayed ?: if (shouldAnimate) "—" else value
    Text(
        shown,
        modifier = modifier.graphicsLayer { this.alpha = alpha.value },
        style = style,
        color = color,
        textAlign = textAlign,
        maxLines = maxLines,
        overflow = overflow
    )
}

@Composable
internal fun ProvideMetricRevealPlay(play: Boolean, content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalMetricRevealPlay provides play,
        LocalProgressChartRevealActive provides true,
        content = content
    )
}
