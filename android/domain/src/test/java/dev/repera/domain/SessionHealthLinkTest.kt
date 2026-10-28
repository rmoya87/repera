package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

/** Reglas de vínculo sesión ↔ registro de Salud (resolveLink/validStoredLink):
 *  el vínculo persistido solo se reusa si pertenece a ESTA sesión y el
 *  registro sigue válido; la ambigüedad nunca cae a inserción. */
class SessionHealthLinkTest {

    private val own = "dev.repera"
    private val garmin = "com.garmin.android"
    private val sessionId = "ses-1"
    // Sesión Repera 10:00-11:00 (en minutos desde medianoche, a ms).
    private val sStart = 10 * 60 * 60_000L
    private val sEnd = 11 * 60 * 60_000L

    private fun candidate(
        id: String, startMin: Long, endMin: Long, pkg: String,
        clientRecordId: String? = null
    ) = SessionHealthMatcher.CandidateSession(
        id, startMin * 60_000, endMin * 60_000, pkg, clientRecordId)

    private fun decision(
        stored: String?, candidates: List<SessionHealthMatcher.CandidateSession>
    ) = SessionHealthMatcher.resolveLink(
        sessionId, sStart, sEnd, stored, candidates, own)

    @Test fun storedLinkToOwnRecordOfThisSessionIsReused() {
        val rec = candidate("r1", 600, 660, own,
            clientRecordId = HealthSessionLink.clientRecordId(sessionId))
        // Fuera de ventana incluso: el registro es PROPIO y de ESTA sesión.
        val far = candidate("r1", 100, 160, own,
            clientRecordId = HealthSessionLink.clientRecordId(sessionId))
        assertEquals(SessionHealthMatcher.LinkDecision.UseExisting("r1"),
            decision("r1", listOf(far)))
    }

    @Test fun storedLinkToExternalRecordPassingThresholdsIsReused() {
        val ext = candidate("g1", 602, 658, garmin)
        assertEquals(SessionHealthMatcher.LinkDecision.UseExisting("g1"),
            decision("g1", listOf(ext)))
    }

    @Test fun storedLinkToAnotherSessionsRecordIsNotReused() {
        // Registro propio pero con el clientRecordId de OTRA sesión, fuera de ventana.
        val other = candidate("rX", 100, 160, own,
            clientRecordId = HealthSessionLink.clientRecordId("ses-otra"))
        val d = decision("rX", listOf(other))
        // No hay nada asociable en ventana: toca insertar el registro de ESTA sesión.
        assertEquals(SessionHealthMatcher.LinkDecision.Insert, d)
    }

    @Test fun storedLinkToRecordOutsideWindowIsNotReused() {
        val extFar = candidate("g9", 100, 160, garmin)
        assertEquals(SessionHealthMatcher.LinkDecision.Insert,
            decision("g9", listOf(extFar)))
    }

    @Test fun staleStoredLinkRecordGoneFallsThrough() {
        assertEquals(SessionHealthMatcher.LinkDecision.Insert,
            decision("ya-no-existe", emptyList()))
    }

    @Test fun ownRecordWithClientRecordIdIsAdoptedWithoutStoredLink() {
        val rec = candidate("r7", 601, 659, own,
            clientRecordId = HealthSessionLink.clientRecordId(sessionId))
        assertEquals(SessionHealthMatcher.LinkDecision.UseExisting("r7"),
            decision(null, listOf(rec)))
    }

    @Test fun unambiguousExternalIsAdoptedWithoutWriting() {
        val ext = candidate("g1", 602, 658, garmin)
        assertEquals(SessionHealthMatcher.LinkDecision.UseExisting("g1"),
            decision(null, listOf(ext)))
    }

    @Test fun ambiguousAssociationSkipsWithoutInserting() {
        val a = candidate("g1", 600, 660, garmin)
        val b = candidate("g2", 601, 659, "com.polar.app")
        assertEquals(SessionHealthMatcher.LinkDecision.Skip,
            decision(null, listOf(a, b)))
    }

    @Test fun ownMatchedRecordWithoutClientRecordIdIsReusedLikeIosUpdate() {
        // iOS existingReperaWorkout actualiza el registro propio solapado en
        // vez de crear otro; sin clientRecordId (versiones antiguas) se reusa.
        val ownOld = candidate("r0", 602, 658, own)
        assertEquals(SessionHealthMatcher.LinkDecision.UseExisting("r0"),
            decision(null, listOf(ownOld)))
    }

    @Test fun validStoredLinkRejectsLinkOfAnotherSessionEvenInWindow() {
        // Explicit clientRecordId ownership beats an otherwise plausible time window.
        val other = candidate("rX", 602, 658, own,
            clientRecordId = HealthSessionLink.clientRecordId("ses-otra"))
        val v = SessionHealthMatcher.validStoredLink(
            sessionId, sStart, sEnd, "rX", listOf(other), own)
        assertEquals(null, v)
        assertEquals(SessionHealthMatcher.LinkDecision.Insert,decision("rX",listOf(other)))
        // Y fuera de ventana se rechaza:
        val far = candidate("rY", 100, 160, own,
            clientRecordId = HealthSessionLink.clientRecordId("ses-otra"))
        val rejected = SessionHealthMatcher.validStoredLink(
            sessionId, sStart, sEnd, "rY", listOf(far), own)
        assertEquals(null, rejected)
    }
    @Test fun readEligibilityRejectsOtherSessionAndUnboundOwnRecordButKeepsLegacyAndExternal() {
        val same=candidate("same",600,660,own,HealthSessionLink.clientRecordId(sessionId))
        val other=candidate("other",600,660,own,HealthSessionLink.clientRecordId("other"))
        val legacy=candidate("legacy",600,660,own)
        val external=candidate("external",600,660,garmin,"vendor-id")
        assertEquals(listOf(same,legacy,external),SessionHealthMatcher.eligibleForSession(sessionId,listOf(same,other,legacy,external),own))
        assertEquals(listOf(legacy,external),SessionHealthMatcher.eligibleForSession(null,listOf(same,other,legacy,external),own))
    }

    private val ownPkg = "dev.repera"
    private fun lrec(id: String, pkg: String, client: String? = null) = SessionHealthMatcher.CandidateSession(id, 0, 1000, pkg, client)

    @Test fun editedWindowKeepsPersistedExternalRecord() {
        val r = SessionHealthMatcher.resolveStoredLink("s1", "x1", SessionHealthMatcher.LinkLookup.Found(lrec("x1", "ext")), ownPkg)
        assertEquals(SessionHealthMatcher.LinkResolution.Use(lrec("x1", "ext")), r)
    }
    @Test fun unreadableNeverReassociates() {
        assertEquals(SessionHealthMatcher.LinkResolution.KeepLinkUnresolved,
            SessionHealthMatcher.resolveStoredLink("s1", "x1", SessionHealthMatcher.LinkLookup.Unreadable, ownPkg))
    }
    @Test fun verifiedAbsenceFreesWindowMatching() {
        assertEquals(SessionHealthMatcher.LinkResolution.FallBackToWindow,
            SessionHealthMatcher.resolveStoredLink("s1", "x1", SessionHealthMatcher.LinkLookup.Gone, ownPkg))
    }
    @Test fun noStoredLinkFallsBackAndOtherSessionsOwnRecordIsRejected() {
        assertEquals(SessionHealthMatcher.LinkResolution.FallBackToWindow,
            SessionHealthMatcher.resolveStoredLink("s1", null, SessionHealthMatcher.LinkLookup.Unreadable, ownPkg))
        assertEquals(SessionHealthMatcher.LinkResolution.FallBackToWindow,
            SessionHealthMatcher.resolveStoredLink("s1", "o2", SessionHealthMatcher.LinkLookup.Found(lrec("o2", ownPkg, HealthSessionLink.clientRecordId("s2"))), ownPkg))
        assertEquals(SessionHealthMatcher.LinkResolution.Use(lrec("o1", ownPkg, HealthSessionLink.clientRecordId("s1"))),
            SessionHealthMatcher.resolveStoredLink("s1", "o1", SessionHealthMatcher.LinkLookup.Found(lrec("o1", ownPkg, HealthSessionLink.clientRecordId("s1"))), ownPkg))
    }
}
