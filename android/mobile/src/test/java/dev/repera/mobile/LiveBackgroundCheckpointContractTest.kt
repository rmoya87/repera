package dev.repera.mobile

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Apple f6f13169: al suspenderse la app hay un checkpoint GPS durable forzado
 *  (el throttling de 10s no debe perder los ultimos fixes). Contrato de cableado;
 *  la escritura real en suspension queda para validacion runtime. */
class LiveBackgroundCheckpointContractTest {
    private fun src(name: String) = File("src/main/java/dev/repera/mobile/$name").readText()

    @Test fun onStopForcesDurableCheckpoint() {
        assertTrue(src("MainActivity.kt").contains("LiveActivityRuntime.checkpointForBackground()"))
        assertTrue(src("LiveActivityRuntime.kt").contains("fun checkpointForBackground() { current?.checkpoint(true) }"))
    }

    @Test fun forceBypassesThrottle() {
        val body = src("LiveActivityRuntime.kt")
        assertTrue(body.contains("if (!force && now-lastSaveMillis<10_000) return"))
    }
}
