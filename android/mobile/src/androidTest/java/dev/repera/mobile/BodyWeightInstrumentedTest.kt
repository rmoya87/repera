package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.util.UUID

/** Registro de peso corporal: formato BodyWeightEntry compartido con iOS. */
@RunWith(AndroidJUnit4::class)
class BodyWeightInstrumentedTest {
    private fun repo(): Pair<WorkoutRepository, LocalSnapshotStore> {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val user = UUID.randomUUID().toString()
        val state = JSONObject().put("exercises", JSONArray())
            .put("routines", JSONArray()).put("workouts", JSONArray())
            .put("bodyWeights", JSONArray()).put("syncRevision", 0)
        val local = LocalSnapshotStore(ctx, user)
        local.write(state.toString().toByteArray(Charsets.UTF_8))
        return WorkoutRepository(ctx, user) to local
    }

    private fun weights(local: LocalSnapshotStore): JSONArray =
        JSONObject(String(local.read()!!)).getJSONArray("bodyWeights")

    @Test fun logWritesSharedFormatAndOnePerDay() {
        val (repo, local) = repo()
        val before=System.currentTimeMillis()
        val captured=repo.logBodyWeight(80.5)
        assertTrue(captured.first>=before && captured.first<=System.currentTimeMillis())
        var array = weights(local)
        assertEquals(1, array.length())
        val entry = array.getJSONObject(0)
        assertEquals(80.5, entry.getDouble("weightKg"), 0.001)
        assertEquals("manual", entry.getString("source"))
        assertTrue(entry.getString("id").isNotBlank())
        assertEquals(LocalDate.now(),BodyWeightHistory.day(entry.getString("date")))
        val identity=entry.getString("id")
        // Mismo día: sustituye, no duplica.
        repo.logBodyWeight(81.0)
        array = weights(local)
        assertEquals(1, array.length())
        assertEquals(81.0, array.getJSONObject(0).getDouble("weightKg"), 0.001)
        assertEquals(identity,array.getJSONObject(0).getString("id"))
        // Empty authorized provider still exports local-only days.
        val outbound=repo.mergeHealthBodyWeights(emptyList())
        assertEquals(1,outbound.size);assertEquals(81.0,outbound.single().second,0.0)
        // Otro día explícito: coexisten.
        repo.logBodyWeight(79.0, "2026-10-01")
        assertEquals(2, weights(local).length())
    }

    @Test fun validationAndDelete() {
        val (repo, local) = repo()
        assertThrows(IllegalArgumentException::class.java) { repo.logBodyWeight(5.0) }
        assertThrows(IllegalArgumentException::class.java) { repo.logBodyWeight(500.0) }
        repo.logBodyWeight(80.0)
        val id = weights(local).getJSONObject(0).getString("id")
        repo.deleteBodyWeight(id)
        assertEquals(0, weights(local).length())
        // Borrar un id inexistente no falla.
        repo.deleteBodyWeight(UUID.randomUUID().toString())
    }
}
