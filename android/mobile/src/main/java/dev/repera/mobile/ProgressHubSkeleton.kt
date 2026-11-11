package dev.repera.mobile

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import android.provider.Settings

/** Placeholder estructural del hub Progreso (paridad iOS; sin spinner «Cargando»). */
@Composable
internal fun ProgressHubSkeleton(modifier: Modifier = Modifier) {
    val bone = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f)
    val card = MaterialTheme.colorScheme.surface
    val contentResolver = LocalContext.current.contentResolver
    val reduceMotion = runCatching {
        Settings.Global.getFloat(
            contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            1f
        ) == 0f
    }.getOrDefault(false)
    val pulseAlpha = if (reduceMotion) {
        0.72f
    } else {
        val transition = rememberInfiniteTransition(label = "progress_hub_skeleton")
        val animated by transition.animateFloat(
            initialValue = 0.48f,
            targetValue = 0.92f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = 900, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "progress_skeleton_pulse"
        )
        animated
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer { alpha = pulseAlpha }
            .semantics { contentDescription = "Preparando progreso" }
            .testTag("progress_hub_skeleton"),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        SkeletonCard(card) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Bone(bone, 22.dp, 22.dp)
                    Bone(bone, 140.dp, 13.dp)
                }
                Bone(bone, 96.dp, 36.dp)
                Bone(bone, height = 11.dp, fillMaxWidth = true)
                Bone(bone, 200.dp, 11.dp)
                Bone(bone, height = 56.dp, fillMaxWidth = true)
            }
        }
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            GlanceBone(bone, card, Modifier.weight(1f), 72.dp)
            GlanceBone(bone, card, Modifier.weight(1f), 88.dp)
        }
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            GlanceBone(bone, card, Modifier.weight(1f), 64.dp)
            GlanceBone(bone, card, Modifier.weight(1f), 80.dp)
        }
        SkeletonCard(card) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Bone(bone, 20.dp, 20.dp)
                    Bone(bone, 120.dp, 12.dp)
                }
                Bone(bone, 84.dp, 28.dp)
                Bone(bone, height = 72.dp, fillMaxWidth = true)
            }
        }
    }
}

@Composable
private fun GlanceBone(
    bone: androidx.compose.ui.graphics.Color,
    card: androidx.compose.ui.graphics.Color,
    modifier: Modifier,
    titleWidth: Dp
) {
    Column(
        modifier
            .clip(RoundedCornerShape(16.dp))
            .background(card)
            .padding(14.dp)
            .height(88.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Bone(bone, titleWidth, 11.dp)
        Bone(bone, 56.dp, 22.dp)
        Bone(bone, 44.dp, 10.dp)
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun SkeletonCard(
    card: androidx.compose.ui.graphics.Color,
    content: @Composable () -> Unit
) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(card)
            .padding(14.dp)
    ) {
        content()
    }
}

@Composable
private fun Bone(
    color: androidx.compose.ui.graphics.Color,
    width: Dp? = null,
    height: Dp,
    fillMaxWidth: Boolean = false
) {
    Box(
        Modifier
            .then(
                when {
                    fillMaxWidth -> Modifier.fillMaxWidth()
                    width != null -> Modifier.width(width)
                    else -> Modifier.fillMaxWidth()
                }
            )
            .height(height)
            .clip(RoundedCornerShape(6.dp))
            .background(color)
    )
}
