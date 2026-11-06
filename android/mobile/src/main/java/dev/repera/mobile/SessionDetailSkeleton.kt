package dev.repera.mobile

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
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

/** Placeholder estructural del resumen mientras hidrata HC/clima (paridad iOS). */
@Composable
internal fun SessionDetailSkeleton(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val bone = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
    val card = MaterialTheme.colorScheme.surface
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
                .padding(top = 4.dp, bottom = 12.dp),
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
        Box(
            Modifier
                .width(160.dp)
                .height(14.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(bone)
        )
        Spacer(Modifier.height(14.dp))
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            repeat(3) {
                Column(
                    Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(14.dp))
                        .background(card)
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        Modifier
                            .width(36.dp)
                            .height(12.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(bone)
                    )
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(28.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(bone)
                    )
                }
            }
        }
        Spacer(Modifier.height(14.dp))
        Box(
            Modifier
                .fillMaxWidth()
                .height(120.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(card)
        )
        Spacer(Modifier.height(14.dp))
        repeat(4) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(card)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Box(
                    Modifier
                        .size(56.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(bone)
                )
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(
                        Modifier
                            .width(140.dp)
                            .height(12.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(bone)
                    )
                    Box(
                        Modifier
                            .width(90.dp)
                            .height(10.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(bone)
                    )
                }
            }
            Spacer(Modifier.height(12.dp))
        }
    }
}
