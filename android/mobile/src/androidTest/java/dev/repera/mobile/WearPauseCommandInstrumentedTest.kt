package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class WearPauseCommandInstrumentedTest {
 @Test fun delayedCommandOnlyTargetsItsOwnSession() {
  val command=WearPauseCommand.parse("""{"sessionId":"old","blockIndex":2,"paused":true}""".toByteArray())!!
  assertTrue(command.targets("old",2))
  assertFalse(command.targets("new",2))
  assertFalse(command.targets(null,null))
  assertFalse(command.targets("old",1))
  assertTrue(command.paused)
 }
 @Test fun malformedOrLegacyUnboundControlIsRejected() {
  listOf("""{"paused":true}""","""{"sessionId":"old"}""","""{"sessionId":"old","paused":"true"}""","""{"sessionId":"old","blockIndex":-1,"paused":true}""","""{"sessionId":"old","blockIndex":1.5,"paused":true}""","bad").forEach {
   assertNull(WearPauseCommand.parse(it.toByteArray()))
  }
 }
}
