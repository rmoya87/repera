package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/**
 * Atomicidad, cuota y copias con ids nuevos de los flujos de borrador (sesión desde borrador, plan con custom
 * diferido, favorito al editar entreno terminado). Almacenamiento temporal por usuario aleatorio: nunca datos reales.
 * COMPILADO, no ejecutado (CI bloqueado y sin dispositivo).
 */
@RunWith(AndroidJUnit4::class)
class DraftSessionRepositoryInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val press = JSONObject().put("id", UUID.randomUUID().toString())
            .put("name", "Press banca").put("muscleGroup", "Pecho").put("equipment", "Barra")
        val state = JSONObject().put("exercises", JSONArray().put(press))
            .put("routines", JSONArray()).put("workouts", JSONArray()).put("syncRevision", 0)
            .put("settings", JSONObject().put("defaultProgression", "off"))
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }
    private fun state(local: LocalSnapshotStore) = JSONObject(String(local.read()!!))
    private fun exId(local: LocalSnapshotStore) = state(local).getJSONArray("exercises").getJSONObject(0).getString("id")
    private fun draft(vararg ids: String) = listOf(RoutineBlockDraft(format = "strength",
        entries = ids.map { RoutineDraftEntry(exerciseId = it, quantity = 5, sets = 2, weightKg = 40.0) }))

    @Test fun sessionWithoutFavoritePersistsNoRoutine() {
        val (repo, local) = repo()
        repo.startSessionFromDrafts("", draft(exId(local)), saveAsFavorite = false)
        val st = state(local)
        assertEquals(0, st.getJSONArray("routines").length())
        assertEquals("Mi entreno", st.getJSONObject("activeSession").getString("title"))
    }

    @Test fun sessionWithFavoriteSavesOneFavoriteRoutineWithProgressionOff() {
        val (repo, local) = repo()
        repo.startSessionFromDrafts("Mío", draft(exId(local)), saveAsFavorite = true)
        val routines = state(local).getJSONArray("routines")
        assertEquals(1, routines.length())
        assertTrue(routines.getJSONObject(0).getBoolean("isFavorite"))
        assertEquals("off", routines.getJSONObject(0).getString("progression"))
    }

    @Test fun deniedCustomQuotaLeavesNothingBehind() {
        val (repo, local) = repo()
        val before = String(local.read()!!)
        assertThrows(IllegalStateException::class.java) {
            repo.startSessionFromDrafts("X", draft("pending:Nuevo A", "pending:Nuevo B"), true) { false }
        }
        assertEquals(before, String(local.read()!!))
    }

    @Test fun invalidBlockAfterPendingCustomDoesNotLeakCatalogEntry() {
        val (repo, local) = repo()
        val id = exId(local)
        val rid = repo.createRoutine("R", "strength", listOf(RoutineDraftEntry(id, 5)))
        val before = String(local.read()!!)
        val bad = listOf(RoutineBlockDraft(format = "strength", timeCapMinutes = 0,
            entries = listOf(RoutineDraftEntry("pending:Nuevo", 5))))
        assertThrows(IllegalArgumentException::class.java) { repo.replaceRoutineBlocks(rid, bad) }
        assertEquals(before, String(local.read()!!))
    }

    @Test fun sameNormalizedNamesCreateOneCustomAndRetryDoesNotDuplicate() {
        val (repo, local) = repo()
        val rid = repo.createRoutine("R", "strength", listOf(RoutineDraftEntry(exId(local), 5)))
        val d = draft("pending:Remo Pendlay", "pending:remo pendlay ")
        // Mismo nombre normalizado en el mismo bloque estrength: el validador rechaza el duplicado; sin escribir.
        assertThrows(IllegalArgumentException::class.java) { repo.replaceRoutineBlocks(rid, d) }
        val one = draft("pending:Remo Pendlay")
        repo.replaceRoutineBlocks(rid, one); repo.replaceRoutineBlocks(rid, one)
        val customs = (0 until state(local).getJSONArray("exercises").length()).count {
            state(local).getJSONArray("exercises").getJSONObject(it).optBoolean("isCustom") }
        assertEquals(1, customs)
    }

    @Test fun finishedEditSaveAsFavoriteCopiesBlocksWithFreshIds() {
        val (repo, local) = repo()
        val exerciseId = exId(local)
        repo.startQuickLog(exerciseId); repo.logCurrentSet(10, 60.0); repo.finish()
        val w = state(local).getJSONArray("workouts").getJSONObject(0)
        repo.updateFinishedWorkout(w.getString("id"), WorkoutRepository.FinishedWorkoutEdit(
            title = "Hecho", startedAtIso = null, finishedAtIso = null, notes = null, pinEdited = false, pin = null,
            saveAsFavorite = true))
        val st = state(local)
        val fav = st.getJSONArray("routines").getJSONObject(0)
        assertTrue(fav.getBoolean("isFavorite"))
        val workoutBlockIds = (0 until (st.getJSONArray("workouts").getJSONObject(0).optJSONArray("routineBlocks")?.length() ?: 0)).map {
            st.getJSONArray("workouts").getJSONObject(0).getJSONArray("routineBlocks").getJSONObject(it).getString("id") }
        val favIds = (0 until fav.getJSONArray("blocks").length()).map { fav.getJSONArray("blocks").getJSONObject(it).getString("id") }
        assertTrue(favIds.none { it in workoutBlockIds })
    }
    @Test fun suggestedTemplateTitleAndContentCommitTogetherOrNeither() {
        val (repo,local)=repo()
        val rid=repo.createRoutine("Entreno","strength",listOf(RoutineDraftEntry(exId(local),5)))
        repo.replaceRoutineBlocks(rid,draft(exId(local)),suggestedTitle="Plantilla elegida")
        assertEquals("Plantilla elegida",state(local).getJSONArray("routines").getJSONObject(0).getString("title"))
        val before=local.read()!!
        assertThrows(IllegalArgumentException::class.java) {
            repo.replaceRoutineBlocks(rid,draft(exId(local)),suggestedTitle=" ")
        }
        assertArrayEquals(before,local.read())
    }
    @Test fun oneOffRetryWithSameDraftIdDoesNotDuplicateOrOverwriteCommittedEdits() {
        val (repo,local)=repo()
        val request="fixture-oneoff-request"
        repo.createRoutineFromDrafts("Original",draft(exId(local)),RoutineSchedule(scheduledDate="2026-10-26"),routineId=request)
        repo.updateRoutineDetails(request,"Edición posterior",RoutineSchedule(scheduledDate="2026-10-27"))
        val before=local.read()!!
        repo.createRoutineFromDrafts("Original",draft(exId(local)),RoutineSchedule(scheduledDate="2026-10-26"),routineId=request)
        assertArrayEquals(before,local.read())
        assertEquals(1,state(local).getJSONArray("routines").length())
    }
    @Test fun sameSessionDraftRequestReturnsActiveWithoutDuplicateFavorite() {
        val (repo,local)=repo()
        val entries=draft(exId(local))
        val first=repo.startSessionFromDrafts("Mi entreno",entries,true,requestId="session-request")
        val before=local.read()!!
        val again=repo.startSessionFromDrafts("Mi entreno",entries,true,requestId="session-request")
        assertEquals(first.id,again.id)
        assertArrayEquals(before,local.read())
        assertEquals(1,state(local).getJSONArray("routines").length())
        repo.finish()
        val finished=local.read()!!
        assertThrows(IllegalStateException::class.java) {
            repo.startSessionFromDrafts("Mi entreno",entries,true,requestId="session-request")
        }
        assertArrayEquals(finished,local.read())
    }
    @Test fun newWeeklyTemplatePersistsOnceAndUnassignsPreviousWithoutDeletingIt() {
        val (repo,local)=repo()
        val exercise=exId(local)
        val previous=repo.createRoutineFromDrafts("Anterior",draft(exercise),RoutineSchedule(weekday=1))
        val request=UUID.randomUUID().toString()
        repo.createRoutineFromDrafts("Nueva rutina",draft(exercise),RoutineSchedule(weekday=1),routineId=request)
        repo.createRoutineFromDrafts("No sobrescribir",draft(exercise),RoutineSchedule(weekday=2),routineId=request)
        val routines=state(local).getJSONArray("routines")
        assertEquals(2,routines.length())
        val all=(0 until routines.length()).map {routines.getJSONObject(it)}
        assertFalse(all.first {it.getString("id")==previous}.has("weekday"))
        val created=all.first {it.getString("id")==request}
        assertEquals(1,created.getInt("weekday"))
        assertEquals("Nueva rutina",created.getString("title"))
        assertFalse(created.has("scheduledDate"))
    }
    @Test fun favoriteQuotaIsCheckedBeforeMaterializationButNotForAnExistingDraftRequest() {
        val (repo,local)=repo()
        val entries=draft(exId(local))
        val before=local.read()!!
        var observedCount:Int?=null
        assertThrows(IllegalStateException::class.java) {
            repo.startSessionFromDrafts("No",draft("pending:No debe crearse"),true,
                requestId="denied",canSaveFavorite={count ->observedCount=count;false})
        }
        assertEquals(0,observedCount)
        assertArrayEquals(before,local.read())
        val first=repo.startSessionFromDrafts("Sí",entries,true,requestId="same",canSaveFavorite={true})
        val committed=local.read()!!
        val again=repo.startSessionFromDrafts("No cambiar",entries,true,requestId="same",
            canSaveFavorite={error("A retry must not consume a new favorite slot")})
        assertEquals(first.id,again.id)
        assertEquals("same",again.draftRequestId)
        assertArrayEquals(committed,local.read())
    }
    @Test fun nonFavoriteSessionDoesNotRequireTemplateQuota() {
        val (repo,local)=repo()
        repo.startSessionFromDrafts("Libre",draft(exId(local)),false,
            canSaveFavorite={error("No new template requested")})
        assertEquals(0,state(local).getJSONArray("routines").length())
    }
    @Test fun templateQuotaUsesLoadedCountSkipsOneOffAndAllowsExactRetry() {
        val (repo,local)=repo()
        val entries=draft(exId(local))
        repo.createRoutineFromDrafts("Suelto",entries,RoutineSchedule(scheduledDate="2026-10-26"),
            canCreateTemplate={error("Dated routines do not need a template slot")})
        repo.createRoutineFromDrafts("Semanal",entries,RoutineSchedule(weekday=1),routineId="weekly")
        val before=local.read()!!
        var count:Int?=null
        assertThrows(IllegalStateException::class.java) {
            repo.createRoutineFromDrafts("No",draft("pending:No crear"),canCreateTemplate={count=it;false})
        }
        assertEquals(1,count)
        assertArrayEquals(before,local.read())
        repo.createRoutineFromDrafts("No cambiar",entries,routineId="weekly",
            canCreateTemplate={error("Retry is not a new template")})
        assertArrayEquals(before,local.read())
        assertThrows(IllegalStateException::class.java) {
            repo.createRoutineFromScan("No",emptyList(),canCreateTemplate={false})
        }
        assertArrayEquals(before,local.read())
    }
    @Test fun simpleWodAndHistoryFavoriteDenyWithoutChangingSnapshot() {
        val (repo,local)=repo()
        val exercise=exId(local)
        val initial=local.read()!!
        assertThrows(IllegalStateException::class.java) {
            repo.createRoutine("No","strength",listOf(RoutineDraftEntry(exercise,5)),canCreateTemplate={false})
        }
        assertThrows(IllegalStateException::class.java) {
            repo.createWodRoutine(dev.repera.domain.CatalogWods.template("cindy")!!,canCreateTemplate={false})
        }
        assertArrayEquals(initial,local.read())
        repo.startQuickLog(exercise);repo.logCurrentSet(5,40.0);repo.finish()
        val workout=state(local).getJSONArray("workouts").getJSONObject(0).getString("id")
        val before=local.read()!!
        assertThrows(IllegalStateException::class.java) {
            repo.updateFinishedWorkout(workout,WorkoutRepository.FinishedWorkoutEdit(
                title="No editar",startedAtIso=null,finishedAtIso=null,notes="No guardar",
                pinEdited=false,pin=null,saveAsFavorite=true),canSaveFavorite={false})
        }
        assertArrayEquals(before,local.read())
        repo.updateFinishedWorkout(workout,WorkoutRepository.FinishedWorkoutEdit(
            title="Editar sin favorito",startedAtIso=null,finishedAtIso=null,notes=null,
            pinEdited=false,pin=null),canSaveFavorite={error("No template requested")})
        assertEquals(0,state(local).getJSONArray("routines").length())
    }
}
