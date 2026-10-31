package dev.repera.domain

import org.junit.Assert.*
import org.junit.Test

/** Apple live main (26 Oct): catálogo de deportes ampliado y estímulo muscular de sesiones «Comenzar». JVM only. */
class NativeSportStimuliTest {
    private fun w(sport: String?, minutes: Double, finished: Boolean = true, epoch: Long = 1_000L) =
        StatsWorkout(epoch, minutes, finished, liveSportID = sport)

    @Test fun newSportsExistAreSelectableAndGrouped() {
        val selectable = listOf(
            "boxing", "kickboxing", "martialArts", "wrestling", "badminton", "pickleball", "squash",
            "functionalStrength", "coreTraining", "americanFootball", "baseball",
            "hockey", "lacrosse", "rugby"
        )
        for (id in selectable) {
            val s = LiveSport.byId(id)
            assertNotNull(id, s); assertTrue(s!!.isSelectable); assertTrue(LiveSport.groups.contains(s.group))
        }
        for (legacy in listOf("elliptical", "stairClimbing", "softball")) {
            val s = LiveSport.byId(legacy)!!
            assertFalse(legacy, s.isSelectable)
            assertTrue(LiveSport.groups.contains(s.group))
        }
        assertTrue(LiveSport.GRAVEL.isSelectable && LiveSport.OTHER.isSelectable)
        assertEquals("Combate", LiveSport.BOXING.group)
        assertEquals("figure.kickboxing", LiveSport.KICKBOXING.symbol)
        assertEquals("figure.wrestling", LiveSport.WRESTLING.symbol)
        assertEquals("figure.american.football", LiveSport.AMERICAN_FOOTBALL.symbol)
        assertEquals("figure.baseball", LiveSport.BASEBALL.symbol)
        assertEquals("figure.field.hockey", LiveSport.HOCKEY.symbol)
        assertEquals("figure.lacrosse", LiveSport.LACROSSE.symbol)
        assertEquals("figure.rugby", LiveSport.RUGBY.symbol)
        assertTrue("crossfit" in LiveSport.cardioLiveSports && "rugby" in LiveSport.cardioLiveSports)
        assertFalse("coreTraining" in LiveSport.cardioLiveSports)
    }

    @Test fun nativeStimuliNeedFinishedSportAndDuration() {
        assertEquals(1, HealthMuscleMapper.nativeSportStimuli(listOf(w("boxing", 30.0))).size)
        assertTrue(HealthMuscleMapper.nativeSportStimuli(listOf(w("boxing", 0.0))).isEmpty())
        assertTrue(HealthMuscleMapper.nativeSportStimuli(listOf(w("boxing", 30.0, finished = false))).isEmpty())
        assertTrue(HealthMuscleMapper.nativeSportStimuli(listOf(w(null, 30.0))).isEmpty())
        val s = HealthMuscleMapper.nativeSportStimuli(listOf(w("boxing", 30.0, epoch = 777L))).single()
        assertEquals(777L, s.epochMillis)
        assertEquals(HealthMuscleMapper.muscleLoad("boxing", 30.0), s.load)
    }

    @Test fun highEffortLayerOnlyTakesIntenseModalities() {
        val native = listOf(w("running", 40.0), w("kickboxing", 40.0), w("crossfit", 40.0), w("padel", 40.0))
        assertEquals(2, HealthMuscleMapper.nativeHighEffortSportStimuli(native).size)
        val ext = listOf(HealthMuscleMapper.ExternalActivity(1L, "walking", 30.0),
            HealthMuscleMapper.ExternalActivity(2L, "highIntensityIntervalTraining", 30.0))
        assertEquals(listOf(2L), HealthMuscleMapper.highEffortStimuli(ext).map { it.epochMillis })
    }

    @Test fun genericAndMindBodyActivitiesAreNotCardioMinutes() {
        for (t in listOf("coreTraining", "yoga", "pilates", "flexibility", "cooldown", "other")) assertFalse(t, HealthMuscleMapper.isCardio(t))
        assertTrue(HealthMuscleMapper.isCardio("soccer"))
    }
}
