package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import dev.repera.domain.WeeklyWorkoutDay

@Composable
internal fun HomeWeeklyProgressCard(days:List<WeeklyWorkoutDay>,goal:Int?,modifier:Modifier=Modifier) {
    val count=days.sumOf {it.completedCount}
    val trained=days.count {it.completedCount>0}
    ReperaCard(modifier.fillMaxWidth()) {
        Column(Modifier.padding(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
            Text("Progreso semanal",style=MaterialTheme.typography.titleMedium)
            // Paridad HomeView.streakSubtitle (main 153a90b0): días distintos
            // con actividad / planificados, no suma bruta de sesiones.
            val planned = days.count { it.planned }
            Text(
                when {
                    goal != null && goal > 0 ->
                        "$trained días con deporte · $goal objetivo · $count entrenos"
                    planned > 0 ->
                        "$trained días con deporte · $planned días planificados · $count entrenos"
                    trained == 1 -> "1 día con deporte · $count entrenos"
                    else -> "$trained días con deporte · $count entrenos"
                }
            )
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) {
                days.forEach {day ->
                    val label=listOf("LU","MA","MI","JU","VI","SA","DO")[day.date.dayOfWeek.value-1]
                    val done=day.completedCount>0
                    val description="$label ${day.date.dayOfMonth}: "+when {
                        done -> "entrenamiento completado"
                        day.planned -> "entrenamiento planificado"
                        else -> "sin entrenamiento"
                    }
                    Column(horizontalAlignment=Alignment.CenterHorizontally,
                        modifier=Modifier.weight(1f).semantics(mergeDescendants=true) {contentDescription=description}) {
                        Text(label,style=MaterialTheme.typography.labelSmall)
                        Box(Modifier.padding(top=8.dp).size(28.dp)
                            .background(if(done) brandGreen else androidx.compose.ui.graphics.Color.Transparent,CircleShape)
                            .border(if(done) 0.dp else 1.5.dp,
                                if(day.planned) brandGreen else MaterialTheme.colorScheme.outlineVariant,CircleShape),
                            contentAlignment=Alignment.Center) {
                            if(done) Text("✓",color=androidx.compose.ui.graphics.Color.Black)
                        }
                    }
                }
            }
            if(goal!=null && goal>0) LinearProgressIndicator(
                progress={(count.toFloat()/goal).coerceIn(0f,1f)},modifier=Modifier.fillMaxWidth())
        }
    }
}

/** Same cutoff as the current Apple HomeView. Width includes the page's content padding. */
internal fun homeUsesExpandedLayout(widthDp:Float):Boolean = adaptiveCardColumns(widthDp)==2
