package dev.repera.mobile

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test

class DiarySplitInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    private fun overview()=StateOverview(0,0,2,0,0,null,recentWorkoutTitles=emptyList(),history=emptyList(),
        routineEntries=listOf(RoutineEntry("template","Plantilla reutilizable",true),
            RoutineEntry("one-off","Entreno suelto oculto",true,scheduledDate="2026-10-26")),exerciseEntries=emptyList())
    @Test fun wideEditorStaysOnRightAndAccountChangeDiscardsSelection() {
        var account by mutableStateOf("fixture-a")
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp).fillMaxHeight()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview(),activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},onInitializeLocal={},onImportJson={},
                onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={},accountId=account,
                inlineRoutineEditor={routine,close ->Column {Text("Borrador: ${routine.title}");TextButton(onClick=close) {Text("Descartar")}}})
        }}}
        compose.onNodeWithTag("diary_split").assertExists()
        compose.onNodeWithText("Entreno suelto oculto").assertDoesNotExist()
        compose.onNodeWithTag("diary_routines_list").performScrollToNode(hasText("Contenido"))
        compose.onNodeWithText("Contenido").performClick()
        compose.onNodeWithTag("diary_schedule").assertExists()
        compose.onNodeWithText("Borrador: Plantilla reutilizable").assertExists()
        compose.runOnIdle {account="fixture-b"}
        compose.onNodeWithText("Borrador: Plantilla reutilizable").assertDoesNotExist()
    }
    @Test fun compactSwitchesBetweenPlanAndReusableTemplates() {
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(360.dp).fillMaxHeight()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview(),activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},onInitializeLocal={},onImportJson={},
                onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={})
        }}}
        compose.onNodeWithTag("diary_split").assertDoesNotExist()
        compose.onNodeWithText("Entreno suelto oculto").assertDoesNotExist()
        compose.onNodeWithText("Rutinas").performClick()
        compose.onNodeWithText("Plantilla reutilizable").assertExists()
        compose.onNodeWithText("Entreno suelto oculto").assertDoesNotExist()
    }
    @Test fun freeWeekdayPickerSelectsExistingReusableTemplate() {
        var chosen:Int?=null
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(360.dp).fillMaxHeight()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview(),activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,schedule ->chosen=schedule.weekday},onDeleteRoutine={},
                onInitializeLocal={},onImportJson={},onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={})
        }}}
        compose.onNodeWithTag("diary_assign_1").performScrollTo().performClick()
        compose.onNodeWithTag("diary_assign_template_template").performClick()
        compose.runOnIdle {org.junit.Assert.assertEquals(1,chosen)}
    }
    @Test fun newTemplateFromFreeDayIsUnsavedAccountBoundDraft() {
        var account by mutableStateOf("fixture-a")
        var draft:RoutineEntry?=null
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(800.dp).fillMaxHeight()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview(),activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},onInitializeLocal={},onImportJson={},
                onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={},accountId=account,
                newRoutineEditor={routine,close ->draft=routine;Column {Text("Nuevo borrador");TextButton(onClick=close) {Text("Descartar")}}})
        }}}
        compose.onNodeWithTag("diary_assign_1").performScrollTo().performClick()
        compose.onNodeWithTag("diary_create_for_day").performClick()
        compose.onNodeWithText("Nuevo borrador").assertExists()
        compose.onNodeWithTag("diary_schedule").assertExists()
        compose.runOnIdle {org.junit.Assert.assertEquals(1,draft?.weekday);account="fixture-b"}
        compose.onNodeWithText("Nuevo borrador").assertDoesNotExist()
    }
    @Test fun deniedNewTemplateDoesNotOpenDraft() {
        compose.setContent {MaterialTheme {Box(Modifier.requiredWidth(360.dp).fillMaxHeight()) {
            DiaryTab(busy=false,syncing=false,status=null,overview=overview(),activeWorkout=null,
                onStartRoutine={},onEditRoutine={_,_,_->},onDeleteRoutine={},onInitializeLocal={},onImportJson={},
                onDriveSync={},onExportJson={},onSignOut={},onNavigateHome={},canCreateTemplate={false},
                newRoutineEditor={_,_ ->Text("Nuevo borrador")})
        }}}
        compose.onNodeWithText("Rutinas").performClick()
        compose.onNodeWithTag("diary_new_template").performClick()
        compose.onNodeWithText("Nuevo borrador").assertDoesNotExist()
    }
}
