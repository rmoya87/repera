package dev.repera.mobile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import dev.repera.domain.CatalogWods
import dev.repera.domain.WodTemplate

/**
 * Elegir WOD a pantalla completa: un único bloque (card) con filas separadas
 * por línea (paridad lista insetGrouped / Ejercicios).
 */
@Composable
internal fun WodCatalogPickerSheet(
    onPick: (WodTemplate) -> Unit,
    onDismiss: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val results = remember(query) { CatalogWods.search(query) }

    ReperaFullscreenDialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .navigationBarsPadding()
                .testTag("wod_picker_fullscreen")
        ) {
            PickerChromeTitle(title = "Elegir WOD", onBack = onDismiss)
            ReperaSearchField(
                value = query,
                onValueChange = { query = it },
                placeholder = "Buscar WOD",
                modifier = Modifier
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .testTag("plan_wod_search")
            )
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                if (results.isEmpty()) {
                    item {
                        Text(
                            "Sin coincidencias",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    }
                } else {
                    item {
                        ReperaInsetGroupedList {
                            results.forEachIndexed { index, t ->
                                if (index > 0) {
                                    HorizontalDivider(
                                        color = MaterialTheme.colorScheme.outlineVariant
                                            .copy(alpha = 0.45f)
                                    )
                                }
                                Column(
                                    Modifier
                                        .fillMaxWidth()
                                        .clickable { onPick(t) }
                                        .padding(horizontal = 14.dp, vertical = 12.dp)
                                        .testTag("plan_wod_pick_${t.id}"),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Text(
                                        t.name,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Text(
                                        listOfNotNull(t.formatLabel, t.typicalLabel)
                                            .joinToString(" · "),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Añadir favorito: mismo chrome y lista agrupada que Elegir WOD.
 */
@Composable
internal fun FavoriteCatalogPickerSheet(
    favorites: List<RoutineEntry>,
    onPick: (RoutineEntry) -> Unit,
    onDismiss: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val filtered = remember(favorites, query) {
        val q = foldForSearch(query)
        if (q.isEmpty()) favorites
        else favorites.filter { foldForSearch(it.title).contains(q) }
    }

    ReperaFullscreenDialog(onDismissRequest = onDismiss) {
        Column(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .navigationBarsPadding()
                .testTag("favorite_picker_fullscreen")
        ) {
            PickerChromeTitle(title = "Añadir favorito", onBack = onDismiss)
            ReperaSearchField(
                value = query,
                onValueChange = { query = it },
                placeholder = "Buscar favorito",
                modifier = Modifier
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .testTag("plan_favorite_search")
            )
            LazyColumn(
                Modifier.fillMaxSize().testTag("add_favorite_list"),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                if (filtered.isEmpty()) {
                    item {
                        Text(
                            if (favorites.isEmpty()) "No hay entrenos en Favoritos."
                            else "Sin coincidencias",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    }
                } else {
                    item {
                        ReperaInsetGroupedList {
                            filtered.forEachIndexed { index, fav ->
                                if (index > 0) {
                                    HorizontalDivider(
                                        color = MaterialTheme.colorScheme.outlineVariant
                                            .copy(alpha = 0.45f)
                                    )
                                }
                                val exerciseCount = fav.blocks.sumOf { it.entries.size }
                                Column(
                                    Modifier
                                        .fillMaxWidth()
                                        .clickable { onPick(fav) }
                                        .padding(horizontal = 14.dp, vertical = 12.dp)
                                        .testTag("add_favorite_${fav.id}"),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Text(
                                        fav.title,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Text(
                                        "· $exerciseCount ej.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PickerChromeTitle(title: String, onBack: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ReperaToolbarGlassIconButton(
            icon = Icons.AutoMirrored.Outlined.ArrowBack,
            contentDescription = "Volver",
            onClick = onBack
        )
        Text(
            title,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        androidx.compose.foundation.layout.Spacer(Modifier.padding(24.dp))
    }
}

/** Una sola card con filas internas (insetGrouped). */
@Composable
internal fun ReperaInsetGroupedList(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    ReperaCard(modifier = modifier.fillMaxWidth()) {
        content()
    }
}
