package dev.repera.mobile

import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.WorkoutLocationPin
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.util.UUID

/** Edición del pin (selector de lugar) sobre sesión activa y entrenos archivados.
 *  Sólo fixtures sintéticos en un usuario aleatorio: sin ubicación real ni datos del usuario. */
class WorkoutPinEditingInstrumentedTest {

    private fun repoWithRoutines(vararg routineIds: String): Pair<WorkoutRepository, android.content.Context> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val exercise = JSONObject()
            .put("id", exerciseId).put("name", "Press fixture")
            .put("muscleGroup", "Pecho").put("isCustom", true)
            .put("secondaryMuscles", JSONArray()).put("instructions", JSONArray())
            .put("primaryRegions", JSONArray()).put("secondaryRegions", JSONArray())
            .put("isFavorite", false)
        val routines = JSONArray()
        routineIds.forEach { rid ->
            val sets = JSONArray().put(JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8))
            val block = JSONObject().put("id", UUID.randomUUID().toString())
                .put("kind", "strength").put("title", "Bloque")
                .put("exercises", JSONArray().put(JSONObject().put("id", UUID.randomUUID().toString())
                    .put("exerciseId", exerciseId).put("plannedSets", sets)))
            routines.put(JSONObject().put("id", rid).put("title", "Rutina $rid")
                .put("blocks", JSONArray().put(block)).put("progression", "off").put("isFavorite", false))
        }
        val state = JSONObject()
            .put("settings", JSONObject())
            .put("exercises", JSONArray().put(exercise))
            .put("routines", routines)
            .put("workouts", JSONArray()).put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 0).put("lastWriterDeviceId", "")
            .put("updatedAt", "2026-10-24T00:00:00Z")
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        return WorkoutRepository(ctx, user) to ctx
    }

    private fun pin(name: String?, lat: Double = 10.0, lon: Double = 20.0) =
        WorkoutLocationPin(lat, lon, 1_700_000_000_000L, name = name, mapItemIdentifier = "osm:N1")

    private fun edit(title: String = "Editado", start: String? = null, end: String? = null,
                     notes: String? = null, pinEdited: Boolean = false, pin: WorkoutLocationPin? = null) =
        WorkoutRepository.FinishedWorkoutEdit(title, start, end, notes, pinEdited, pin)

    private fun activePinName(repo: WorkoutRepository): String? =
        repo.activeSessionLocationPinForTest()?.optString("name")

    @Test fun addChangeRemoveAndPersistOnActiveSession() {
        val (repo, _) = repoWithRoutines("r1")
        val active = repo.startStrengthRoutine("r1")
        assertNull(repo.activeSessionLocationPinForTest())
        repo.setActiveLocationPin(active.id, pin("Gym A"))
        assertEquals("Gym A", activePinName(repo))
        repo.setActiveLocationPin(active.id, pin("Gym B", 11.0, 21.0))
        assertEquals("Gym B", activePinName(repo))
        assertEquals(11.0, repo.activeSessionLocationPinForTest()!!.getDouble("latitude"), 1e-9)
        // Quitar el pin lo borra del snapshot en disco (lectura vía loadOrNull).
        repo.setActiveLocationPin(active.id, null)
        assertNull(repo.activeSessionLocationPinForTest())
    }

    @Test fun wrongSessionIdNeverTouchesActivePin() {
        val (repo, _) = repoWithRoutines("r1")
        val active = repo.startStrengthRoutine("r1")
        repo.setActiveLocationPin(active.id, pin("Gym A"))
        repo.setActiveLocationPin("otra-sesion", pin("Intruso"))
        repo.setActiveLocationPin("otra-sesion", null)
        assertEquals("Gym A", activePinName(repo))
    }

    @Test fun finishedWorkoutPinIsIsolatedFromOthers() {
        val (repo, _) = repoWithRoutines("r1", "r2")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        val b = repo.startStrengthRoutine("r2"); repo.finish()
        assertTrue(repo.updateFinishedWorkout(a.id, edit(pinEdited = true, pin = pin("Solo A"))))
        val workouts = repo.finishedWorkoutsSnapshot().associateBy { it.optString("id") }
        assertEquals("Solo A", workouts[a.id]!!.getJSONObject("locationPin").getString("name"))
        assertNull(workouts[b.id]!!.optJSONObject("locationPin"))
        assertTrue(repo.updateFinishedWorkout(a.id, edit(pinEdited = true, pin = null)))
        assertNull(repo.finishedWorkoutsSnapshot().first { it.optString("id") == a.id }.optJSONObject("locationPin"))
        assertFalse(repo.updateFinishedWorkout("no-existe", edit(pinEdited = true, pin = pin("x"))))
    }

    @Test fun finishedWorkoutWithRouteIsNotEditable() {
        val (repo, _) = repoWithRoutines("r1")
        val w = repo.startStrengthRoutine("r1"); repo.finish()
        val pts = (0 until 3).map {
            dev.repera.domain.WorkoutRoutePoint(it, 10.0 + it * 0.001, 20.0, 1_700_000_000_000L + it * 1000L)
        }
        repo.attachRoutePoints(w.id, pts)
        repo.updateFinishedWorkout(w.id, edit(pinEdited = true, pin = pin("No debe guardarse")))
        assertNull(repo.finishedWorkoutsSnapshot().first().optJSONObject("locationPin"))
    }

    @Test fun activePinSurvivesFinishIntoArchive() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1")
        repo.setActiveLocationPin(a.id, pin("Gym A"))
        repo.finish()
        assertEquals("Gym A", repo.finishedWorkoutsSnapshot().first().getJSONObject("locationPin").getString("name"))
    }

    @Test fun editAppliesTitleNotesDatesAndKeepsCountsAndIds() {
        val (repo, _) = repoWithRoutines("r1", "r2")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        val b = repo.startStrengthRoutine("r2"); repo.finish()
        val before = repo.finishedWorkoutsSnapshot()
        val bBefore = before.first { it.optString("id") == b.id }.toString()
        assertTrue(repo.updateFinishedWorkout(a.id, edit(
            title = "  Mi pierna  ", start = "2026-10-20T10:00:00Z", end = "2026-10-20T11:00:00Z",
            notes = " dolor leve ")))
        val after = repo.finishedWorkoutsSnapshot()
        assertEquals(before.size, after.size)
        val ea = after.first { it.optString("id") == a.id }
        assertEquals("Mi pierna", ea.getString("title"))
        assertEquals("dolor leve", ea.getString("notes"))
        assertEquals("2026-10-20T10:00:00Z", ea.getString("startedAt"))
        assertEquals(bBefore, after.first { it.optString("id") == b.id }.toString())
    }

    @Test fun endBeforeStartIsClampedToStartPlusOneMinuteAndBlankTitleBecomesEntreno() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        repo.updateFinishedWorkout(a.id, edit(title = "  ", start = "2026-10-20T10:00:00Z", end = "2026-10-20T09:00:00Z"))
        val e = repo.finishedWorkoutsSnapshot().first()
        assertEquals("Entreno", e.getString("title"))
        assertEquals("2026-10-20T10:01:00Z", e.getString("finishedAt"))
    }

    @Test fun editDropsStaleSessionReviewAndBlankNotesRemoveNotes() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        repo.updateFinishedWorkout(a.id, edit(notes = "algo"))
        repo.updateFinishedWorkout(a.id, edit(notes = "   "))
        val e = repo.finishedWorkoutsSnapshot().first()
        assertFalse(e.has("notes"))
        assertFalse(e.has("sessionReview"))
    }
}
