package dev.repera.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.TextButton
import dev.repera.domain.WearSessionDuration

/** Tokens alineados a OG watchOS (fondo negro, accent #30D158, onAccent negro). */
internal object WearOg {
    val bg = Color(0xFF000000)
    val accent = Color(0xFF30D158)
    val onAccent = Color.Black
    val card = Color(0xFF1C1C1E)
    val label2 = Color(0xFFAEAEB2)
    val yellow = Color(0xFFFFD60A)
    val red = Color(0xFFFF453A)
    val orange = Color(0xFFFF9F0A)
}

internal fun wearClockLabel(seconds: Int): String =
    WearSessionDuration.format(seconds.coerceAtLeast(0))

@Composable
internal fun WearStepButton(
    symbol: String,
    contentDescription: String,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    // Compacto para esfera redonda: el 58×62 anterior desbordaba con − valor +.
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .size(width = 40.dp, height = 40.dp)
            .semantics { this.contentDescription = contentDescription },
        shape = CircleShape
    ) {
        Text(
            symbol,
            color = WearOg.onAccent,
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
        )
    }
}

/** Texto de botón a ancho: Wear Material3 alinea el slot a la izquierda. */
@Composable
internal fun WearButtonLabel(
    text: String,
    color: Color = Color.Unspecified,
    style: androidx.compose.ui.text.TextStyle = MaterialTheme.typography.titleSmall
) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text,
            color = color,
            textAlign = TextAlign.Center,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip,
            style = style
        )
    }
}

@Composable
internal fun WearPrimaryButton(
    label: String,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp)
    ) {
        WearButtonLabel(label, color = WearOg.onAccent)
    }
}

@Composable
internal fun WearClockText(
    seconds: Int,
    modifier: Modifier = Modifier,
    contentDescription: String? = null
) {
    Text(
        wearClockLabel(seconds),
        modifier = Modifier
            .fillMaxWidth()
            .then(modifier)
            .then(
                if (contentDescription != null)
                    Modifier.semantics { this.contentDescription = contentDescription }
                else Modifier
            ),
        color = Color.White,
        style = MaterialTheme.typography.displayMedium.copy(
            fontSize = 43.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.SansSerif,
            letterSpacing = 0.sp,
            textAlign = TextAlign.Center
        ),
        textAlign = TextAlign.Center,
        maxLines = 1,
        softWrap = false
    )
}

@Composable
internal fun WearPauseCircle(
    paused: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .size(70.dp)
            .semantics {
                contentDescription = if (paused) "Reanudar entrenamiento" else "Pausar entrenamiento"
            },
        shape = CircleShape
    ) {
        Text(
            if (paused) "▶" else "⏸",
            color = WearOg.onAccent,
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
        )
    }
}

@Composable
internal fun WearHealthRow(bpm: Int?, kcal: Double?) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        bpm?.let {
            Text("♥ $it lpm", color = WearOg.red, style = MaterialTheme.typography.labelSmall)
        }
        kcal?.let {
            Text("🔥 ${it.toInt()} kcal", color = WearOg.orange, style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
internal fun WearStatsLine(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = WearOg.label2, style = MaterialTheme.typography.labelSmall)
        Spacer(Modifier.width(4.dp))
        Text(value, style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold))
    }
}

@Composable
internal fun WearCard(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(WearOg.card.copy(alpha = 0.95f), RoundedCornerShape(13.dp))
    ) {
        Column(modifier = Modifier.fillMaxWidth()) { content() }
    }
}

@Composable
internal fun WearMetricStepper(
    label: String,
    value: String,
    enabled: Boolean = true,
    onMinus: () -> Unit,
    onPlus: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            label,
            color = WearOg.label2,
            style = MaterialTheme.typography.labelSmall,
            maxLines = 1,
            softWrap = false
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            WearStepButton("−", "Reducir $label", enabled, onMinus)
            Text(
                value,
                modifier = Modifier.widthIn(min = 36.dp, max = 72.dp),
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.titleLarge.copy(
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.SansSerif
                ),
                maxLines = 1,
                softWrap = false
            )
            WearStepButton("+", "Aumentar $label", enabled, onPlus)
        }
    }
}
