package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
/** StatsView.healthChartsLayout: stable score/cardio/calories/weight order for both tiers. */
@Composable internal fun ProgressHealthGrid(score:@Composable ()->Unit,cardio:@Composable ()->Unit,calories:@Composable ()->Unit,weight:@Composable ()->Unit) {
 BoxWithConstraints(Modifier.fillMaxWidth()) {
  val columns=adaptiveCardColumns(maxWidth.value,32f)
  val cells=listOf(score,cardio,calories,weight)
  Column(Modifier.fillMaxWidth().testTag("activity_health_columns_$columns"),verticalArrangement=Arrangement.spacedBy(12.dp)) {
   cells.chunked(columns).forEach {row ->
    Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(12.dp),verticalAlignment=androidx.compose.ui.Alignment.Top) {
     row.forEach {cell ->Box(Modifier.weight(1f)) {cell()}}
    }
   }
  }
 }
}
