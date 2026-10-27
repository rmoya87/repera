package dev.repera.mobile

import androidx.compose.ui.Alignment
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.animation.animateContentSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.TrendingUp
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.key
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import dev.repera.domain.ExerciseAliasSearch
import dev.repera.domain.WodFormat
import dev.repera.domain.WodClock
import dev.repera.domain.WodClockSpec
import java.time.LocalDate
import java.time.LocalTime
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.LaunchedEffect
import kotlinx.coroutines.delay


@Composable
internal fun DiaryTab(
    aiPrograms: List<AITrainingProgramsStore.Program> = emptyList(),
    onOpenAIPrograms: () -> Unit = {},
    busy: Boolean,
    syncing: Boolean,
    status: String?,
    overview: StateOverview?,
    activeWorkout: ActiveWorkout?,
    onStartRoutine: (String) -> Unit,
    onEditRoutine: (String, String, RoutineSchedule) -> Unit,
    onDeleteRoutine: (String) -> Unit,
    onCopyPreviousWeek: (java.time.LocalDate) -> Unit = {},
    onAssignRoutineToDate: (String, java.time.LocalDate) -> Unit = { _, _ -> },
    onRemoveScheduledRoutine: (String) -> Unit = {},
    onClearWeeklySchedule: (java.time.LocalDate) -> Unit = {},
    onEditRoutineContent: (String) -> Unit = {},
    onSetRoutineProgression: (String, String) -> Unit = { _, _ -> },
    onSetRoutineFavorite: (String, Boolean) -> Unit = { _, _ -> },
    onInitializeLocal: () -> Unit,
    onImportJson: () -> Unit,
    onDriveSync: () -> Unit,
    onExportJson: () -> Unit,
    onSignOut: () -> Unit,
    onNavigateHome: () -> Unit,
    onDayPlusCreate: (String, String) -> Unit = { _, _ -> },
    onDayPlusFavorites: () -> Unit = {},
    onDayPlusTimer: () -> Unit = {},
    onDayPlusScan: () -> Unit = {},
    professionalSessions:List<BusinessCenterStore.ProfessionalSession> = emptyList(),
    centerName:(String)->String = {"Centro"},
    modifier: Modifier = Modifier,
    accountId:String = "",
    inlineRoutineEditor:(@Composable (RoutineEntry,()->Unit)->Unit)? = null,
    canCreateTemplate:()->Boolean = {true},
    newRoutineEditor:(@Composable (RoutineEntry,()->Unit)->Unit)? = null
) {
    var diaryDateIso by rememberSaveable(accountId) { mutableStateOf(LocalDate.now().toString()) }
    var showScheduleMenu by remember(accountId) { mutableStateOf(false) }
    var confirmClearSchedule by remember(accountId) { mutableStateOf(false) }
    var showDayPlus by rememberSaveable(accountId) { mutableStateOf(false) }
    val routines = overview?.routineEntries.orEmpty()
    val day = LocalDate.parse(diaryDateIso)
    val weekly = DiaryCatalog.weekly(routines)
    val library = DiaryCatalog.library(routines)
    var section by rememberSaveable(accountId) {mutableStateOf("Programado")}
    var editingId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    var assigningDay by rememberSaveable(accountId) {mutableStateOf<Int?>(null)}
    var assigningDate by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    val weekStart = day.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
    var newId by rememberSaveable(accountId) {mutableStateOf<String?>(null)}
    var newWeekday by rememberSaveable(accountId) {mutableStateOf<Int?>(null)}
    fun openNew(weekday:Int?) {
        if(newRoutineEditor!=null && canCreateTemplate()) {
            editingId=null;newWeekday=weekday;newId=java.util.UUID.randomUUID().toString()
        }
    }
    androidx.activity.compose.BackHandler(enabled=newId!=null) {if(!busy) {newId=null;newWeekday=null}}
    val newDraft=newId?.let {id ->RoutineEntry(id,
        newWeekday?.let {java.time.DayOfWeek.of(it).getDisplayName(java.time.format.TextStyle.FULL,java.util.Locale("es"))} ?: "Nueva rutina",
        true,weekday=newWeekday)}
    val content: @Composable (Boolean,Boolean,(String)->Unit)->Unit = {showSchedule,showRoutines,openEditor ->
        LazyColumn(Modifier.fillMaxSize().testTag(if(showSchedule) "diary_schedule_list" else "diary_routines_list"),contentPadding=PaddingValues(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        // Programas IA (paridad PlanView iOS): entrada cuando el asistente ha
        // propuesto algún programa mult semana.
        if (showSchedule && aiPrograms.isNotEmpty()) {
            items(aiPrograms, key = { "programa-" + it.id }) { program ->
                Card(modifier = Modifier.fillMaxWidth()
                    .clickable(onClick = onOpenAIPrograms)) {
                    Row(modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(program.title,
                                style = MaterialTheme.typography.titleSmall)
                            Text("${program.durationWeeks} semanas · " +
                                program.startDate + " · " + program.statusLabel,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme
                                    .onSurfaceVariant)
                        }
                    }
                }
            }
        }
        if(showSchedule) {
            item { WeekCalendarStrip(day,overview?.trainingSettings?.weekStartsOnMonday ?: true,returnToDay=java.time.LocalDate.now()) { chosen -> diaryDateIso = chosen.toString() } }
            item { Text("Tu programación",style=MaterialTheme.typography.titleLarge) }
            for(weekday in 1..7) {
                val routine=weekly.firstOrNull {it.weekday==weekday}
                item(key="weekday-$weekday") {
                    Text(java.time.DayOfWeek.of(weekday).getDisplayName(java.time.format.TextStyle.FULL,java.util.Locale("es")),
                        style=MaterialTheme.typography.titleMedium)
                    if(routine==null) TextButton(onClick={assigningDay=weekday},enabled=!busy,
                        modifier=Modifier.testTag("diary_assign_$weekday")) {Text("Día libre · toca para asignar")}
                    else Column {
                        ScheduledRoutineCard(routine,busy,activeWorkout==null,
                            onStart={onStartRoutine(it);onNavigateHome()},onEdit=onEditRoutine,onDelete=onDeleteRoutine,
                            onEditContent=openEditor,onSetProgression=onSetRoutineProgression,onSetFavorite=onSetRoutineFavorite)
                        TextButton(enabled=!busy,modifier=Modifier.testTag("diary_unassign_$weekday"),
                            onClick={onEditRoutine(routine.id,routine.title,RoutineSchedule(timeMinutes=routine.timeMinutes))}) {
                            Text("Quitar del día")
                        }
                    }
                    // Independent dated sessions of this date (Apple scheduledRoutines(on:)); they never touch the weekday routine.
                    val date=weekStart.plusDays((weekday-1).toLong())
                    DiaryCatalog.datedOn(routines,date).forEach {dated ->
                        Column(Modifier.testTag("diary_dated_${dated.id}")) {
                            ScheduledRoutineCard(dated,busy,activeWorkout==null,
                                onStart={onStartRoutine(it);onNavigateHome()},onEdit=onEditRoutine,onDelete=onDeleteRoutine,
                                onEditContent=openEditor,onSetProgression=onSetRoutineProgression,onSetFavorite=onSetRoutineFavorite)
                            TextButton(enabled=!busy,onClick={onRemoveScheduledRoutine(dated.id)}) {Text("Quitar de $date")}
                        }
                    }
                    TextButton(enabled=!busy,modifier=Modifier.testTag("diary_add_dated_$weekday"),
                        onClick={assigningDate=date.toString()}) {Text("＋ Añadir otro entreno el $date")}
                }
            }
            items(professionalSessions,key={"professional-${it.id}"}) {session -> ProfessionalSessionCard(session,centerName(session.orgId),false)}
        }
        if(showRoutines) {
            item {Text("Rutinas",style=MaterialTheme.typography.titleLarge)}
            if(newRoutineEditor!=null) item {
                Button(onClick={openNew(null)},enabled=!busy,modifier=Modifier.fillMaxWidth().testTag("diary_new_template")) {Text("Nueva rutina")}
            }
            if(library.isEmpty()) item {
                Text("Sin rutinas")
                Text("Crea plantillas reutilizables y asígnalas en Programado.")
            }
            items(library,key={"library-${it.id}"}) {routine ->
                ScheduledRoutineCard(routine,busy,activeWorkout==null,
                    onStart={onStartRoutine(it);onNavigateHome()},onEdit=onEditRoutine,onDelete=onDeleteRoutine,
                    onEditContent=openEditor,onSetProgression=onSetRoutineProgression,onSetFavorite=onSetRoutineFavorite)
            }
        }
        item { OverviewEmptyActions(overview, busy, onInitializeLocal, onImportJson) }
        item {
            AccountSyncCard(busy, syncing, status, overview, onDriveSync, onExportJson, onSignOut)
        }
    }
    }
    BoxWithConstraints(modifier.fillMaxSize()) {
        val expanded=adaptiveCardColumns(maxWidth.value)==2
        LaunchedEffect(expanded) {if(!expanded) editingId=null}
        Column(Modifier.fillMaxSize()) {
        Box {
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal=16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically) {
                Text("Diario", style = MaterialTheme.typography.headlineMedium)
                androidx.compose.foundation.layout.Box {
                    TextButton(onClick = { showScheduleMenu = true }, enabled = !busy,
                        modifier = Modifier.testTag("diary_schedule_menu")) { Text("Opciones") }
                    androidx.compose.material3.DropdownMenu(expanded = showScheduleMenu,
                        onDismissRequest = { showScheduleMenu = false }) {
                        androidx.compose.material3.DropdownMenuItem(text = { Text("Copiar semana anterior") },
                            onClick = { showScheduleMenu = false; onCopyPreviousWeek(day) })
                        if (weekly.isNotEmpty() || routines.any { r -> r.scheduledDate?.let { s -> runCatching { java.time.LocalDate.parse(s.take(10)) }.getOrNull() }?.let { d -> d.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY)) == day.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY)) } == true }) androidx.compose.material3.DropdownMenuItem(
                            text = { Text("Vaciar programación") },
                            onClick = { showScheduleMenu = false; confirmClearSchedule = true })
                    }
                }
                // Menú «＋» del día seleccionado (paridad DayPlusSheet iOS).
                TextButton(onClick = { showDayPlus = true },
                    modifier = Modifier.testTag("day_plus_open")) {
                    Text("＋ Añadir")
                }
            }
        }

            if(expanded) Row(Modifier.weight(1f).fillMaxWidth().testTag("diary_split"),horizontalArrangement=Arrangement.spacedBy(12.dp)) {
                Box(Modifier.weight(1f).testTag("diary_schedule")) {content(true,false,onEditRoutineContent)}
                Box(Modifier.weight(1f).testTag("diary_routines")) {
                    val editing=library.firstOrNull {it.id==editingId}
                    if(newDraft!=null && newRoutineEditor!=null) key(accountId,newDraft.id) {
                        newRoutineEditor(newDraft) {newId=null;newWeekday=null}
                    } else if(editing!=null && inlineRoutineEditor!=null) key(accountId,editing.id) {
                        inlineRoutineEditor(editing) {editingId=null}
                    } else content(false,true) {id -> if(inlineRoutineEditor!=null) editingId=id else onEditRoutineContent(id)}
                }
            } else {
                if(newDraft!=null && newRoutineEditor!=null) key(accountId,newDraft.id) {
                    newRoutineEditor(newDraft) {newId=null;newWeekday=null}
                } else Column(Modifier.weight(1f)) {
                Row(horizontalArrangement=Arrangement.spacedBy(8.dp),modifier=Modifier.padding(horizontal=16.dp)) {
                    listOf("Programado","Rutinas").forEach {label ->FilterChip(selected=section==label,onClick={section=label},label={Text(label)})}
                }
                Box(Modifier.weight(1f)) {content(section=="Programado",section=="Rutinas",onEditRoutineContent)}
                }
            }
        }
    }
    assigningDay?.let {weekday ->
        androidx.compose.material3.AlertDialog(onDismissRequest={assigningDay=null},
            title={Text(java.time.DayOfWeek.of(weekday).getDisplayName(java.time.format.TextStyle.FULL,java.util.Locale("es")))},
            text={LazyColumn(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                if(newRoutineEditor!=null) item {TextButton(enabled=!busy,modifier=Modifier.testTag("diary_create_for_day"),
                    onClick={assigningDay=null;openNew(weekday)}) {Text("Crear nueva rutina")}}
                if(library.isEmpty()) item {Text("Sin rutinas guardadas. Crea una plantilla en Rutinas.")}
                items(library,key={it.id}) {routine ->TextButton(enabled=!busy,
                    modifier=Modifier.testTag("diary_assign_template_${routine.id}"),
                    onClick={onEditRoutine(routine.id,routine.title,RoutineSchedule(weekday=weekday,timeMinutes=routine.timeMinutes));assigningDay=null}) {Text(routine.title)}}
            }},confirmButton={TextButton(onClick={assigningDay=null}) {Text("Cerrar")}})
    }
    assigningDate?.let {iso ->
        androidx.compose.material3.AlertDialog(onDismissRequest={assigningDate=null},
            title={Text("Añadir entreno el $iso")},
            text={LazyColumn(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                if(library.isEmpty()) item {Text("Sin rutinas guardadas. Crea una plantilla en Rutinas.")}
                items(library,key={it.id}) {routine ->TextButton(enabled=!busy,
                    modifier=Modifier.testTag("diary_assign_date_${routine.id}"),
                    onClick={onAssignRoutineToDate(routine.id,LocalDate.parse(iso));assigningDate=null}) {Text(routine.title)}}
            }},confirmButton={TextButton(onClick={assigningDate=null}) {Text("Cerrar")}})
    }
    if (confirmClearSchedule) androidx.compose.material3.AlertDialog(
        onDismissRequest = { confirmClearSchedule = false },
        title = { Text("¿Vaciar programación?") },
        text = { Text("Se quitan las rutinas fechadas de la semana seleccionada (las favoritas se conservan sin fecha) y el plan semanal recurrente. Las plantillas en Rutinas se conservan. Los entrenos ya registrados se mantienen.") },
        confirmButton = { TextButton(onClick = { confirmClearSchedule = false; onClearWeeklySchedule(day) }, enabled = !busy) { Text("Vaciar") } },
        dismissButton = { TextButton(onClick = { confirmClearSchedule = false }) { Text("Cancelar") } })
    if (showDayPlus) {
        val dayName = day.dayOfWeek.getDisplayName(java.time.format.TextStyle.FULL,
            java.util.Locale("es")).replaceFirstChar { it.uppercase() }
        DayPlusSheet(
            dayName = dayName,
            favoriteRoutines = routines.count { it.isFavorite },
            favoriteTimers = overview?.favoriteTimerCount ?: 0,
            onCreateWorkout = { showDayPlus = false; onDayPlusCreate(diaryDateIso, dayName) },
            onOpenFavorites = { showDayPlus = false; onDayPlusFavorites() },
            onOpenTimer = { showDayPlus = false; onDayPlusTimer() },
            onScanBoard = { showDayPlus = false; onDayPlusScan() },
            onDismiss = { showDayPlus = false })
    }
}
