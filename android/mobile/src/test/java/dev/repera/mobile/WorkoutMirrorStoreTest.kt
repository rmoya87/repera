package dev.repera.mobile

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Privatización y huella canónica del espejo de entrenos. */
class WorkoutMirrorStoreTest {

    @Test
    fun privatizeStripsPrivateFields() {
        val workout = JSONObject()
            .put("id", "w1")
            .put("title", "Fuerza")
            .put("notes", "Me sentí mal")
            .put("sessionReview", JSONObject().put("rating", 3))
            .put("locationPin", JSONObject().put("lat", 40.0))
            .put("routePoints", org.json.JSONArray().put(JSONObject()))
            .put("healthKitWorkoutUUID", "hk-1")
            .put("appleActiveEnergyKcal", 450.0)
            .put("appleAverageHeartRateBpm", 132.0)
            .put("appleHealthProvenance", "hk")
            .put("appleDurationSeconds", 3600.0)
            .put("exercises", org.json.JSONArray())
        val clean = WorkoutMirrorStore.privatize(workout)
        assertEquals("w1", clean.getString("id"))
        assertEquals("Fuerza", clean.getString("title"))
        for (key in listOf("notes", "sessionReview", "locationPin", "routePoints",
            "healthKitWorkoutUUID", "appleActiveEnergyKcal",
            "appleAverageHeartRateBpm", "appleHealthProvenance",
            "appleDurationSeconds")) {
            assertFalse("$key no debía sobrevivir", clean.has(key))
        }
        // El original no se toca
        assertTrue(workout.has("notes"))
    }

    @Test
    fun digestIsStableAndKeyOrderIndependent() {
        val a = JSONObject()
            .put("id", "w1")
            .put("title", "Fuerza")
            .put("reps", 10)
        val b = JSONObject()
            .put("reps", 10)
            .put("title", "Fuerza")
            .put("id", "w1")
        assertEquals(WorkoutMirrorStore.canonicalDigest(a),
            WorkoutMirrorStore.canonicalDigest(b))
        assertEquals(64, WorkoutMirrorStore.canonicalDigest(a).length)
    }

    @Test
    fun digestChangesWithContent() {
        val a = JSONObject().put("id", "w1").put("reps", 10)
        val b = JSONObject().put("id", "w1").put("reps", 11)
        assertTrue(WorkoutMirrorStore.canonicalDigest(a) !=
            WorkoutMirrorStore.canonicalDigest(b))
    }

    @Test
    fun digestHandlesNestedStructures() {
        val set = JSONObject().put("reps", 10).put("weightKg", 60.0)
        val exercise = JSONObject().put("name", "Sentadilla")
            .put("loggedSets", org.json.JSONArray().put(set))
        val workout = JSONObject().put("id", "w1")
            .put("exercises", org.json.JSONArray().put(exercise))
        val digest = WorkoutMirrorStore.canonicalDigest(workout)
        assertEquals(64, digest.length)
        // Determinista
        assertEquals(digest, WorkoutMirrorStore.canonicalDigest(
            JSONObject(workout.toString())))
    }

    @Test
    fun backfillOnlyWhenBlocksMissingAndEverythingElseMatches() {
        val blocks = org.json.JSONArray().put(JSONObject().put("kind", "wod"))
        val local = JSONObject()
            .put("id", "w1").put("title", "WOD").put("finishedAt", "2026-10-20T18:00:00Z")
            .put("routineBlocks", blocks)
        val remote = JSONObject()
            .put("id", "w1").put("title", "WOD").put("finishedAt", "2026-10-20T18:00:00Z")
        assertTrue(WorkoutMirrorStore.canRestoreMissingBlockSnapshot(local, remote))
    }

    @Test
    fun backfillRejectedWhenRemoteHasBlocksOrFieldsDiffer() {
        val blocks = org.json.JSONArray().put(JSONObject().put("kind", "wod"))
        val local = JSONObject()
            .put("id", "w1").put("title", "WOD").put("finishedAt", "2026-10-20T18:00:00Z")
            .put("routineBlocks", blocks)
        // El remoto ya tiene bloques: no hay nada que restaurar.
        val withBlocks = JSONObject(local.toString())
        assertFalse(WorkoutMirrorStore.canRestoreMissingBlockSnapshot(local, withBlocks))
        // Cualquier otro campo distinto invalida el backfill.
        val edited = JSONObject()
            .put("id", "w1").put("title", "WOD editado").put("finishedAt", "2026-10-20T18:00:00Z")
        assertFalse(WorkoutMirrorStore.canRestoreMissingBlockSnapshot(local, edited))
        // Local sin bloques no puede restaurar nada.
        val noBlocks = JSONObject()
            .put("id", "w1").put("title", "WOD").put("finishedAt", "2026-10-20T18:00:00Z")
        assertFalse(WorkoutMirrorStore.canRestoreMissingBlockSnapshot(noBlocks,
            JSONObject().put("id", "w1")))
    }
}
