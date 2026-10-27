package dev.repera.mobile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import dev.repera.domain.CatalogWods

/** Library catalog and ephemeral play. History and visual fidelity remain separate work. */
@Composable
internal fun WodLibraryScreen(accountId:String,busy:Boolean,favorites:Set<String>,onToggle:(String)->Unit,onBack:()->Unit,onPlay:(String,String)->Unit = {_,_->},canPlay:Boolean=false,hasActiveSession:Boolean=false,activeRequestId:String?=null,history:Map<String,List<WodLibraryResult>> = emptyMap(),exercises:List<ExerciseEntry> = emptyList(),onExercise:(String)->Unit = {},exerciseDetail:(@Composable (ExerciseEntry,()->Unit)->Unit)? = null) {
    val context=androidx.compose.ui.platform.LocalContext.current
    val aliases=remember(context) {ExerciseSearchAssets.load(context)}
    var sort by rememberSaveable(accountId) {mutableStateOf("Alfabético")}
    var query by rememberSaveable(accountId) {mutableStateOf("")}
    var selectedId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    val playRequest=rememberSaveable(accountId,selectedId) {java.util.UUID.randomUUID().toString()}
    val subscriptions=dev.repera.mobile.monetization.LocalSubscriptions.current
    val selected=selectedId?.let {CatalogWods.template(it)}
    var selectedExerciseId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    val matches=CatalogWods.search(query).sortedWith(compareByDescending<dev.repera.domain.WodTemplate> {it.id in favorites}
        .thenComparator {a,b ->if(sort=="Músculo") LibraryCollator.compare(a.musclesLabel,b.musclesLabel) else 0}
        .thenComparator {a,b ->LibraryCollator.compare(a.name,b.name)})
    BoxWithConstraints(Modifier.fillMaxSize()) {
    val split=adaptiveCardColumns(maxWidth.value)==2 && selected==null && query.isNotBlank() && matches.isEmpty() && exerciseDetail!=null
    val back:()->Unit = {if(selectedId!=null) selectedId=null else if(split && selectedExerciseId!=null) selectedExerciseId=null else onBack()}
    androidx.activity.compose.BackHandler(onBack=back)
    val listContent:@Composable (Modifier)->Unit = {listModifier ->
    LazyColumn(contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp),modifier=listModifier.fillMaxSize()) {
        item {TextButton(onClick=back) {Text("Volver")}}
        if(selected!=null) {
            item {Text(selected.name,style=MaterialTheme.typography.headlineMedium)}
            item {TextButton(enabled=!busy,onClick={onToggle(selected.id)},modifier=Modifier.testTag("wod_toggle_favorite")) {
                Text(if(selected.id in favorites) "Quitar de favoritos" else "Favorito")}}
            item {
                Text("Formato: ${selected.formatLabel}")
                selected.timeCapMinutes?.let {Text("Time cap: $it min")}
                selected.typicalLabel?.let {Text("Tiempo típico: $it")}
                Text("Músculos: ${selected.musclesLabel}")
                selected.notes?.takeIf {it.isNotBlank()}?.let {Text(it)}
            }
            if(canPlay) item {Button(enabled=!busy && (!hasActiveSession || activeRequestId==playRequest),onClick={onPlay(selected.id,playRequest)},modifier=Modifier.testTag("wod_play_now")) {Text("Empezar ahora")}}
            val scores=history[selected.id].orEmpty()
            val allowed=subscriptions?.isPro ?: false
            val visible=WodLibraryHistory.visible(scores,allowed)
            if(scores.isNotEmpty()) {
                item {Text("Tu progresión",style=MaterialTheme.typography.titleLarge)}
                items(visible) {result ->Text(result.summary,modifier=Modifier.testTag("wod_result_${result.id}"))}
                if(!allowed && scores.size>visible.size) item {TextButton(onClick={subscriptions?.presentPaywall(
                    dev.repera.domain.monetization.PaywallContext.WOD_HISTORY,
                    feature=dev.repera.domain.monetization.ReperaFeature.HISTORICAL_WOD_RESULTS)}) {Text("Supera tus marcas · ver historial completo")}}
            }
            item {Text("Movimientos",style=MaterialTheme.typography.titleLarge)}
            items(selected.movements) {move ->
                val exercise=remember(move.name,exercises) {resolveWodExercise(move.name,exercises,aliases)}
                Row(horizontalArrangement=Arrangement.spacedBy(12.dp)) {
                WodExerciseThumbnail(exercise,aliases)
                Column {
                Text(exercise.displayName,style=MaterialTheme.typography.titleMedium)
                Text(listOfNotNull(move.reps?.let {"$it rep"},move.distanceMeters?.let {"$it m"},move.calories?.let {"$it cal"},
                    move.weightMaleKg?.let {"H: $it kg"},move.weightFemaleKg?.let {"M: $it kg"},move.notes).joinToString(" · "))
            }}}

        } else {
            item {Text("WODs",style=MaterialTheme.typography.headlineMedium)}
            item {OutlinedTextField(value=query,onValueChange={query=it},label={Text("Nombre o formato")},modifier=Modifier.fillMaxWidth())}
            item {Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                listOf("Alfabético","Músculo").forEach {mode ->FilterChip(selected=sort==mode,onClick={sort=mode},label={Text(mode)})}
            }}
            if(matches.isEmpty() && query.isNotBlank()) {
                val fallback=exercises.map {it to dev.repera.domain.ExerciseAliasSearch.score(query,it.name,aliases,it.disciplineTags.joinToString(" "))}
                    .filter {it.second>=0}.sortedByDescending {it.second}.map {it.first}
                item {Text("Ejercicios",style=MaterialTheme.typography.titleLarge)}
                if(fallback.isEmpty()) item {Text("Sin ejercicios coincidentes")}
                items(fallback,key={"exercise-${it.id}"}) {exercise ->
                    TextButton(onClick={if(split) selectedExerciseId=exercise.id else onExercise(exercise.id)},modifier=Modifier.testTag("wod_fallback_${exercise.id}")) {Text(exercise.displayName)}
                }
            } else if(matches.isEmpty()) item {Text("Sin WODs coincidentes")}
            items(matches,key={it.id}) {template ->Card(Modifier.fillMaxWidth().testTag("wod_catalog_${template.id}").clickable {selectedId=template.id}) {
                Column(Modifier.padding(16.dp)) {
                    Text(template.name+if(template.id in favorites) " ★" else "",style=MaterialTheme.typography.titleMedium)
                    Text(template.formatLabel);Text(template.musclesLabel)
                    template.typicalLabel?.let {Text(it)}
                    history[template.id]?.firstOrNull()?.let {Text(it.summary)}
                }
            }}
        }
    }
    }
    if(split) Row(Modifier.fillMaxSize().testTag("wod_fallback_split"),horizontalArrangement=Arrangement.spacedBy(12.dp)) {
        Box(Modifier.weight(1f).testTag("wod_fallback_selector")) {listContent(Modifier)}
        Box(Modifier.weight(1f).testTag("wod_fallback_detail")) {
            val exercise=exercises.firstOrNull {it.id==selectedExerciseId}
            if(exercise==null) Column(Modifier.fillMaxWidth().padding(24.dp)) {
                Text("Selecciona ejercicio",style=MaterialTheme.typography.titleLarge)
                Text("Elige un ejercicio de la lista para ver sus datos, instrucciones y progreso.")
            } else key(exercise.id) {exerciseDetail?.invoke(exercise) {selectedExerciseId=null}}
        }
    } else listContent(Modifier)
    }
}
