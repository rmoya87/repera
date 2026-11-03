package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
/** Gráficas sanitarias generales. La puntuación deportiva se ubica en Entreno. */
@Composable internal fun ProgressHealthGrid(
 score:@Composable ()->Unit,
 cardio:@Composable ()->Unit,
 calories:@Composable ()->Unit,
 weight:@Composable ()->Unit,
 showScore:Boolean=true
) {
 BoxWithConstraints(Modifier.fillMaxWidth()) {
  val columns=adaptiveCardColumns(maxWidth.value,32f)
  val cells=if(showScore) listOf(score,cardio,calories,weight) else listOf(cardio,calories,weight)
  Column(Modifier.fillMaxWidth().testTag("activity_health_columns_$columns"),verticalArrangement=Arrangement.spacedBy(12.dp)) {
   cells.chunked(columns).forEach {row ->
    Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(12.dp),verticalAlignment=androidx.compose.ui.Alignment.Top) {
     row.forEach {cell ->Box(Modifier.weight(1f)) {cell()}}
    }
   }
  }
 }
}
