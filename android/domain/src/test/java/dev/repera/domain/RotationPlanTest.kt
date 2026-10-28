package dev.repera.domain
import org.junit.Assert.*
import org.junit.Test
class RotationPlanTest {
    @Test fun emptyNegativeIndexAndWrapMatchApple() {
        assertNull(RotationPlan("r").nextRoutineId)
        val p=RotationPlan("r",routineIds=listOf("a","b","c"),nextIndex=-1)
        assertEquals("c",p.nextRoutineId)
        assertEquals("a",p.copy(nextIndex=2).advanced().nextRoutineId)
    }
    @Test fun moveKeepsIndexRatherThanFollowingMovedIdentity() {
        val p=RotationPlan("r",routineIds=listOf("a","b","c"),nextIndex=1)
        val moved=p.moved(0,2)
        assertEquals(listOf("b","c","a"),moved.routineIds);assertEquals("c",moved.nextRoutineId)
        assertEquals(p,p.moved(-1,1))
    }
}
