package dev.repera.mobile
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DragHandle
import androidx.compose.material.icons.outlined.KeyboardArrowDown
import androidx.compose.material.icons.outlined.KeyboardArrowUp
import androidx.compose.material3.*
import dev.repera.domain.RotationPlan

@Composable internal fun RotationSettingsSection(plan:RotationPlan?,routines:List<RoutineEntry>,busy:Boolean,onChange:(RotationPlan?)->Unit) {
    val current=plan ?: RotationPlan(java.util.UUID.randomUUID().toString())
    val heights=remember(current.routineIds) {mutableStateMapOf<Int,Int>()}
    Text(
        "El siguiente entreno sigue este orden, no el día de la semana. Mantén pulsado el tirador y arrastra para reordenar.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    if(current.routineIds.isEmpty()) {
        ReperaEmptyState(
            title = "Sin cola de rotación",
            subtitle = "Añade rutinas para armar el orden A→B→C."
        )
    }
    current.routineIds.forEachIndexed { index,id ->
        key(id) { DragReorderItem(index,heights,current.routineIds.size,onDrop={_,target ->
            if(!busy && target!=index) onChange(current.moved(index,target))
        }) {handle ->
            ReperaCard(modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Outlined.DragHandle,
                            contentDescription = "Reordenar",
                            modifier = Modifier.then(if(busy) Modifier else handle).testTag("rotation_drag_$id").padding(4.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            (if(current.nextRoutineId==id) "Siguiente · " else "") + (routines.firstOrNull {it.id==id}?.title ?: "Rutina"),
                            modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyLarge
                        )
                        IconButton(enabled=!busy && index>0,onClick={onChange(current.moved(index,index-1))}) {
                            Icon(Icons.Outlined.KeyboardArrowUp, contentDescription = "Subir")
                        }
                        IconButton(enabled=!busy && index<current.routineIds.lastIndex,onClick={onChange(current.moved(index,index+1))}) {
                            Icon(Icons.Outlined.KeyboardArrowDown, contentDescription = "Bajar")
                        }
                        IconButton(enabled=!busy,onClick={
                            val ids=current.routineIds.filterNot {it==id}
                            onChange(if(ids.isEmpty()) null else current.copy(routineIds=ids))
                        }) {
                            Icon(Icons.Outlined.Close, contentDescription = "Quitar")
                        }
                    }
                }
            }
        } }
    }
    ReperaSectionTitle("Disponibles")
    val available=routines.filter {it.id !in current.routineIds && it.weekday==null && it.scheduledDate==null}
    if(available.isEmpty()) Text(
        "No hay más rutinas. Crea alguna desde Añadir entreno → Favoritos.",
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    available.forEach { routine ->
        OutlinedButton(
            enabled=!busy,
            onClick={onChange(current.copy(routineIds=current.routineIds+routine.id))},
            modifier = Modifier.fillMaxWidth()
        ) {Text("Añadir ${routine.title}")}
    }
}
