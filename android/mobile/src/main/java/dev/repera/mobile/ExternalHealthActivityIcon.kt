package dev.repera.mobile

import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.size
import androidx.compose.ui.unit.dp
import dev.repera.domain.LiveSport

/** d99799ac: use the provider's typed activity, never infer from a custom title.
 *  Unknown/legacy entries retain a generic icon. Material equivalents of SF symbols. */
internal fun externalHealthSport(typeKey:String):LiveSport = when(typeKey) {
 "waterSports" -> LiveSport.SWIMMING
 "handCycling" -> LiveSport.CYCLING
 "wheelchairRunPace" -> LiveSport.OTHER
 else -> LiveSport.entries.firstOrNull {it.healthKey==typeKey} ?: LiveSport.OTHER
}

@Composable internal fun ExternalHealthActivityIcon(typeKey:String) {
 Icon(externalHealthSport(typeKey).materialIcon, contentDescription=null,
  modifier=Modifier.size(26.dp))
}
