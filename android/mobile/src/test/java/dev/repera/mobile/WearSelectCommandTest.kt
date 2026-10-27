package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test

class WearSelectCommandTest {
    private fun parse(s:String)=WearSelectCommand.parse(s.toByteArray())
    @Test fun validCommandTargetsOnlyItsSessionAndIndex() {
        val c=parse("""{"sessionId":"s1","fromIndex":1,"toIndex":3}""")!!
        assertTrue(c.targets("s1",1,5))
        assertFalse(c.targets("s2",1,5))
        assertFalse(c.targets("s1",2,5))
        assertFalse(c.targets(null,null,null))
    }
    @Test fun outOfRangeOrNoopTargetIsRejected() {
        assertFalse(parse("""{"sessionId":"s","fromIndex":0,"toIndex":5}""")!!.targets("s",0,5))
        assertFalse(parse("""{"sessionId":"s","fromIndex":2,"toIndex":2}""")!!.targets("s",2,5))
        assertTrue(parse("""{"sessionId":"s","fromIndex":0,"toIndex":4}""")!!.targets("s",0,5))
    }
    @Test fun malformedIsRejected() {
        listOf("""{"fromIndex":0,"toIndex":1}""","""{"sessionId":"s","fromIndex":0}""","""{"sessionId":"s","fromIndex":-1,"toIndex":1}""",
            """{"sessionId":"s","fromIndex":0,"toIndex":1.5}""","""{"sessionId":"s","fromIndex":"0","toIndex":1}""","bad").forEach {assertNull(it,parse(it))}
    }
}
