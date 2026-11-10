package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Test

class ForegroundNotificationPermissionTest {
    @Test fun preAndroid13NeverRequests() {
        assertEquals(ForegroundNotificationDecision.START,
            foregroundNotificationDecision(32, granted = false, requests = 0, rationale = false))
    }

    @Test fun grantedStartsImmediately() {
        assertEquals(ForegroundNotificationDecision.START,
            foregroundNotificationDecision(33, granted = true, requests = 2, rationale = false))
    }

    @Test fun firstInstallRequestsDespiteFalseRationale() {
        assertEquals(ForegroundNotificationDecision.REQUEST,
            foregroundNotificationDecision(33, granted = false, requests = 0, rationale = false))
    }

    @Test fun firstDenialAllowsSecondNativeRequest() {
        assertEquals(ForegroundNotificationDecision.REQUEST,
            foregroundNotificationDecision(33, granted = false, requests = 1, rationale = true))
        assertEquals(ForegroundNotificationDecision.REQUEST,
            foregroundNotificationDecision(33, granted = false, requests = 1, rationale = false))
    }

    @Test fun repeatedDenialGoesToSettingsInsteadOfSystemDialog() {
        assertEquals(ForegroundNotificationDecision.SETTINGS,
            foregroundNotificationDecision(33, granted = false, requests = 2, rationale = false))
    }

    @Test fun rationaleAfterTwoRequestsStillPermitsDialog() {
        assertEquals(ForegroundNotificationDecision.REQUEST,
            foregroundNotificationDecision(35, granted = false, requests = 2, rationale = true))
    }
}
