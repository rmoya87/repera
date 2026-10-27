package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Synthetic catalog only. Wide behavior must also be checked on real tablet pixels. */
class LibrarySplitInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private val entry=ExerciseEntry("split-example","Ejercicio de prueba",true,true)
    private fun catalog()=StateOverview(0,0,0,1,0,null,recentWorkoutTitles=emptyList(),
        history=emptyList(),routineEntries=emptyList(),exerciseEntries=listOf(entry))
    @Test fun wideSelectStaysInlineAndClearsWhenAccountChanges() {
        var account by mutableStateOf("fixture-a")
        var navigations=0
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp).fillMaxHeight()) {
            ExercisesTab(false,false,null,catalog(),null,{},onOpenExercise={navigations++},
                onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={},
                onNavigateHome={},accountId=account)
        }}}
        compose.onNodeWithTag("library_split").assertExists()
        compose.onNodeWithTag("library_detail").assert(hasAnyDescendant(hasText("Selecciona ejercicio")))
        compose.onNodeWithTag("library_exercise_${entry.id}").performScrollTo().performClick().assertIsSelected()
        compose.onNodeWithTag("library_detail").assert(hasAnyDescendant(hasText(entry.displayName)))
        compose.runOnIdle {assertEquals(0,navigations);account="fixture-b"}
        compose.onNodeWithText("Selecciona ejercicio").assertExists()
    }
    @Test fun compactRetainsNavigationInsteadOfHiddenDetail() {
        var opened:String?=null
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(360.dp).fillMaxHeight()) {
            ExercisesTab(false,false,null,catalog(),null,{},onOpenExercise={opened=it},
                onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={})
        }}}
        compose.onNodeWithTag("library_split").assertDoesNotExist()
        compose.onNodeWithTag("library_exercise_${entry.id}").performScrollTo().performClick()
        compose.runOnIdle {assertEquals(entry.id,opened)}
    }
}
