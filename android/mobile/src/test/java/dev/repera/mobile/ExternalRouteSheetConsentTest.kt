package dev.repera.mobile

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Consentimiento por sesion de la ruta externa: el boton lanza el contrato con
 *  el ID EXACTO del registro (doble onConsentLaunch; el contract HC real solo
 *  se valida en runtime con Activity). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class ExternalRouteSheetConsentTest {

    @get:Rule val composeRule = createComposeRule()

    private fun entry() = ExternalHealthHistoryEntry(
        id = "hc-42", title = "Carrera", startMillis = 1_000_000L,
        endMillis = 2_000_000L, minutes = 16.6, sourcePackage = "com.strava")

    @Test fun consentButtonLaunchesContractWithExactRecordId() {
        var launched: String? = null
        composeRule.setContent {
            MaterialTheme {
                ExternalHealthDetailSheet(entry(),
                    provider = { null },
                    routeReader = { ExternalRouteRead.ConsentRequired },
                    onConsentLaunch = { launched = it }) {}
            }
        }
        composeRule.onNodeWithTag("external_route_consent", useUnmergedTree = true)
            .assertExists().performClick()
        assertEquals("hc-42", launched)
    }

    @Test fun routeSectionShownWithAuthorizedPoints() {
        composeRule.setContent {
            MaterialTheme {
                ExternalHealthDetailSheet(entry(),
                    provider = { null },
                    routeReader = { ExternalRouteRead.Points(listOf(
                        WorkoutRoutePoint(0, 40.0, -3.7, 1_100_000L),
                        WorkoutRoutePoint(1, 40.001, -3.7, 1_160_000L))) },
                    onConsentLaunch = {}) {}
            }
        }
        composeRule.onNodeWithText("Recorrido GPS de la fuente", useUnmergedTree = true)
            .assertExists()
    }

    @Test fun noRouteSectionWhenUnavailableOrEmpty() {
        composeRule.setContent {
            MaterialTheme {
                ExternalHealthDetailSheet(entry(),
                    provider = { null },
                    routeReader = { ExternalRouteRead.Unavailable },
                    onConsentLaunch = {}) {}
            }
        }
        composeRule.onNodeWithText("Recorrido GPS de la fuente", useUnmergedTree = true)
            .assertDoesNotExist()
        composeRule.onNodeWithTag("external_route_consent", useUnmergedTree = true)
            .assertDoesNotExist()
    }
}
