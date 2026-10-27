package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

/** No nested card: the caller already owns section margins and background. */
@Composable
internal fun RestPauseClusterEditor(clusters:List<Pair<Int,Int>>,reps:String,rest:String,busy:Boolean,
    onReps:(String)->Unit,onRest:(String)->Unit,onAdd:(Int,Int)->Unit) {
    Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        Text("Clusters (myo / rest-pause)",style=MaterialTheme.typography.titleSmall)
        Text("Las reps totales = suma de clusters. El peso es el de la serie.",style=MaterialTheme.typography.bodySmall)
        clusters.forEachIndexed {i,c ->Text("${i+1}. ${c.first} reps · descanso ${c.second} s")}
        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(12.dp)) {
            OutlinedTextField(reps,{onReps(it.filter(Char::isDigit))},label={Text("REPS")},
                modifier=Modifier.weight(1f),singleLine=true,enabled=!busy,
                keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Number))
            OutlinedTextField(rest,{onRest(it.filter(Char::isDigit))},label={Text("DESCANSO")},suffix={Text("s")},
                modifier=Modifier.weight(1f),singleLine=true,enabled=!busy,
                keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Number))
        }
        val r=reps.toIntOrNull();val seconds=rest.toIntOrNull()
        OutlinedButton(onClick={if(r!=null && seconds!=null) onAdd(r,seconds)},
            modifier=Modifier.fillMaxWidth().heightIn(min=46.dp),
            enabled=!busy && clusters.size<8 && r!=null && r in 1..10000 && seconds!=null && seconds in 5..30) {
            Text("Añadir cluster")
        }
    }
}
