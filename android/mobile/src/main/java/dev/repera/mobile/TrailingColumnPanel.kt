package dev.repera.mobile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Half-width overlay, matching Apple's trailing column without replacing the page. */
@Composable
internal fun TrailingColumnPanel(onDismiss:()->Unit,closeLabel:String="‹ Cerrar Ajustes",content:@Composable ()->Unit) {
    BackHandler(onBack=onDismiss)
    // Apple ogTrailingColumnPanel: scrim fades in, the half-width panel moves in from the trailing edge.
    // Dismiss is immediate (no exit animation).
    val shown=androidx.compose.runtime.remember {
        androidx.compose.animation.core.MutableTransitionState(false).apply {targetState=true}
    }
    BoxWithConstraints(Modifier.fillMaxSize().testTag("trailing_panel")) {
        androidx.compose.animation.AnimatedVisibility(shown,enter=androidx.compose.animation.fadeIn()) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha=0.10f)))
        }
        Box(Modifier.width(maxWidth/2).fillMaxHeight()
            .clickable(onClick=onDismiss).testTag("trailing_panel_scrim"))
        androidx.compose.animation.AnimatedVisibility(shown,
            modifier=Modifier.align(Alignment.CenterEnd),
            enter=androidx.compose.animation.slideInHorizontally {it}) {
            Surface(modifier=Modifier.width(maxWidth/2).fillMaxHeight()
                .testTag("trailing_panel_content"),color=MaterialTheme.colorScheme.background) {
                Column {
                    TextButton(onClick=onDismiss,modifier=Modifier.testTag("trailing_panel_close")) {Text(closeLabel)}
                    Box(Modifier.weight(1f).fillMaxWidth()) {content()}
                }
            }
        }
    }
}
