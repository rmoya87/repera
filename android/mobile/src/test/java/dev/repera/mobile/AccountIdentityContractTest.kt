package dev.repera.mobile

import org.junit.Assert.*
import org.junit.Test
import java.io.File

/**
 * Guardia ESTATICA (JVM, lee fuentes): documenta que dominio de identidad recibe cada almacen por cuenta.
 * Dominio Google = profile.uniqueId. Dominio Supabase = session.userId (UUID de GoTrue). El par se une en SessionStore y
 * accountWorkGuard comprueba ambos. NO ejecuta Android: no demuestra aislamiento en tiempo de ejecucion.
 * Los tests *KnownDivergence* fijan un hallazgo abierto; deben cambiar de aserto cuando se repare.
 */
class AccountIdentityContractTest {
    private val dir = File("src/main/java/dev/repera/mobile")
    private fun src(name: String) = File(dir, name).readText()
    private fun firstArgs(text: String, ctor: String): List<String> =
        Regex("""(?<![A-Za-z])${Regex.escape(ctor)}\(([^,)]*(?:\([^)]*\))?[^,)]*)""").findAll(text)
            .map { it.groupValues[1].trim() }.filter { !it.startsWith("val ") && !it.startsWith("private") && !it.startsWith("context:") }.toList()
    private fun allMain() = dir.listFiles { f -> f.name.endsWith(".kt") }!!.associate { it.name to it.readText() }

    @Test fun mirrorAiContextAndAiChangeStoresAreKeyedBySupabaseUserIdInMainActivity() {
        val main = src("MainActivity.kt")
        for (c in listOf("WorkoutMirrorStore", "AITrainingContextStore", "AIChangeRequestStore")) {
            // el primer argumento tras "this@MainActivity," es el id de cuenta
            val ids = Regex("""${c}\(this@MainActivity,\s*([A-Za-z.]+)""").findAll(main).map { it.groupValues[1] }.toList()
            assertTrue(c, ids.isNotEmpty()); assertTrue("$c $ids", ids.all { it == "session.userId" })
        }
    }

    @Test fun repositoryAndSnapshotStoresAreNeverKeyedBySupabaseUserId() {
        for ((name, text) in allMain()) {
            if (name == "WorkoutMirrorStore.kt") continue
            for (c in listOf("WorkoutRepository", "LocalSnapshotStore", "LiveRoutesStore", "RecentPlacesStore")) {
                Regex("""(?<![A-Za-z])${c}\([^,)]*,\s*([^,)]*)""").findAll(text).forEach {
                    assertFalse("$name $c ${it.groupValues[1]}", it.groupValues[1].contains("userId"))
                }
            }
        }
    }

    @Test fun knownDivergenceRepositoryInternalMirrorUsesGoogleIdWhileSyncUsesSupabaseId() {
        assertTrue(src("WorkoutRepository.kt").contains("private val mirror = WorkoutMirrorStore(context, googleId)"))
        assertTrue(src("MainActivity.kt").contains("WorkoutMirrorStore(this@MainActivity, session.userId"))
    }

    @Test fun knownDivergenceAiDecideNeverUsesItsMirrorParameter() {
        val text = src("AIChangeRequestStore.kt")
        val start = text.indexOf("fun decide(")
        val end = text.indexOf("private fun decideRemote", start)
        val body = text.substring(start, end)
        assertEquals(0, Regex("""[^A-Za-z]mirror\.""").findAll(body).count())
        assertTrue(body.contains("repository.deleteWorkout("))
    }

    @Test fun syncMirrorRepositoryCarriesTheAccountGuard() {
        val main = src("MainActivity.kt")
        val i = main.indexOf("private fun syncWorkoutMirror()")
        val body = main.substring(i, main.indexOf("\n    }\n", i))
        assertTrue(body.contains("WorkoutRepository(this@MainActivity, uniqueId, authorized)"))
    }
}
