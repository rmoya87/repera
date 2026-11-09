package dev.repera.mobile

import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.ProgressionPolicy
import dev.repera.domain.StrengthReferenceFrame

/** Controls are offered only for settings with connected consumers. */
@Composable internal fun TrainingSettingsSection(value:TrainingSettings,busy:Boolean,onChange:(TrainingSettings)->Unit) {
    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
    Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Género", style = MaterialTheme.typography.bodyLarge)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("female" to "Femenino", "male" to "Masculino").forEach { (sex, label) ->
                    ReperaFilterChip(
                        selected = value.competitionSex == sex,
                        enabled = !busy,
                        onClick = {
                            onChange(
                                value.copy(
                                    competitionSex = if (value.competitionSex == sex) null else sex
                                )
                            )
                        },
                        label = { Text(label) }
                    )
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Nivel", style = MaterialTheme.typography.bodyLarge)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(
                    StrengthReferenceFrame.AMATEUR.wire to "Amateur",
                    StrengthReferenceFrame.ELITE.wire to "Élite"
                ).forEach { (frame, label) ->
                    ReperaFilterChip(
                        selected = value.strengthReferenceFrame == frame,
                        enabled = !busy,
                        onClick = { onChange(value.copy(strengthReferenceFrame = frame)) },
                        label = { Text(label) }
                    )
                }
            }
        }
        var yearMenuOpen by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically) {
            Text("Año de nacimiento", style = MaterialTheme.typography.bodyLarge)
            Box {
                OutlinedButton(onClick = { yearMenuOpen = true }, enabled = !busy) {
                    Text(value.birthYear?.toString() ?: "Sin indicar")
                }
                DropdownMenu(expanded = yearMenuOpen, onDismissRequest = { yearMenuOpen = false }) {
                    DropdownMenuItem(text = { Text("Sin indicar") }, onClick = {
                        onChange(value.copy(birthYear = null)); yearMenuOpen = false
                    })
                    for (year in java.time.Year.now().value downTo (java.time.Year.now().value - 100)) {
                        DropdownMenuItem(text = { Text(year.toString()) }, onClick = {
                            onChange(value.copy(birthYear = year)); yearMenuOpen = false
                        })
                    }
                }
            }
        }
        Text("Unidad", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            listOf("kg","lb").forEach {unit -> ReperaFilterChip(selected=value.weightUnit==unit,enabled=!busy,onClick={onChange(value.copy(weightUnit=unit))},label={Text(unit)})}
        }
        Text("Esfuerzo (registro)", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            listOf("rir","rpe").forEach {unit -> ReperaFilterChip(selected=value.effortUnit==unit,enabled=!busy,onClick={onChange(value.copy(effortUnit=unit))},label={Text(unit.uppercase())})}
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("FC máxima", style = MaterialTheme.typography.bodyLarge)
            Text(
                "${value.heartRateMaxBpm ?: 190} lpm",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
                enabled = !busy && (value.heartRateMaxBpm ?: 190) > 120,
                onClick = {
                    onChange(
                        value.copy(
                            heartRateMaxBpm = ((value.heartRateMaxBpm ?: 190) - 5).coerceAtLeast(120)
                        )
                    )
                }
            ) { Text("−5") }
            OutlinedButton(
                enabled = !busy && (value.heartRateMaxBpm ?: 190) < 230,
                onClick = {
                    onChange(
                        value.copy(
                            heartRateMaxBpm = ((value.heartRateMaxBpm ?: 190) + 5).coerceAtMost(230)
                        )
                    )
                }
            ) { Text("+5") }
        }
        Text("Modo de plan")
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            ReperaFilterChip(selected=value.scheduleMode=="fixedWeek",enabled=!busy,onClick={onChange(value.copy(scheduleMode="fixedWeek"))},label={Text("Semana fija")})
            ReperaFilterChip(selected=value.scheduleMode=="rotation",enabled=!busy,onClick={onChange(value.copy(scheduleMode="rotation"))},label={Text("Rotación A→B→C")})
        }
        Text("Semana empieza")
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            ReperaFilterChip(selected=value.weekStartsOnMonday,enabled=!busy,onClick={onChange(value.copy(weekStartsOnMonday=true))},label={Text("Lunes")})
            ReperaFilterChip(selected=!value.weekStartsOnMonday,enabled=!busy,onClick={onChange(value.copy(weekStartsOnMonday=false))},label={Text("Domingo")})
        }
        Text("Descanso: ${value.defaultRestSeconds}s")
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            OutlinedButton(enabled=!busy && value.defaultRestSeconds>30,onClick={onChange(value.copy(defaultRestSeconds=(value.defaultRestSeconds-15).coerceAtLeast(30)))}) {Text("Restar 15 s")}
            OutlinedButton(enabled=!busy && value.defaultRestSeconds<300,onClick={onChange(value.copy(defaultRestSeconds=(value.defaultRestSeconds+15).coerceAtMost(300)))}) {Text("Añadir 15 s")}
        }
        Row { Text("Sonido al terminar descanso",modifier=Modifier.weight(1f));Switch(checked=value.restSoundEnabled,enabled=!busy,onCheckedChange={onChange(value.copy(restSoundEnabled=it))},colors=reperaSwitchColors()) }
        Row { Text("Vibración en countdown",modifier=Modifier.weight(1f));Switch(checked=value.restHapticEnabled,enabled=!busy,onCheckedChange={onChange(value.copy(restHapticEnabled=it))},colors=reperaSwitchColors()) }
        Text("Progresión por defecto")
        ProgressionPolicy.entries.forEach { policy ->
            ReperaFilterChip(selected=value.defaultProgression==policy.wire,enabled=!busy,
                onClick={onChange(value.copy(defaultProgression=policy.wire))},label={Text(policy.displayName)})
        }
        Text("Incremento: ${dev.repera.domain.ReperaNumberFormat.decimal(value.weightIncrementKg)} kg")
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(enabled=!busy && value.weightIncrementKg>0.5,onClick={onChange(value.copy(weightIncrementKg=(value.weightIncrementKg-0.5).coerceAtLeast(0.5)))}) {Text("Restar 0,5 kg")}
            OutlinedButton(enabled=!busy && value.weightIncrementKg<10,onClick={onChange(value.copy(weightIncrementKg=(value.weightIncrementKg+0.5).coerceAtMost(10.0)))}) {Text("Añadir 0,5 kg")}
        }
    }
}
