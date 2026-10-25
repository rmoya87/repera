package dev.repera.mobile
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.dp
import dev.repera.domain.ProgressDayPoint

@Composable
internal fun SessionScoreProgressCard(points:List<ProgressDayPoint>,preview:Boolean=false) {
 Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text("Puntuación de entrenos",style=MaterialTheme.typography.titleMedium)
  if(preview) Text("Ejemplo · datos ficticios, no son tus puntuaciones")
  if(points.isEmpty()) {
   val axis=MaterialTheme.colorScheme.onSurfaceVariant
   Row {Text("10");Spacer(Modifier.weight(1f));Text("Sin puntuaciones verificadas")}
   Canvas(Modifier.fillMaxWidth().height(130.dp)) {
    drawLine(axis,Offset(0f,0f),Offset(0f,size.height),2f)
    drawLine(axis,Offset(0f,size.height),Offset(size.width,size.height),2f)
   }
   Text("0")
   Text("Todavía no hay puntuaciones basadas en tu historial.")
  } else {
   Text("${kotlin.math.round(points.map {it.value}.average()).toInt()}/10")
   DayPointLineChart(points,valueFormat={"${formatWeight(it)}/10"},bounds=0.0..10.0,interactive=!preview)
  }
 }}
}
