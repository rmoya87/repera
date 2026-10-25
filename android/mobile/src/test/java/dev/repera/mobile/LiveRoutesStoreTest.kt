package dev.repera.mobile

import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class LiveRoutesStoreTest {
    @get:Rule val folder = TemporaryFolder()
    private val points = listOf(WorkoutRoutePoint(0,40.0,-3.0,0), WorkoutRoutePoint(1,40.01,-3.0,60_000))
    @Test fun favoriteEditAndGeometryRoundTripWithStableIdentity() {
        val file = File(folder.root,"routes.json"); val s = LiveRoutesStore(file)
        val r = s.addRecordedRoute("Ruta",points,"running",true,123L)
        s.update(r.id,"  Parque  ","walking")
        val restored = LiveRoutesStore(file).routes.single()
        assertEquals(r.id,restored.id); assertEquals("Parque",restored.title)
        assertEquals("walking",restored.sportID); assertTrue(restored.isFavorite)
        assertEquals(points,restored.points); assertTrue(restored.distanceKm > 1)
    }
    @Test fun tombstonesPreventRecoveryAfterRestartAndDoNotDuplicateRoutes() {
        val file = File(folder.root,"routes.json"); val s = LiveRoutesStore(file)
        val r = s.addRecordedRoute("Ruta",points,"running",true)
        s.remove(r.id)
        val restored = LiveRoutesStore(file); restored.recoverFromSessions(listOf(r,r))
        assertTrue(restored.routes.isEmpty())
        val fresh = r.copy(id="fresh")
        restored.recoverFromSessions(listOf(fresh,fresh))
        assertEquals(1,restored.routes.size); assertFalse(restored.routes.single().isFavorite)
    }
    @Test fun failedWriteLeavesMemoryUnchanged() {
        val file = File(folder.root,"routes.json"); val s = LiveRoutesStore(file)
        val r = s.addRecordedRoute("Ruta",points,"running")
        File(file.path+".tmp").mkdir(); File(file.path+".tmp/block").writeText("block")
        try { s.setFavorite(r.id,true); fail("write accepted") } catch (_: java.io.IOException) {}
        assertFalse(s.routes.single().isFavorite)
        assertFalse(LiveRoutesStore(file).routes.single().isFavorite)
    }
    @Test fun emptyNamesRejectedWithoutChangingIdentityOrMetadata() {
        val s = LiveRoutesStore(File(folder.root,"routes.json"))
        val r = s.addRecordedRoute("Ruta",points,"running")
        try { s.update(r.id," ",null); fail() } catch (_: IllegalArgumentException) {}
        assertEquals(r,s.routes.single())
    }
}
