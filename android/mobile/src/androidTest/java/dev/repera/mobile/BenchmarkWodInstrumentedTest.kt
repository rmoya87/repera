package dev.repera.mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.CatalogWods
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID

@RunWith(AndroidJUnit4::class)
class BenchmarkWodInstrumentedTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun franBecomesANativeRoutineKeepingItsRepeatedMovements() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        MobilityCatalogMigration.ensure(context, account)
        val repo = WorkoutRepository(context, account)
        val fran = CatalogWods.template("fran")!!
        val routineId = repo.createWodRoutine(fran)
        val local = LocalSnapshotStore(context, account)
        val routines = JSONObject(String(local.read()!!)).getJSONArray("routines")
        val routine = (0 until routines.length()).map { routines.getJSONObject(it) }
            .single { it.getString("id") == routineId }
        assertEquals("Fran", routine.getString("title"))
        val block = routine.getJSONArray("blocks").getJSONObject(0)
        assertEquals("wod", block.getString("kind"))
        assertEquals("forTime", block.getString("wodFormat"))
        assertEquals("fran", block.getString("wodTemplateId"))
        assertEquals(10, block.getInt("timeCapMinutes"))
        assertEquals("21-15-9 thrusters + pull-ups", block.getString("wodNotes"))
        val movements = block.getJSONArray("movements")
        // The 21-15-9 couplet stays six entries; no synthetic dedup.
        assertEquals(6, movements.length())
        assertEquals(listOf(21, 21, 15, 15, 9, 9),
            (0 until movements.length()).map { movements.getJSONObject(it).getInt("reps") })
        // Known names resolve to real catalog exercises; none is fabricated.
        val catalog = JSONObject(String(local.read()!!)).getJSONArray("exercises")
        val names = (0 until catalog.length()).map { catalog.getJSONObject(it) }
            .associate { it.getString("id") to it.getString("name") }
        val thruster = movements.getJSONObject(0)
        assertEquals("Thruster", names[thruster.getString("exerciseId")])
        assertEquals(43.0, thruster.getDouble("weightMaleKg"), 0.0)
    }

    @Test fun benchmarkRoutineStartsAndAssemblesSessionMovements() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        MobilityCatalogMigration.ensure(context, account)
        val repo = WorkoutRepository(context, account)
        val routineId = repo.createWodRoutine(CatalogWods.template("cindy")!!)
        val active = repo.startRoutine(routineId)
        val wod = active.wod!!
        assertEquals("amrap", wod.format)
        assertEquals(20, wod.timeCapMinutes)
        assertEquals(3, wod.movements.size)
        assertEquals(listOf("Dominadas", "Flexiones", "Air squat"),
            wod.movements.map { it.name })
        repo.finish()
    }

    @Test fun unmatchedTemplateNamesNeverBlockCreation() {
        val account = UUID.randomUUID().toString()
        CatalogBootstrap.initializeEmptyAccount(context, account)
        MobilityCatalogMigration.ensure(context, account)
        val repo = WorkoutRepository(context, account)
        // Every catalog benchmark must insert and remain startable, even when a
        // movement name is absent from the local catalog (custom resolution).
        CatalogWods.seed().forEach { template ->
            val id = repo.createWodRoutine(template)
            assertNotNull(id)
        }
        val routines = JSONObject(String(LocalSnapshotStore(context, account).read()!!))
            .getJSONArray("routines")
        assertEquals(31, routines.length())
    }
}
