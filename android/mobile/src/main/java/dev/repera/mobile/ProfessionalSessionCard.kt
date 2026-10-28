package dev.repera.mobile
import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.json.JSONArray

/** Read-only projection. Never mutates personal catalog/session or starts sensors. */
@Composable internal fun ProfessionalSessionCard(session:BusinessCenterStore.ProfessionalSession,centerName:String,compact:Boolean) {
    Card(Modifier.fillMaxWidth()) {Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
        Text(session.title,style=MaterialTheme.typography.titleMedium)
        Text("$centerName · ${session.scheduledDate}",style=MaterialTheme.typography.bodySmall)
        if(session.instructions.isNotEmpty()) Text(session.instructions)
        val blocks=session.prescription?.takeIf {it.optInt("schemaVersion")==1}?.optJSONArray("blocks") ?: JSONArray()
        for(i in 0 until blocks.length()) {
            val b=blocks.getJSONObject(i)
            Text(b.optString("title"),style=MaterialTheme.typography.titleSmall)
            Text(if(b.optString("kind")=="strength") "FUERZA" else b.optString("wodFormat","WOD").uppercase()+
                if(b.has("rounds") && !b.isNull("rounds")) " · ${b.optInt("rounds")} rondas" else "")
            val entries=b.optJSONArray(if(b.optString("kind")=="wod") "movements" else "exercises") ?: JSONArray()
            for(j in 0 until if(compact) minOf(3,entries.length()) else entries.length()) {
                val e=entries.getJSONObject(j);Text(e.optString("name"))
                val sets=e.optJSONArray("plannedSets")
                if(sets!=null && sets.length()>0) Text((0 until sets.length()).joinToString(" / ") { n ->
                    val set=sets.getJSONObject(n)
                    "${set.optInt("targetReps")} rep"+
                        (if(set.has("targetWeightKg") && !set.isNull("targetWeightKg")) " · ${professionalNumber(set.optDouble("targetWeightKg"))} kg" else "")+
                        (if(set.has("targetRir") && !set.isNull("targetRir")) " · RIR ${professionalNumber(set.optDouble("targetRir"))}" else "")
                },style=MaterialTheme.typography.bodySmall)
                else Text(listOfNotNull(e.optInt("reps").takeIf {e.has("reps") && !e.isNull("reps")}?.let {"$it rep"},
                    e.optString("notes").takeIf {it.isNotEmpty()},"Ejercicio libre".takeIf {e.optString("source")=="free"}).joinToString(" · "),style=MaterialTheme.typography.bodySmall)
            }
            if(compact && entries.length()>3) Text("+ ${entries.length()-3} movimientos · Ver todos en el historial")
        }
        if(blocks.length()==0 && session.instructions.isEmpty()) Text("Sin bloques estructurados: el entrenador todavía no ha añadido movimientos.")
    } }
}

private fun professionalNumber(value:Double):String = dev.repera.domain.ReperaNumberFormat.decimal(value)
