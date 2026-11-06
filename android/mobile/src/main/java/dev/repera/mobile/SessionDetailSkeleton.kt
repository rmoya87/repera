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
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
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

/** Placeholder estructural del resumen mientras hidrata HC/clima (paridad iOS). */
@Composable
internal fun SessionDetailSkeleton(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
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
        val transition = rememberInfiniteTransition(label = "session_detail_skeleton")
        val animated by transition.animateFloat(
            initialValue = 0.48f,
            targetValue = 0.92f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = 900, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "skeleton_pulse"
        )
        animated
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 16.dp)
            .semantics { contentDescription = "Cargando resumen del entrenamiento" }
            .testTag("session_detail_skeleton")
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(top = 4.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            ReperaToolbarGlassIconButton(
                icon = Icons.AutoMirrored.Outlined.ArrowBack,
                contentDescription = "Volver",
                onClick = onBack,
                modifier = Modifier.testTag("session_detail_skeleton_back")
            )
            Spacer(Modifier.weight(1f))
        }

        Column(
            Modifier
                .fillMaxWidth()
                .graphicsLayer { alpha = pulseAlpha },
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Bone(width = 210.dp, height = 13.dp, color = bone)

            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                repeat(3) {
                Column(
                    Modifier
                        .weight(1f)
                        .height(73.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(card)
                        .padding(horizontal = 6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterVertically),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Bone(width = 14.dp, height = 14.dp, radius = 3.dp, color = bone)
                        Bone(width = 40.dp, height = 11.dp, color = bone)
                    }
                    Bone(width = 52.dp, height = 22.dp, color = bone)
                    Bone(width = 36.dp, height = 10.dp, color = bone)
                }
                }
            }

            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(card)
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Bone(width = 22.dp, height = 22.dp, radius = 6.dp, color = bone)
                    Bone(width = 128.dp, height = 12.dp, color = bone)
                }
                Bone(width = 72.dp, height = 28.dp, color = bone)
                Bone(height = 10.dp, color = bone, fillMaxWidth = true)
                Bone(width = 180.dp, height = 10.dp, color = bone)
            }

            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(card)
            ) {
                Bone(
                    height = 180.dp,
                    color = bone,
                    fillMaxWidth = true,
                    radius = 0.dp
                )
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    repeat(3) {
                        Column(
                            Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Bone(width = 44.dp, height = 10.dp, color = bone)
                            Bone(width = 36.dp, height = 16.dp, color = bone)
                        }
                    }
                }
            }

            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(card)
            ) {
                val titleWidths = listOf(148.dp, 120.dp, 162.dp, 110.dp)
                titleWidths.forEachIndexed { index, titleWidth ->
                    if (index > 0) {
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                        )
                    }
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Bone(width = 44.dp, height = 44.dp, radius = 10.dp, color = bone)
                        Column(
                            Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Bone(width = titleWidth, height = 13.dp, color = bone)
                            Bone(width = titleWidth * 0.62f, height = 10.dp, color = bone)
                        }
                        Bone(width = 10.dp, height = 16.dp, radius = 3.dp, color = bone)
                    }
                }
            }
        }
    }
}

@Composable
private fun Bone(
    height: Dp,
    color: androidx.compose.ui.graphics.Color,
    modifier: Modifier = Modifier,
    width: Dp? = null,
    radius: Dp = 4.dp,
    fillMaxWidth: Boolean = false
) {
    val shape = RoundedCornerShape(radius)
    Box(
        modifier
            .then(
                when {
                    fillMaxWidth -> Modifier.fillMaxWidth()
                    width != null -> Modifier.width(width)
                    else -> Modifier.fillMaxWidth()
                }
            )
            .height(height)
            .clip(shape)
            .background(color)
    )
}
