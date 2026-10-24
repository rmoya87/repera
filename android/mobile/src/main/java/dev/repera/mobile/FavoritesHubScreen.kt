package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Hub de favoritos del menú «＋» de día (port de FavoritesHubView iOS):
 * entrenos y temporizadores habituales listos para empezar.
 */
@Composable
internal fun FavoritesHubScreen(
    overview: StateOverview?,
    busy: Boolean,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onBack: () -> Unit
) {
    val favorites = overview?.routineEntries.orEmpty().filter { it.isFavorite }
    LazyColumn(
        modifier = Modifier.fillMaxSize().testTag("favorites_hub"),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Column {
                TextButton(onClick = onBack) { Text("‹ Volver") }
                Text("Favoritos", style = MaterialTheme.typography.headlineMedium)
            }
        }
        if (favorites.isEmpty()) {
            item {
                Text("Marca entrenos o temporizadores con ★ para tenerlos aquí.",
                    fontSize = 14.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        items(favorites, key = { "favhub:" + it.id }) { routine ->
            Card(modifier = Modifier.fillMaxWidth()
                .clickable(enabled = !busy && activeWorkout == null) {
                    onStartRoutine(routine.id)
                }) {
                Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Text(routine.title, style = MaterialTheme.typography.titleMedium)
                    Text("Toca para empezar", fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
