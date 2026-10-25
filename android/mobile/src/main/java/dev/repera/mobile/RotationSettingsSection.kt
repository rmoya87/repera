package dev.repera.mobile
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import dev.repera.domain.RotationPlan

@Composable internal fun RotationSettingsSection(plan:RotationPlan?,routines:List<RoutineEntry>,busy:Boolean,onChange:(RotationPlan?)->Unit) {
    val current=plan ?: RotationPlan(java.util.UUID.randomUUID().toString())
    Text("Rotación",style=MaterialTheme.typography.titleMedium)
    val heights=remember(current.routineIds) {mutableStateMapOf<Int,Int>()}
    Text("El siguiente entreno sigue este orden, no el día de la semana. Mantén pulsado el tirador y arrastra para reordenar.")
    if(current.routineIds.isEmpty()) Text("Añade rutinas para armar la cola.")
    current.routineIds.forEachIndexed { index,id ->
        key(id) { DragReorderItem(index,heights,current.routineIds.size,onDrop={_,target ->
            if(!busy && target!=index) onChange(current.moved(index,target))
        }) {handle -> Column {
            Text("☰ Arrastrar",modifier=Modifier.then(if(busy) Modifier else handle).testTag("rotation_drag_$id").padding(8.dp))
            Text((if(current.nextRoutineId==id) "Siguiente · " else "") + (routines.firstOrNull {it.id==id}?.title ?: "Rutina"))
            Row {
                TextButton(enabled=!busy && index>0,onClick={onChange(current.moved(index,index-1))}) {Text("Subir")}
                TextButton(enabled=!busy && index<current.routineIds.lastIndex,onClick={onChange(current.moved(index,index+1))}) {Text("Bajar")}
                TextButton(enabled=!busy,onClick={
                    val ids=current.routineIds.filterNot {it==id}
                    onChange(if(ids.isEmpty()) null else current.copy(routineIds=ids))
                }) {Text("Quitar")}
            }
        } } }
    }
    Text("Disponibles",style=MaterialTheme.typography.titleSmall)
    val available=routines.filter {it.id !in current.routineIds && it.weekday==null && it.scheduledDate==null}
    if(available.isEmpty()) Text("No hay más rutinas. Crea alguna en Diario → Rutinas.")
    available.forEach { routine ->
        OutlinedButton(enabled=!busy,onClick={onChange(current.copy(routineIds=current.routineIds+routine.id))}) {Text("Añadir ${routine.title}")}
    }
}
