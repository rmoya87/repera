package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
class WorkoutActionAuthorizationInstrumentedTest {
    @Test fun actionRevokedBeforeReadCannotChangeSettings() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val owner="test-action-revoked-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(ctx,owner)
        val before=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray()
        local.write(before)
        val repo=WorkoutRepository(ctx,owner,stillAuthorized={false})
        assertTrue(runCatching {repo.updateTrainingSettings(TrainingSettings())}.isFailure)
        assertArrayEquals(before,local.read())
    }
    @Test fun revocationDuringCustomMaterializationCannotCommitDraftOrCatalog() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val owner="test-action-midflight-${java.util.UUID.randomUUID()}"
        val local=LocalSnapshotStore(ctx,owner)
        val before=JSONObject().put("exercises",JSONArray()).put("routines",JSONArray()).put("workouts",JSONArray()).toString().toByteArray()
        local.write(before)
        var allowed=true
        val repo=WorkoutRepository(ctx,owner,stillAuthorized={allowed})
        val drafts=listOf(RoutineBlockDraft(format="strength",entries=listOf(RoutineDraftEntry("pending:Fixture ejercicio",5))))
        assertTrue(runCatching {repo.createRoutineFromDrafts("Borrador",drafts) {allowed=false;true}}.isFailure)
        assertArrayEquals(before,local.read())
    }
}
