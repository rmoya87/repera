package dev.repera.mobile

import androidx.compose.runtime.Composable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.repera.domain.ProgressionPolicy

/** Controls are offered only for settings with connected consumers. */
@Composable internal fun TrainingSettingsSection(value:TrainingSettings,busy:Boolean,onChange:(TrainingSettings)->Unit) {
    Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
    Text("Unidad", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            listOf("kg","lb").forEach {unit -> ReperaFilterChip(selected=value.weightUnit==unit,enabled=!busy,onClick={onChange(value.copy(weightUnit=unit))},label={Text(unit)})}
        }
        Text("Esfuerzo (registro)", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            listOf("rir","rpe").forEach {unit -> ReperaFilterChip(selected=value.effortUnit==unit,enabled=!busy,onClick={onChange(value.copy(effortUnit=unit))},label={Text(unit.uppercase())})}
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
        Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            OutlinedButton(enabled=!busy && value.weightIncrementKg>0.5,onClick={onChange(value.copy(weightIncrementKg=(value.weightIncrementKg-0.5).coerceAtLeast(0.5)))}) {Text("Restar 0,5 kg")}
            OutlinedButton(enabled=!busy && value.weightIncrementKg<10,onClick={onChange(value.copy(weightIncrementKg=(value.weightIncrementKg+0.5).coerceAtMost(10.0)))}) {Text("Añadir 0,5 kg")}
        }
    }
}
