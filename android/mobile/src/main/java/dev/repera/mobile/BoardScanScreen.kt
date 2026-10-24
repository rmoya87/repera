package dev.repera.mobile

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import dev.repera.domain.BoardScanLiteParser
import dev.repera.domain.CatalogExercise
import dev.repera.domain.RoutineBlock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Pantalla del escáner de pizarra. Paridad con StartHubSheet de iOS:
 * foto -> OCR -> parser lite -> revisión -> crear rutina.
 * Gate de suscripción replicado como costura (BoardScanQuota) pendiente
 * de monetización real.
 */
@Composable
internal fun BoardScanScreen(
    busy: Boolean,
    overview: StateOverview?,
    onConfirm: (String, List<RoutineBlock>) -> Unit,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var reading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var review by remember { mutableStateOf<List<RoutineBlock>?>(null) }
    var reviewTitle by remember { mutableStateOf("Entreno de pizarra") }

    fun process(uri: Uri) {
        if (reading) return
        if (!BoardScanQuota.canStart()) {
            // Paywall pendiente de RevenueCat; hoy nunca se alcanza.
            errorMessage = "Escaneos agotados. La suscripción llegará pronto."
            return
        }
        reading = true
        errorMessage = null
        scope.launch {
            try {
                val text = BoardScanOcr.recognize(context, uri)
                val catalog = (overview?.exerciseEntries ?: emptyList())
                    .map { CatalogExercise(it.id, it.name) }
                val aliases = ExerciseSearchAssets.load(context)
                val parsed = withContext(Dispatchers.Default) {
                    BoardScanLiteParser.parse(ocrText = text, catalog = catalog,
                        searchAliases = aliases)
                }
                if (parsed.blocks.isEmpty() && parsed.lines.isEmpty()) {
                    errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                } else {
                    BoardScanQuota.consume()
                    review = parsed.blocks
                }
            } catch (error: Exception) {
                errorMessage = error.localizedMessage ?: "No se pudo leer la foto"
            } finally {
                reading = false
            }
        }
    }

    val pickImage = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? -> uri?.let(::process) }

    val photoUri = remember {
        val dir = File(context.cacheDir, "board_scan").apply { mkdirs() }
        FileProvider.getUriForFile(context, context.packageName + ".boardscan",
            File(dir, "captura.jpg"))
    }
    val takePicture = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { ok: Boolean -> if (ok) process(photoUri) }

    val blocks = review
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item { Text("Importar pizarra", style = MaterialTheme.typography.headlineMedium) }
        if (blocks == null) {
            item {
                Text("Fotografía la pizarra del box y Repera la convierte en una rutina.")
            }
            item {
                Button(
                    onClick = { takePicture.launch(photoUri) },
                    enabled = !busy && !reading,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = brandGreen, contentColor = Color.Black)
                ) { Text("Tomar foto") }
            }
            item {
                OutlinedButton(
                    onClick = { pickImage.launch("image/*") },
                    enabled = !busy && !reading,
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Elegir de la galería") }
            }
            if (reading) {
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Text("Leyendo la pizarra…", modifier = Modifier.padding(top = 8.dp))
                    }
                }
            }
            errorMessage?.let { msg ->
                item { Text(msg, color = MaterialTheme.colorScheme.error) }
            }
            item {
                OutlinedButton(onClick = onBack, enabled = !reading,
                    modifier = Modifier.fillMaxWidth()) { Text("Volver") }
            }
        } else {
            item {
                OutlinedTextField(
                    value = reviewTitle,
                    onValueChange = { reviewTitle = it },
                    label = { Text("Título de la rutina") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
            items(blocks.size) { index ->
                val block = blocks[index]
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(block.title, style = MaterialTheme.typography.titleMedium)
                        val details = buildString {
                            block.wodFormat?.let { append(it.raw) }
                            block.timeCapMinutes?.let { append(" · TC $it min") }
                            block.rounds?.let { append(" · $it rondas") }
                            block.emomIntervalSeconds?.let {
                                if (block.wodFormat == dev.repera.domain.WODFormat.EMOM)
                                    append(" · cada $it s")
                            }
                        }
                        if (details.isNotBlank()) {
                            Text(details, style = MaterialTheme.typography.bodySmall)
                        }
                        if (block.exercises.isNotEmpty()) {
                            Text("${block.exercises.size} ejercicios",
                                style = MaterialTheme.typography.bodySmall)
                            block.exercises.take(5).forEach { ex ->
                                val name = overview?.exerciseEntries
                                    ?.firstOrNull { it.id == ex.exerciseId }?.displayName
                                    ?: ex.exerciseId
                                Text("· $name (${ex.plannedSets.size} series)",
                                    style = MaterialTheme.typography.bodySmall)
                            }
                        }
                        if (block.movements.isNotEmpty()) {
                            Text("${block.movements.size} movimientos",
                                style = MaterialTheme.typography.bodySmall)
                            block.movements.take(6).forEach { move ->
                                Text("· ${move.summaryLine}",
                                    style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
            item {
                Button(
                    onClick = { onConfirm(reviewTitle, blocks) },
                    enabled = !busy && reviewTitle.isNotBlank(),
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = brandGreen, contentColor = Color.Black)
                ) { Text("Crear rutina") }
            }
            item {
                OutlinedButton(onClick = { review = null; errorMessage = null },
                    enabled = !busy, modifier = Modifier.fillMaxWidth()) {
                    Text("Repetir foto")
                }
            }
        }
    }
}
