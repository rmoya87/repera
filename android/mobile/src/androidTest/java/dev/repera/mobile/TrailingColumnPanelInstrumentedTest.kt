package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test

class TrailingColumnPanelInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun overlayIsHalfWidthAndOnlyOutsideOrCloseDismisses() {
        var open by mutableStateOf(true)
        var action=0
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp).fillMaxHeight()) {
            Text("Inicio conservado")
            if(open) TrailingColumnPanel({open=false}) {TextButton(onClick={action++}) {Text("Acción Ajustes")}}
        }}}
        val outer=compose.onNodeWithTag("trailing_panel").fetchSemanticsNode().boundsInRoot
        val right=compose.onNodeWithTag("trailing_panel_content").fetchSemanticsNode().boundsInRoot
        assertEquals(outer.width/2,right.width,1f)
        assertEquals(outer.right,right.right,1f)
        compose.onNodeWithText("Acción Ajustes").performClick()
        compose.runOnIdle {assertTrue(open);assertEquals(1,action)}
        compose.onNodeWithTag("trailing_panel_scrim").performClick()
        compose.onNodeWithTag("trailing_panel").assertDoesNotExist()
        compose.onNodeWithText("Inicio conservado").assertExists()
        compose.runOnIdle {open=true}
        compose.onNodeWithTag("trailing_panel_close").performClick()
        compose.onNodeWithTag("trailing_panel").assertDoesNotExist()
    }

    @Test fun customCloseLabelIsShownAndCloses() {
        var open by mutableStateOf(true)
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp).fillMaxHeight()) {
            if(open) TrailingColumnPanel({open=false},closeLabel="‹ Cerrar rutina") {Text("Editor")}
        }}}
        compose.onNodeWithText("‹ Cerrar rutina").assertExists()
        compose.onNodeWithText("Editor").assertExists()
        compose.onNodeWithTag("trailing_panel_close").performClick()
        compose.onNodeWithTag("trailing_panel").assertDoesNotExist()
    }

    @Test fun exerciseDetailFavoriteStarTogglesAndIsHiddenWithoutHandler() {
        var entry by mutableStateOf(ExerciseEntry("ex1","Sentadilla",true,true))
        var withHandler by mutableStateOf(true)
        var toggles=0
        compose.setContent {MaterialTheme {
            ExerciseDetailScreen(entry,
                onToggleFavorite=if(withHandler) {{toggles++;entry=entry.copy(isFavorite=!entry.isFavorite)}} else null,
                onBack={})
        }}
        compose.onNodeWithTag("exercise_detail_favorite").assertExists()
        compose.onNodeWithContentDescription("Favorito").performClick()
        compose.runOnIdle {assertEquals(1,toggles);assertTrue(entry.isFavorite)}
        compose.onNodeWithContentDescription("Quitar de favoritos").assertExists()
        compose.runOnIdle {withHandler=false}
        compose.onNodeWithTag("exercise_detail_favorite").assertDoesNotExist()
    }
}
