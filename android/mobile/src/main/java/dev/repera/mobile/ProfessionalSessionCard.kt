package dev.repera.mobile
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.json.JSONArray

/** Proyección del plan del entrenador/clase. `onStart` abre Play para registrar resultados. */
@Composable internal fun ProfessionalSessionCard(
    session: BusinessCenterStore.ProfessionalSession,
    centerName: String,
    compact: Boolean,
    onStart: (() -> Unit)? = null,
) {
    val blocks = session.prescription
        ?.takeIf { BusinessCenterStore.isCanonicalPrescription(it) }
        ?.optJSONArray("blocks")
        ?: JSONArray()
    ReperaCard(Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .then(if (onStart != null) Modifier.clickable(onClick = onStart) else Modifier),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(session.title, style = MaterialTheme.typography.titleMedium)
            Text("$centerName · ${session.scheduledDate}", style = MaterialTheme.typography.bodySmall)
            if (session.instructions.isNotEmpty()) Text(session.instructions)
            for (i in 0 until blocks.length()) {
                val b = blocks.getJSONObject(i)
                Text(b.optString("title"), style = MaterialTheme.typography.titleSmall)
                Text(
                    if (b.optString("kind") == "strength") "FUERZA"
                    else b.optString("wodFormat", "WOD").uppercase() +
                        if (b.has("rounds") && !b.isNull("rounds")) " · ${b.optInt("rounds")} rondas" else ""
                )
                val entries = b.optJSONArray(
                    if (b.optString("kind") == "wod") "movements" else "exercises"
                ) ?: JSONArray()
                for (j in 0 until if (compact) minOf(3, entries.length()) else entries.length()) {
                    val e = entries.getJSONObject(j)
                    Text(e.optString("name"))
                    val sets = e.optJSONArray("plannedSets")
                    if (sets != null && sets.length() > 0) Text(
                        (0 until sets.length()).joinToString(" / ") { n ->
                            val set = sets.getJSONObject(n)
                            "${set.optInt("targetReps")} rep" +
                                (if (set.has("targetWeightKg") && !set.isNull("targetWeightKg"))
                                    " · ${professionalNumber(set.optDouble("targetWeightKg"))} kg" else "") +
                                (if (set.has("targetRir") && !set.isNull("targetRir"))
                                    " · RIR ${professionalNumber(set.optDouble("targetRir"))}" else "")
                        },
                        style = MaterialTheme.typography.bodySmall
                    )
                    else Text(
                        listOfNotNull(
                            e.optInt("reps").takeIf { e.has("reps") && !e.isNull("reps") }?.let { "$it rep" },
                            e.optString("notes").takeIf { it.isNotEmpty() },
                            "Ejercicio libre".takeIf { e.optString("source") == "free" }
                        ).joinToString(" · "),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                if (compact && entries.length() > 3) {
                    Text("+ ${entries.length() - 3} movimientos · Ver todos en el historial")
                }
            }
            if (blocks.length() == 0 && session.instructions.isEmpty()) {
                Text(
                    "Sin bloques estructurados: el entrenador todavía no ha añadido movimientos.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (onStart != null && blocks.length() > 0) {
                Button(
                    onClick = onStart,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        Icons.Filled.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text("Comenzar")
                }
                Text(
                    "Registra series y resultados durante o después de la sesión.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private fun professionalNumber(value: Double): String =
    dev.repera.domain.ReperaNumberFormat.decimal(value)
