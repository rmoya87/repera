package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * I-65 Añadir favorito: lista filtrada a entrenos favoritos con «· N ej.» y ⊕
 * (paridad sheet iOS DayEditorView).
 */
@Composable
fun AddFavoriteSheet(
    favorites: List<RoutineEntry>,
    onPick: (RoutineEntry) -> Unit,
    onDismiss: () -> Unit
) {
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Cerrar") }
        },
        title = {
            Text("Añadir favorito", fontWeight = FontWeight.Bold)
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "Añade los bloques de un entrenamiento favorito o un temporizador guardado.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (favorites.isEmpty()) {
                    Text(
                        "No hay entrenos en Favoritos. Márcalos con ★ en el hub o al guardar.",
                        style = MaterialTheme.typography.bodyMedium
                    )
                } else {
                    Text(
                        "Entrenamientos",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    LazyColumn(
                        Modifier.heightIn(max = 360.dp).testTag("add_favorite_list"),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        items(favorites, key = { it.id }) { fav ->
                            val exerciseCount = fav.blocks.sumOf { it.entries.size }
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .clickable { onPick(fav) }
                                    .padding(vertical = 10.dp)
                                    .testTag("add_favorite_${fav.id}"),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(Modifier.weight(1f)) {
                                    Text(fav.title, style = MaterialTheme.typography.titleMedium)
                                    Text(
                                        "· $exerciseCount ej.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                Icon(
                                    Icons.Outlined.Add,
                                    contentDescription = "Añadir",
                                    tint = brandGreen
                                )
                            }
                        }
                    }
                }
            }
        }
    )
}
