package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import dev.repera.domain.BoardClassicReview

/** Explicit opt-in proposal. No write happens until the screen's Create action. */
@Composable internal fun BoardClassicReviewEditor(
 drafts:List<BoardClassicReview.Draft>,busy:Boolean,
 onChange:(Int,BoardClassicReview.Draft)->Unit
) {
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text("Revisar como fuerza clásica",style=MaterialTheme.typography.titleMedium)
  Text("Si no hay esquema, se proponen 3 series de 8 repeticiones. Revisa y cambia cada línea antes de crear. No modifica la lectura WOD original.")
  drafts.forEachIndexed {index,draft ->
   ReperaCard(Modifier.fillMaxWidth()) {Column(Modifier.padding(12.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) {
    Row {Checkbox(draft.included,{onChange(index,draft.copy(included=it))},enabled=!busy);Text(draft.line.raw)}
    OutlinedTextField(draft.name,{onChange(index,draft.copy(name=it))},label={Text("Ejercicio ${index+1}")},enabled=!busy,modifier=Modifier.fillMaxWidth())
    Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
     OutlinedTextField(draft.sets,{onChange(index,draft.copy(sets=it))},label={Text("Series ${index+1}")},enabled=!busy,modifier=Modifier.weight(1f))
     OutlinedTextField(draft.reps,{onChange(index,draft.copy(reps=it))},label={Text("Repeticiones ${index+1}")},enabled=!busy,modifier=Modifier.weight(1f))
    }
    OutlinedTextField(draft.load,{onChange(index,draft.copy(load=it))},label={Text("Carga propuesta ${index+1}")},supportingText={Text("Opcional. Se conserva el número de la pizarra, sin conversión automática de unidades.")},enabled=!busy,modifier=Modifier.fillMaxWidth())
   }}
  }
 }
}

@Composable internal fun BoardScanReviewConfirm(
 title:String,blocks:List<dev.repera.domain.RoutineBlock>,classicMode:Boolean,
 drafts:List<BoardClassicReview.Draft>,catalog:List<dev.repera.domain.CatalogExercise>,
 busy:Boolean,requestId:String,onConfirm:(String,List<dev.repera.domain.RoutineBlock>,String)->Unit,
 /** Paridad iOS Guardar+Empezar: crea y arranca sesión. */
 onStart:(String,List<dev.repera.domain.RoutineBlock>,String)->Unit = onConfirm
) {
 val selected=androidx.compose.runtime.remember(classicMode,drafts,catalog,blocks) {
  if(classicMode) BoardClassicReview.blocks(drafts,catalog) else blocks
 }
 val canAct=!busy && title.isNotBlank() && selected!=null && selected.isNotEmpty()
 Column(verticalArrangement=Arrangement.spacedBy(8.dp),modifier=Modifier.fillMaxWidth()) {
  Button(onClick={if(selected!=null) onConfirm(title,selected,requestId)},
   enabled=canAct,modifier=Modifier.fillMaxWidth(),
   colors=ButtonDefaults.buttonColors(containerColor=brandGreen,contentColor=androidx.compose.ui.graphics.Color.Black)) {Text("Crear rutina")}
  OutlinedButton(onClick={if(selected!=null) onStart(title,selected,requestId)},
   enabled=canAct,modifier=Modifier.fillMaxWidth().testTag("board_scan_start")) {Text("Empezar")}
 }
}

internal data class BoardReviewProposal(val lite:dev.repera.domain.BoardScanLiteParser.Output,val classic:List<BoardClassicReview.Draft>)
internal fun prepareBoardReview(text:String,catalog:List<dev.repera.domain.CatalogExercise>,aliases:Map<String,String>):BoardReviewProposal =
 BoardReviewProposal(dev.repera.domain.BoardScanLiteParser.parse(text,catalog,aliases),BoardClassicReview.drafts(text,catalog))
