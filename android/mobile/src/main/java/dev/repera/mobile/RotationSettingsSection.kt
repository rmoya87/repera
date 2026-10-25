package dev.repera.mobile
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import dev.repera.domain.RotationPlan

@Composable internal fun RotationSettingsSection(plan:RotationPlan?,routines:List<RoutineEntry>,busy:Boolean,onChange:(RotationPlan?)->Unit) {
    val current=plan ?: RotationPlan(java.util.UUID.randomUUID().toString())
    Text("Rotación",style=MaterialTheme.typography.titleMedium)
    Text("El siguiente entreno sigue este orden, no el día de la semana.")
    if(current.routineIds.isEmpty()) Text("Añade rutinas para armar la cola.")
    current.routineIds.forEachIndexed { index,id ->
        Column {
            Text((if(current.nextRoutineId==id) "Siguiente · " else "") + (routines.firstOrNull {it.id==id}?.title ?: "Rutina"))
            Row {
                TextButton(enabled=!busy && index>0,onClick={onChange(current.moved(index,index-1))}) {Text("Subir")}
                TextButton(enabled=!busy && index<current.routineIds.lastIndex,onClick={onChange(current.moved(index,index+1))}) {Text("Bajar")}
                TextButton(enabled=!busy,onClick={
                    val ids=current.routineIds.filterNot {it==id}
                    onChange(if(ids.isEmpty()) null else current.copy(routineIds=ids))
                }) {Text("Quitar")}
            }
        }
    }
    Text("Disponibles",style=MaterialTheme.typography.titleSmall)
    routines.filter {it.id !in current.routineIds && it.weekday==null && it.scheduledDate==null}.forEach { routine ->
        OutlinedButton(enabled=!busy,onClick={onChange(current.copy(routineIds=current.routineIds+routine.id))}) {Text("Añadir ${routine.title}")}
    }
}
