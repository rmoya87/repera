package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/** Apple page width, not card width, determines the 620-point adaptive breakpoint. */
internal fun adaptiveCardColumns(contentWidthDp:Float,outerHorizontalPaddingDp:Float=0f):Int =
    if(contentWidthDp+outerHorizontalPaddingDp>=620f) 2 else 1

@Composable
internal fun AdaptiveCardPair(
    first:@Composable ()->Unit,
    second:@Composable ()->Unit,
    outerHorizontalPaddingDp:Float=32f
) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns=adaptiveCardColumns(maxWidth.value,outerHorizontalPaddingDp)
        if(columns==2) Row(Modifier.fillMaxWidth().testTag("adaptive_pair_2"),
            horizontalArrangement=Arrangement.spacedBy(12.dp),verticalAlignment=androidx.compose.ui.Alignment.Top) {
            Box(Modifier.weight(1f)) {first()}
            Box(Modifier.weight(1f)) {second()}
        } else Column(Modifier.fillMaxWidth().testTag("adaptive_pair_1"),verticalArrangement=Arrangement.spacedBy(12.dp)) {
            first();second()
        }
    }
}
