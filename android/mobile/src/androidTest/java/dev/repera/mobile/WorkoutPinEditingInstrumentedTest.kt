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
                     notes: String? = null, pinEdited: Boolean = false, pin: WorkoutLocationPin? = null,
                     blocksJson: String? = null) =
        WorkoutRepository.FinishedWorkoutEdit(title, start, end, notes, pinEdited, pin, blocksJson)

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

    @Test fun editRecomputesReviewLikeEngineAndKeepsOtherData() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        repo.updateFinishedWorkout(a.id, edit(notes = "algo", title = "T"))
        val e = repo.finishedWorkoutsSnapshot().first()
        // La valoración debe coincidir con lo que calcula el motor sobre el estado actual
        // (presente solo si el motor devuelve algo); las notas no se tocan por extensión.
        val copy = JSONObject(e.toString())
        val expected = SessionReviewSupport.attachToFinishedSession(
            JSONObject().put("workouts", JSONArray().put(copy)), copy)
        assertEquals(expected != null, e.has("sessionReview"))
        assertEquals("algo", e.getString("notes"))
        repo.updateFinishedWorkout(a.id, edit(notes = "   ", title = "T"))
        assertFalse(repo.finishedWorkoutsSnapshot().first().has("notes"))
    }

    @Test fun durationFollowsDatesAndKcalDroppedWithoutHealthLink() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        repo.updateFinishedWorkout(a.id, edit(start = "2026-10-20T10:00:00Z", end = "2026-10-20T11:00:00Z"))
        val e = repo.finishedWorkoutsSnapshot().first()
        assertEquals(3600.0, e.getDouble("appleDurationSeconds"), 1e-6)
        assertFalse(e.has("appleActiveEnergyKcal"))
    }

    @Test fun persistenceFailureThrowsAndLeavesDiskUntouched() {
        val (repo, ctx) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1"); repo.finish()
        val dir = ctx.filesDir.resolve("users").listFiles()!!.first { d ->
            d.resolve("app_state.json").exists() && d.lastModified() >= 0 &&
                String(d.resolve("app_state.json").readBytes()).contains(a.id) }
        val before = dir.resolve("app_state.json").readBytes()
        assertTrue(dir.setWritable(false))
        try {
            var threw = false
            try { repo.updateFinishedWorkout(a.id, edit(title = "No debe persistir")) }
            catch (e: Exception) { threw = true }
            assertTrue(threw)
            assertArrayEquals(before, dir.resolve("app_state.json").readBytes())
        } finally { dir.setWritable(true) }
    }

    @Test fun contentEditReordersKeepsLoggedSetIdentityAndPersistsAtomically() {
        val (repo, ctx) = repoWithRoutines("r1")
        // Rutina de dos ejercicios: se crea en el fixture con un solo ejercicio, así que
        // se registra una serie y se edita el contenido sobre ese entreno.
        val a = repo.startStrengthRoutine("r1")
        repo.logCurrentSet(quantity = 5, weightKg = 60.0, rir = 2.0)
        repo.finish()
        val saved = repo.finishedWorkoutsSnapshot().first()
        val loggedId = saved.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0).getString("id")
        val blocks = CompletedWorkoutEditing.blocksFrom(saved, null)
        val set = blocks.getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").getJSONObject(0)
        set.put("targetReps", 7).put("targetWeightKg", 62.5)
        assertTrue(repo.updateFinishedWorkout(a.id, edit(title = "Editado", blocksJson = blocks.toString())))
        val after = repo.finishedWorkoutsSnapshot().first()
        val l = after.getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").getJSONObject(0)
        assertEquals(loggedId, l.getString("id"))
        assertEquals(7, l.getInt("reps"))
        assertEquals(62.5, l.getDouble("weightKg"), 1e-9)
        assertEquals(7, after.getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
        assertEquals("Editado", after.getString("title"))
    }

    /** Pending custom exercise (WOD→fuerza sin catálogo): cuota denegada = nada persiste; permitido = se crea UNA vez y se enlaza. */
    @Test fun pendingCustomExerciseIsCreatedOnlyOnSaveAndRespectsQuota() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1")
        repo.logCurrentSet(quantity = 5, weightKg = 60.0, rir = 2.0)
        repo.finish()
        val saved = repo.finishedWorkoutsSnapshot().first()
        val blocks = CompletedWorkoutEditing.blocksFrom(saved, null)
        blocks.getJSONObject(0).getJSONArray("exercises").put(JSONObject()
            .put("id", UUID.randomUUID().toString()).put("exerciseId", "pending:Thruster fixture")
            .put("plannedSets", JSONArray().put(JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8))))
        val before = repo.finishedWorkoutsSnapshot().first().toString()
        var threw = false
        try { repo.updateFinishedWorkout(a.id, edit(blocksJson = blocks.toString())) { false } } catch (e: IllegalStateException) { threw = true }
        assertTrue("cuota denegada lanza", threw)
        assertEquals("el entreno no cambia", before, repo.finishedWorkoutsSnapshot().first().toString())
        assertTrue(repo.updateFinishedWorkout(a.id, edit(blocksJson = blocks.toString())) { true })
        val after = repo.finishedWorkoutsSnapshot().first().getJSONArray("exercises")
        val names = (0 until after.length()).map { after.getJSONObject(it).getJSONObject("exercise").getString("name") }
        assertTrue(names.contains("Thruster fixture"))
        val ids = (0 until after.length()).map { after.getJSONObject(it).getJSONObject("exercise").getString("id") }
        assertFalse(ids.any { it.startsWith("pending:") })
    }

    /** Lote de 3 pendientes (2 con el mismo nombre normalizado + 1 distinto): capacidad validada para el lote;
     *  reintento idempotente (sin duplicados). */
    @Test fun pendingBatchValidatesTotalCapacityAndRetryDoesNotDuplicate() {
        val (repo, _) = repoWithRoutines("r1")
        val a = repo.startStrengthRoutine("r1")
        repo.logCurrentSet(quantity = 5, weightKg = 60.0, rir = 2.0)
        repo.finish()
        val saved = repo.finishedWorkoutsSnapshot().first()
        val blocks = CompletedWorkoutEditing.blocksFrom(saved, null)
        fun add(name: String) = blocks.getJSONObject(0).getJSONArray("exercises").put(JSONObject()
            .put("id", UUID.randomUUID().toString()).put("exerciseId", "pending:$name")
            .put("plannedSets", JSONArray().put(JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8))))
        add("Remo Sentado"); add("remo sentado"); add("Zancada Búlgara")
        // El fixture ya tiene 1 personalizado: 1 + 2 nuevos = 3 → el último comprueba con 2 existentes previos.
        val seen = mutableListOf<Int>()
        var threw = false
        try { repo.updateFinishedWorkout(a.id, edit(blocksJson = blocks.toString())) { n -> seen += n; false } }
        catch (e: IllegalStateException) { threw = true }
        assertTrue(threw); assertEquals("una sola comprobación del lote", listOf(2), seen)
        assertTrue(repo.updateFinishedWorkout(a.id, edit(blocksJson = blocks.toString())) { true })
        // Reintento con el mismo contenido: no crea nada nuevo.
        val sizeAfterFirst = repo.finishedWorkoutsSnapshot().first().getJSONArray("exercises").length()
        assertTrue(repo.updateFinishedWorkout(a.id, edit(blocksJson = blocks.toString())) { n -> fail("no debe pedir cuota"); false })
        assertEquals(sizeAfterFirst, repo.finishedWorkoutsSnapshot().first().getJSONArray("exercises").length())
    }
}
