package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.SortByAlpha
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.DirectionsRun
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import java.text.Collator
import java.util.Locale

/** Presentation order only. Stable filter values and matching remain unchanged. */
internal fun alphabeticExerciseFacets(filters:List<String>):List<String> {
    val collator=Collator.getInstance(Locale.forLanguageTag("es-ES"))
    return filters.distinct().sortedWith {a,b ->collator.compare(a,b)}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ExerciseFilterSheet(filters:List<String>,filter:String,sort:String,
    onFilter:(String)->Unit,onSort:(String)->Unit,onClose:()->Unit) {
    ReperaModalBottomSheet(onDismissRequest=onClose) {
        ExerciseFilterContent(filters,filter,sort,onFilter,onSort,onClose)
    }
}

@Composable
internal fun ExerciseFilterContent(filters:List<String>,filter:String,sort:String,
    onFilter:(String)->Unit,onSort:(String)->Unit,onClose:()->Unit) {
    Column(Modifier.fillMaxWidth().padding(horizontal=16.dp).verticalScroll(rememberScrollState()),
        verticalArrangement=Arrangement.spacedBy(18.dp)) {
        Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
            Text("Ordenar y filtrar",style=MaterialTheme.typography.headlineSmall,modifier=Modifier.weight(1f))
            IconButton(onClick=onClose) {Icon(Icons.Outlined.Close,"Cerrar filtros")}
        }
        ReperaSectionTitle("Ordenar")
        ReperaCard(Modifier.fillMaxWidth()) {
            listOf("Alfabético","Músculo","Material").forEach {mode ->
                val icon=when(mode) {
                    "Alfabético" -> Icons.Outlined.SortByAlpha
                    "Músculo" -> ExerciseCategorySymbols.muscle
                    else -> ExerciseCategorySymbols.equipment
                }
                ExerciseFacetRow(mode,icon,sort==mode) {onSort(mode)}
            }
        }
        ReperaSectionTitle("Filtrar")
        ReperaCard(Modifier.fillMaxWidth()) {
            alphabeticExerciseFacets(filters).forEach {value ->
                val selected=filter==value
                val icon=when(value) {
                    "Todos" -> Icons.Outlined.GridView
                    "Cardio" -> if(selected) Icons.Outlined.Favorite else Icons.Outlined.FavoriteBorder
                    "Favoritos" -> if(selected) Icons.Outlined.Star else Icons.Outlined.StarBorder
                    "WODs" -> Icons.Outlined.Timer
                    "Deportes" -> Icons.Outlined.DirectionsRun
                    else -> ExerciseCategorySymbols.discipline(value)
                }
                ExerciseFacetRow(value,icon,selected) {onFilter(value)}
            }
        }
        if(sort!="Alfabético" || filter!="Todos") TextButton(onClick={
            onSort("Alfabético");onFilter("Todos")
        }) {Text("Restablecer opciones")}
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun ExerciseFacetRow(title:String,icon:ImageVector,isSelected:Boolean,onClick:()->Unit) {
    TextButton(onClick=onClick,modifier=Modifier.fillMaxWidth().semantics {selected=isSelected},
        contentPadding=PaddingValues(horizontal=16.dp,vertical=12.dp),
        colors=ButtonDefaults.textButtonColors(contentColor=if(isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)) {
        Icon(icon,null,Modifier.size(22.dp))
        Text(title,modifier=Modifier.weight(1f).padding(horizontal=12.dp))
        if(isSelected) Text("✓",style=MaterialTheme.typography.titleMedium)
    }
}
