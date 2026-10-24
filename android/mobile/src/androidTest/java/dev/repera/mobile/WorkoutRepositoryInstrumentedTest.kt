package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

/** Device-only integration tests for the exact Repera JSON contract and atomic writes. */
@RunWith(AndroidJUnit4::class)
class WorkoutRepositoryInstrumentedTest {
    @Test fun realSeriesArePersistedExactlyOnceAndContinueAfterReload() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val exercise = JSONObject()
            .put("id", exerciseId)
            .put("name", "Sentadilla")
            .put("muscleGroup", "Piernas")
            .put("isCustom", true)
            .put("secondaryMuscles", JSONArray())
            .put("instructions", JSONArray())
            .put("primaryRegions", JSONArray())
            .put("secondaryRegions", JSONArray())
            .put("isFavorite", false)
        val sets = JSONArray().put(
            JSONObject().put("id", UUID.randomUUID().toString()).put("targetReps", 8)
                .put("targetWeightKg", 50.0)
        )
        val block = JSONObject().put("id", UUID.randomUUID().toString()).put("kind", "strength")
            .put("title", "Fuerza").put("exercises", JSONArray().put(
                JSONObject().put("id", UUID.randomUUID().toString())
                    .put("exerciseId", exerciseId).put("plannedSets", sets)
            ))
        val routine = JSONObject().put("id", routineId).put("title", "Piernas")
            .put("blocks", JSONArray().put(block)).put("progression", "linear")
            .put("isFavorite", false)
        val state = JSONObject().put("settings", JSONObject())
            .put("exercises", JSONArray().put(exercise))
            .put("routines", JSONArray().put(routine))
            .put("workouts", JSONArray()).put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 0).put("lastWriterDeviceId", "")
            .put("updatedAt", "2026-10-23T00:00:00Z")
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startStrengthRoutine(routineId)
        assertEquals(8, active.prescribedQuantity)
        assertEquals(50.0, active.prescribedWeightKg!!, 0.001)
        repo.logCurrentSet(7, 52.5)
        val fresh = WorkoutRepository(ctx, user).active()!!
        assertEquals(1, fresh.completedSets)
        assertEquals(7, fresh.sets.single().reps)
        val id = fresh.sets.single().id
        repo.reviseCurrentSet(id, 8, 52.5)
        assertEquals(id, repo.active()!!.sets.single().id)
        assertNull(repo.next())
        val saved = JSONObject(String(LocalSnapshotStore(ctx, user).read()!!))
        assertFalse(saved.has("activeSession"))
        assertEquals(1, saved.getJSONArray("workouts").length())
        assertEquals(1, saved.getJSONArray("workouts").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0).getJSONArray("loggedSets").length())
    }

    @Test fun recoveredMirrorWorkoutsMergeOnlyUnknownFinishedIdsSorted() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val existing = JSONObject().put("id", "w-local")
            .put("title", "Local").put("finishedAt", "2026-10-22T18:00:00Z")
        val state = JSONObject().put("settings", JSONObject())
            .put("exercises", JSONArray()).put("routines", JSONArray())
            .put("workouts", JSONArray().put(existing))
            .put("bodyWeights", JSONArray())
            .put("favoriteTimers", JSONArray()).put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 0).put("lastWriterDeviceId", "")
            .put("updatedAt", "2026-10-23T00:00:00Z")
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        val older = JSONObject().put("id", "w-remote-1")
            .put("title", "Otro dispositivo").put("finishedAt", "2026-10-20T18:00:00Z")
        val duplicate = JSONObject().put("id", "w-local")
            .put("title", "Duplicado").put("finishedAt", "2026-10-23T18:00:00Z")
        val unfinished = JSONObject().put("id", "w-remote-2").put("title", "Vivo")
        val imported = repo.mergeRecoveredWorkoutsFromSupabase(
            listOf(older, duplicate, unfinished))
        assertEquals(1, imported)
        val saved = JSONObject(String(LocalSnapshotStore(ctx, user).read()!!))
        val workouts = saved.getJSONArray("workouts")
        assertEquals(2, workouts.length())
        assertEquals("w-local", workouts.getJSONObject(0).getString("id"))
        assertEquals("Local", workouts.getJSONObject(0).getString("title"))
        assertEquals("w-remote-1", workouts.getJSONObject(1).getString("id"))
        // Segunda pasada idempotente: ya conocido, no duplica.
        assertEquals(0, repo.mergeRecoveredWorkoutsFromSupabase(listOf(older)))
    }

    @Test fun noWodIsSilentlyCoercedToStrength() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val id = UUID.randomUUID().toString()
        val state = JSONObject()
            .put("exercises", JSONArray())
            .put("workouts", JSONArray())
            .put("routines", JSONArray().put(JSONObject().put("id", id)
                .put("title", "AMRAP").put("blocks", JSONArray().put(
                    JSONObject().put("id", UUID.randomUUID().toString())
                        .put("kind", "wod")
                )))).put("syncRevision", 0)
        LocalSnapshotStore(ctx, user).write(state.toString().toByteArray())
        assertThrows(IllegalStateException::class.java) {
            WorkoutRepository(ctx, user).startStrengthRoutine(id)
        }
        assertNull(WorkoutRepository(ctx, user).active())
    }

    @Test fun forTimeRecordsOnlyOneBlockScoreAndNoFakeSets() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val blockId = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val movements = JSONArray()
            .put(JSONObject().put("id", UUID.randomUUID().toString())
                .put("name", "Squat clean").put("reps", 21))
            .put(JSONObject().put("id", UUID.randomUUID().toString())
                .put("name", "Box jump").put("reps", 21))
        val block = JSONObject().put("id", blockId).put("kind", "wod")
            .put("title", "21-15-9").put("wodFormat", "forTime")
            .put("timeCapMinutes", 12).put("movements", movements)
        val state = JSONObject().put("exercises", JSONArray())
            .put("routines", JSONArray().put(
                JSONObject().put("id", routineId).put("title", "Metcon")
                    .put("blocks", JSONArray().put(block))
            )).put("workouts", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        val active = repo.startRoutine(routineId)
        assertEquals("ELAPSED_TIME", active.wod!!.capture)
        assertEquals(2, active.wod!!.movements.size)
        assertThrows(IllegalStateException::class.java) { repo.next() }
        assertNull(repo.recordWodScore(null, null, 387))
        val after = JSONObject(String(local.read()!!))
        assertFalse(after.has("activeSession"))
        val recorded = after.getJSONArray("workouts").getJSONObject(0)
        assertEquals("finished", recorded.getString("phase"))
        val score = recorded.getJSONArray("wodResults").getJSONObject(0)
        assertEquals(blockId, score.getString("id"))
        assertEquals("forTime", score.getString("format"))
        assertEquals(387, score.getInt("elapsedSeconds"))
        val overview = StateOverview.fromBytes(local.read())!!
        assertEquals("For Time / RFT · 6:27", overview.history.single().results.single())
        assertEquals(2, overview.history.single().movements.size)
        assertTrue(overview.history.single().movements.all { it.registered.isEmpty() })
        assertFalse(score.has("roundsCompleted"))
        for (i in 0 until recorded.getJSONArray("exercises").length()) {
            val ex = recorded.getJSONArray("exercises").getJSONObject(i)
            assertEquals(0, ex.getJSONArray("loggedSets").length())
            assertTrue(ex.getBoolean("isCompleted"))
        }
    }

    @Test fun mixedStrengthThenAmrapKeepsBothKindsWithoutFabricatedSets() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val exerciseId = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val wodId = UUID.randomUUID().toString()
        val catalogExercise = JSONObject().put("id", exerciseId)
            .put("name", "Sentadilla").put("muscleGroup", "Piernas")
            .put("equipment", "Barra").put("isCustom", false)
        val strength = JSONObject().put("id", UUID.randomUUID().toString())
            .put("kind", "strength").put("title", "Fuerza")
            .put("exercises", JSONArray().put(
                JSONObject().put("exerciseId", exerciseId)
                    .put("plannedSets", JSONArray().put(JSONObject()
                        .put("id", UUID.randomUUID().toString())
                        .put("targetReps", 4)))
            ))
        val wod = JSONObject().put("id", wodId).put("kind", "wod")
            .put("title", "AMRAP 12'").put("wodFormat", "amrap")
            .put("movements", JSONArray().put(
                JSONObject().put("id", UUID.randomUUID().toString())
                    .put("name", "Burpee").put("reps", 10)
            ))
        val state = JSONObject().put("exercises", JSONArray().put(catalogExercise))
            .put("routines", JSONArray().put(JSONObject().put("id", routineId)
                .put("title", "Fuerza + Metcon").put("blocks", JSONArray()
                    .put(strength).put(wod))))
            .put("workouts", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        repo.startRoutine(routineId)
        repo.logCurrentSet(4, 60.0)
        val next = repo.next()!!
        assertEquals("amrap", next.wod?.format)
        assertThrows(IllegalArgumentException::class.java) {
            repo.recordWodScore(null, 3, null)
        }
        assertNull(repo.recordWodScore(3, 7, null))
        val archive = JSONObject(String(local.read()!!)).getJSONArray("workouts").getJSONObject(0)
        assertEquals(1, archive.getJSONArray("wodResults").length())
        assertEquals(3, archive.getJSONArray("wodResults").getJSONObject(0)
            .getInt("roundsCompleted"))
        assertEquals(7, archive.getJSONArray("wodResults").getJSONObject(0)
            .getInt("totalReps"))
        assertEquals(1, archive.getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").length())
        assertEquals(0, archive.getJSONArray("exercises").getJSONObject(1)
            .getJSONArray("loggedSets").length())
    }

    @Test fun createsAndRunsRealStrengthRoutineFromNativeCatalog() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(ctx, user)
        val store = LocalSnapshotStore(ctx, user)
        val initial = JSONObject(String(store.read()!!))
        assertEquals(196, initial.getJSONArray("exercises").length())
        val movementId = initial.getJSONArray("exercises").getJSONObject(0).getString("id")
        val repo = WorkoutRepository(ctx, user)
        val createdId = repo.createRoutine(
            title = "Fuerza prueba", format = "strength",
            entries = listOf(RoutineDraftEntry(movementId, 8, sets = 3, weightKg = 50.0))
        )
        assertTrue(createdId.isNotBlank())
        val afterCreate = JSONObject(String(store.read()!!))
        val routine = afterCreate.getJSONArray("routines").getJSONObject(0)
        assertEquals("off", routine.getString("progression"))
        assertEquals(3, routine.getJSONArray("blocks").getJSONObject(0)
            .getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("plannedSets").length())
        repo.startRoutine(createdId)
        repo.logCurrentSet(8, 50.0)
        val fresh = WorkoutRepository(ctx, user).active()!!
        assertEquals(8, fresh.sets.single().reps)
    }

    @Test fun createsWodWithCatalogMovementsAndStoresRealAmrapScore() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(ctx, user)
        val store = LocalSnapshotStore(ctx, user)
        val catalog = JSONObject(String(store.read()!!)).getJSONArray("exercises")
        val burpee = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .first { it.getString("name") == "Burpee" }
        val repo = WorkoutRepository(ctx, user)
        val createdId = repo.createRoutine(
            "AMRAP prueba", "amrap",
            listOf(RoutineDraftEntry(burpee.getString("id"), 10)),
            timeCapMinutes = 12
        )
        val current = repo.startRoutine(createdId)
        assertEquals("amrap", current.wod?.format)
        assertEquals("Burpee", current.wod?.movements?.single()?.name)
        assertNull(repo.recordWodScore(4, 6, null))
        val state = JSONObject(String(store.read()!!))
        val score = state.getJSONArray("workouts").getJSONObject(0)
            .getJSONArray("wodResults").getJSONObject(0)
        assertEquals("amrap", score.getString("format"))
        assertEquals(4, score.getInt("roundsCompleted"))
        assertEquals(6, score.getInt("totalReps"))
    }

    @Test fun warmupDoesNotConsumePrescribedWorkAndRirIsSaved() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(ctx, user)
        val store = LocalSnapshotStore(ctx, user)
        val firstId = JSONObject(String(store.read()!!)).getJSONArray("exercises")
            .getJSONObject(0).getString("id")
        val repo = WorkoutRepository(ctx, user)
        val routineId = repo.createRoutine("Fuerza real", "strength",
            listOf(RoutineDraftEntry(firstId, 8, sets = 2, weightKg = 60.0)))
        repo.startRoutine(routineId)
        repo.logCurrentSet(5, 30.0, rir = 4.0, warmup = true)
        val afterWarmup = repo.active()!!
        assertEquals(8, afterWarmup.prescribedQuantity)
        assertEquals("warmup", afterWarmup.sets.single().phase)
        assertEquals(4.0, afterWarmup.sets.single().rir!!, 0.001)
        val stateAfterWarmup = JSONObject(String(store.read()!!))
        assertEquals(0, stateAfterWarmup.getJSONObject("activeSession")
            .getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
        repo.logCurrentSet(8, 60.0, rir = 2.0, warmup = false)
        val afterWork = WorkoutRepository(ctx, user).active()!!
        assertEquals(2, afterWork.sets.size)
        assertEquals("work", afterWork.sets[1].phase)
        assertEquals(2.0, afterWork.sets[1].rir!!, 0.001)
        val stateAfterWork = JSONObject(String(store.read()!!))
        assertEquals(8, stateAfterWork.getJSONObject("activeSession")
            .getJSONArray("exercises").getJSONObject(0).getInt("completedReps"))
    }

    @Test fun emomMovementsPersistByIntervalWithoutFabricatedSets() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val blockId = UUID.randomUUID().toString()
        val moves = JSONArray().put(JSONObject()
            .put("id", UUID.randomUUID().toString()).put("name", "Air Squat")
            .put("reps", 12)).put(JSONObject()
            .put("id", UUID.randomUUID().toString()).put("name", "Push-up")
            .put("reps", 8))
        val block = JSONObject().put("id", blockId).put("title", "EMOM")
            .put("kind", "wod").put("wodFormat", "emom")
            .put("emomIntervalSeconds", 60).put("rounds", 5)
            .put("movements", moves)
        val state = JSONObject().put("exercises", JSONArray())
            .put("routines", JSONArray().put(JSONObject().put("id", routineId)
                .put("title", "Intervalos").put("blocks", JSONArray().put(block))))
            .put("workouts", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray())
        val repository = WorkoutRepository(ctx, user)
        val started = repository.startRoutine(routineId)
        assertEquals("PER_MOVEMENT_SETS", started.wod?.capture)
        assertTrue(started.wod!!.recorded.isEmpty())
        assertThrows(IllegalStateException::class.java) {
            repository.completeWodMovementBlock()
        }
        assertThrows(IllegalArgumentException::class.java) {
            repository.recordWodMovement(0, 5, 12, null)
        }
        assertTrue(repository.active()!!.wod!!.recorded.isEmpty())
        repository.recordWodMovement(0, 0, 12, null)
        val reloaded = WorkoutRepository(ctx, user)
        assertEquals(1, reloaded.active()!!.wod!!.recorded.size)
        assertNull(reloaded.active()!!.wod!!.recorded.single().quantityUnit)
        reloaded.recordWodMovement(1, 1, 8, null)
        val recorded = reloaded.active()!!.wod!!.recorded
        val originalId = recorded.last().id
        reloaded.reviseWodMovementSet(originalId, 9, 20.0)
        val revised = WorkoutRepository(ctx, user).active()!!.wod!!.recorded.last()
        assertEquals(originalId, revised.id)
        assertEquals(9, revised.quantity)
        assertEquals(20.0, revised.weightKg!!, 0.001)
        reloaded.deleteWodMovementSet(originalId)
        assertEquals(1, reloaded.active()!!.wod!!.recorded.size)
        reloaded.recordWodMovement(1, 1, 8, null)
        assertNull(reloaded.completeWodMovementBlock())
        val saved = JSONObject(String(local.read()!!))
            .getJSONArray("workouts").getJSONObject(0)
        assertEquals(0, saved.getJSONArray("wodResults").length())
        val exercises = saved.getJSONArray("exercises")
        assertEquals(1, exercises.getJSONObject(0).getJSONArray("loggedSets").length())
        assertEquals(1, exercises.getJSONObject(1).getJSONArray("loggedSets").length())
        assertEquals(1, exercises.getJSONObject(1).getJSONArray("loggedSets")
            .getJSONObject(0).getInt("intervalIndex"))
    }

    @Test fun perMovementCaloriesRemainCaloriesAfterPersistingAndReloading() {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val routineId = UUID.randomUUID().toString()
        val block = JSONObject().put("id", UUID.randomUUID().toString())
            .put("kind", "wod").put("wodFormat", "emom")
            .put("title", "Calories EMOM").put("rounds", 3)
            .put("movements", JSONArray().put(JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("name", "Row").put("calories", 14).put("isRest", false)))
        val state = JSONObject().put("exercises", JSONArray())
            .put("routines", JSONArray().put(JSONObject().put("id", routineId)
                .put("title", "Erg").put("blocks", JSONArray().put(block))))
            .put("workouts", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray())
        val repo = WorkoutRepository(ctx, user)
        repo.startRoutine(routineId)
        repo.recordWodMovement(0, 0, 14, null)
        val confirmed = WorkoutRepository(ctx, user).active()!!.wod!!.recorded.single()
        assertEquals(14, confirmed.quantity)
        assertEquals("calories", confirmed.quantityUnit)
        assertNull(repo.completeWodMovementBlock())
        val logged = JSONObject(String(local.read()!!)).getJSONArray("workouts")
            .getJSONObject(0).getJSONArray("exercises").getJSONObject(0)
            .getJSONArray("loggedSets").getJSONObject(0)
        assertEquals("calories", logged.getString("quantityUnit"))
    }
}
