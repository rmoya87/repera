package dev.repera.mobile.monetization

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.ArrowOutward
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.mobile.brandGreen

enum class ProTeaserAppearance(val imageOnLeft: Boolean) {
    PROGRESS(false), ACTIVITY(true), RECOVERY(false), EVOLUTION(false)
}

/**
 * Banner Repera Pro. Port estructural de ProTeaserCard.swift.
 * Divergencia documentada: iOS compone escenas con la mascota ReperaMascot;
 * Android no tiene aún assets de mascota y usa iconos de marca en su lugar.
 */
@Composable
fun ProTeaserCard(
    title: String,
    bodyText: String,
    cta: String = "Ver con Repera Pro",
    appearance: ProTeaserAppearance = ProTeaserAppearance.EVOLUTION,
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(22.dp)
    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape),
        shape = shape,
        color = Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .background(
                    Brush.linearGradient(
                        listOf(brandGreen, Color(0xFF69E887))
                    )
                )
                .padding(
                    start = if (appearance.imageOnLeft) 0.dp else 12.dp,
                    end = if (appearance.imageOnLeft) 12.dp else 0.dp,
                    top = 10.dp,
                    bottom = 10.dp
                )
                .heightIn(min = 148.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (appearance.imageOnLeft) TeaserScene(appearance)
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(9.dp)
            ) {
                Text(
                    "REPERA PRO",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = 1.sp,
                    color = Color.Black.copy(alpha = 0.7f)
                )
                Text(
                    title,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Text(
                    bodyText,
                    fontSize = 12.5.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.Black.copy(alpha = 0.8f)
                )
                Row(
                    modifier = Modifier
                        .background(Color.White.copy(alpha = 0.83f), CircleShape)
                        .padding(horizontal = 10.dp, vertical = 9.dp),
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(cta, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                    Icon(
                        Icons.Default.ArrowOutward,
                        contentDescription = null,
                        tint = Color.Black,
                        modifier = Modifier.size(11.dp)
                    )
                }
            }
            if (!appearance.imageOnLeft) TeaserScene(appearance)
        }
    }
}

@Composable
private fun TeaserScene(appearance: ProTeaserAppearance) {
    val icon = when (appearance) {
        ProTeaserAppearance.PROGRESS -> Icons.Default.FitnessCenter
        ProTeaserAppearance.ACTIVITY -> Icons.Default.Air
        ProTeaserAppearance.RECOVERY -> Icons.Default.Bedtime
        ProTeaserAppearance.EVOLUTION -> Icons.AutoMirrored.Filled.TrendingUp
    }
    Box(modifier = Modifier.size(width = 96.dp, height = 148.dp)) {
        Icon(
            icon,
            contentDescription = null,
            tint = Color.White.copy(alpha = 0.6f),
            modifier = Modifier.align(Alignment.Center).size(56.dp)
        )
    }
}
