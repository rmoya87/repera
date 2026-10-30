package dev.repera.mobile

import dev.repera.mobile.monetization.LocalSubscriptions
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import dev.repera.domain.BoardClassicReview
import dev.repera.domain.BoardScanLiteParser
import dev.repera.domain.SportExerciseNames
import dev.repera.domain.CatalogExercise
import dev.repera.domain.RoutineBlock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Pantalla del escáner de pizarra. Paridad con StartHubSheet de iOS:
 * foto -> OCR -> parser lite -> revisión -> crear rutina.
 * Gate de suscripción real: canStartBoardScan() antes de leer y
 * consumeBoardScanIfNeeded(attemptID) idempotente al llegar a revisión
 * (igual que iOS); el paywall se presenta con contexto boardScansLimit.
 */
@Composable
internal fun BoardScanScreen(
    busy: Boolean,
    overview: StateOverview?,
    onConfirm: (String, List<RoutineBlock>,String) -> Unit,
    /** Crear + iniciar sesión (paridad Empezar iOS). */
    onStart: (String, List<RoutineBlock>, String) -> Unit = onConfirm,
    saveStatus:String? = null,
    onBack: () -> Unit,
    /** Nuevo destino del editor: no crear ni iniciar una segunda actividad. */
    onImportBlocks: ((List<RoutineBlock>) -> Unit)? = null,
    catalogOverride: List<ExerciseEntry> = emptyList(),
    /** Modal ajustado (editor / DayPlus); sin fillMaxSize ni status bars. */
    asSheet: Boolean = false
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var reading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var review by remember { mutableStateOf<List<RoutineBlock>?>(null) }
    var reviewRequestId by androidx.compose.runtime.saveable.rememberSaveable {mutableStateOf(java.util.UUID.randomUUID().toString())}
    var classicDrafts by remember {mutableStateOf<List<BoardClassicReview.Draft>>(emptyList())}
    var classicMode by remember {mutableStateOf(false)}
    var classicCatalog by remember {mutableStateOf<List<CatalogExercise>>(emptyList())}
    var reviewTitle by remember { mutableStateOf("Entreno de pizarra") }

    val subscriptions = LocalSubscriptions.current
    val sessionStore=remember(context) {SessionStore(context)}
    var mediaRevision by remember {mutableStateOf<String?>(null)}
    var mediaPending by remember {mutableStateOf(false)}
    fun consumeMediaRequest():Boolean {
        val valid=mediaPending && mediaRevision==sessionStore.identityRevision()
        mediaPending=false;mediaRevision=null
        return valid
    }
    fun markMediaRequest() {mediaRevision=sessionStore.identityRevision();mediaPending=true}

    fun process(uri: Uri) {
        if (reading) return
        // Id del intento: la cuota se consume una sola vez aunque el usuario
        // reintente la misma foto tras un fallo de OCR (idempotencia iOS).
        val attemptID = java.util.UUID.randomUUID().toString()
        if (subscriptions != null && !subscriptions.canStartBoardScan().allowed) {
            subscriptions.presentPaywall(
                dev.repera.domain.monetization.PaywallContext.BOARD_SCANS_LIMIT,
                feature = dev.repera.domain.monetization.ReperaFeature.UNLIMITED_BOARD_SCANS
            )
            return
        }
        reading = true
        errorMessage = null
        scope.launch {
            try {
                val text = BoardScanOcr.recognize(context, uri)
                val catalog = (overview?.exerciseEntries ?: catalogOverride)
                    .map {
                        CatalogExercise(it.id, it.name,
                            (SportExerciseNames.searchAliases(it.name) + it.searchAliases).distinct(),
                            it.isCustom, it.isCatalogArchived)
                    }
                val aliases = ExerciseSearchAssets.load(context)
                val proposal = withContext(Dispatchers.Default) {prepareBoardReview(text,catalog,aliases)}
                val parsed=proposal.lite
                val classic=proposal.classic
                if (parsed.blocks.isEmpty() && parsed.lines.isEmpty()) {
                    errorMessage = "No encontré texto útil. Prueba más cerca, más luz o otra foto."
                } else {
                    subscriptions?.consumeBoardScanIfNeeded(attemptID)
                    reviewRequestId=java.util.UUID.randomUUID().toString()
                    classicCatalog=catalog
                    classicDrafts=classic
                    classicMode=false
                    review = parsed.blocks
                }
            } catch(cancelled:kotlinx.coroutines.CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                errorMessage = error.localizedMessage ?: "No se pudo leer la foto"
            } finally {
                reading = false
            }
        }
    }

    val pickImage = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? -> if(consumeMediaRequest()) uri?.let(::process) }

    val photoUri = remember {
        val dir = File(context.cacheDir, "board_scan").apply { mkdirs() }
        FileProvider.getUriForFile(context, context.packageName + ".boardscan",
            File(dir, "captura.jpg"))
    }
    val takePicture = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { ok: Boolean -> val valid=consumeMediaRequest();if (ok && valid) process(photoUri) }

    val blocks = review
    LazyColumn(
        modifier = if (asSheet) {
            Modifier
                .fillMaxWidth()
                .heightIn(max = 640.dp)
        } else {
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
        },
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // R8 P1-10 / F4: sheet compacto (iOS BoardScanSourceSheet), sin página
        // explicativa «Fuentes» + Volver.
        item {
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Escanear pizarra", style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold)
                    Text("Cámara o galería", style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                ReperaToolbarGlassIconButton(
                    icon = Icons.Outlined.Close,
                    contentDescription = "Cerrar",
                    onClick = onBack
                )
            }
        }
        saveStatus?.let {message ->item {Text(message,color=MaterialTheme.colorScheme.error)}}
        if (blocks == null) {
            item {
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    Column {
                        PlanEditorActionRow(
                            icon = Icons.Outlined.PhotoCamera,
                            label = "Tomar foto",
                            onClick = { markMediaRequest(); takePicture.launch(photoUri) },
                            enabled = !busy && !reading && !mediaPending,
                            modifier = Modifier.fillMaxWidth()
                        )
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                        )
                        PlanEditorActionRow(
                            icon = Icons.Outlined.PhotoLibrary,
                            label = "Elegir de la galería",
                            onClick = { markMediaRequest(); pickImage.launch("image/*") },
                            enabled = !busy && !reading && !mediaPending,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
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
                item {
                    ReperaEmptyState(title = "No se pudo leer", subtitle = msg)
                }
            }
        } else {
            item {
                ReperaMetaTextField(
                    caption = "Título de la rutina",
                    value = reviewTitle,
                    onValueChange = { reviewTitle = it; reviewRequestId = java.util.UUID.randomUUID().toString() }
                )
            }
            item {
                if(classicDrafts.isNotEmpty()) OutlinedButton(onClick={classicMode=!classicMode;reviewRequestId=java.util.UUID.randomUUID().toString()},enabled=!busy) {
                    Text(if(classicMode) "Volver a lectura WOD" else "Revisar como fuerza clásica")
                }
                if(classicMode) {
                    BoardClassicReviewEditor(classicDrafts,busy) {index,draft ->
                        classicDrafts=classicDrafts.mapIndexed {i,old ->if(i==index) draft else old}
                        reviewRequestId=java.util.UUID.randomUUID().toString()
                    }
                    if(BoardClassicReview.blocks(classicDrafts,classicCatalog)==null)
                        Text("Revisa series (1-200), repeticiones (1-100000), carga y nombres del catálogo. Excluye las líneas que no quieras importar.")
                }
            }
            items(if(classicMode) 0 else blocks.size) { index ->
                val block = blocks[index]
                ReperaCard(modifier = Modifier.fillMaxWidth()) {
                    androidx.compose.foundation.layout.Column(Modifier.padding(16.dp),
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
                BoardScanReviewConfirm(reviewTitle,blocks,classicMode,classicDrafts,classicCatalog,
                    busy,reviewRequestId,onConfirm,onStart,onImportBlocks)
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
