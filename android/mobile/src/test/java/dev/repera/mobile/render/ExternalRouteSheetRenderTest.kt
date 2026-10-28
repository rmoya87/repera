package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.onNodeWithTag
import dev.repera.mobile.ExternalHealthDetailColumn
import dev.repera.mobile.ExternalHealthHistoryEntry
import dev.repera.mobile.ExternalRouteRead
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/** Renders reales del consumidor de rutas externas (6826b9a7): mapa con ruta
 *  autorizada (fallback Canvas bajo Robolectric) y estado de consentimiento. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w360dp-h900dp")
class ExternalRouteSheetRenderTest {

    @get:Rule val composeRule = createComposeRule()

    private fun entry() = ExternalHealthHistoryEntry(
        id = "hc-42", title = "Carrera", startMillis = 1_000_000L,
        endMillis = 2_000_000L, minutes = 16.6, sourcePackage = "com.strava")

    private fun capture(name: String) {
        val bmp = composeRule.onNodeWithTag("sheet_root").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/$name").use {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    @Test fun sheetWithAuthorizedRoute() {
        composeRule.setContent {
            MaterialTheme {
                androidx.compose.foundation.layout.Box(Modifier.testTag("sheet_root")) {
                    ExternalHealthDetailColumn(entry(),
                        detail = dev.repera.mobile.ExternalHealthDetail(entry(),
                            heart = listOf(1_110_000L to 128, 1_170_000L to 141,
                                1_230_000L to 155, 1_290_000L to 149),
                            activeKcal = 210.0), loading = false,
                        routeRead = ExternalRouteRead.Points(
                            (0..20).map { i ->
                                WorkoutRoutePoint(i, 40.0 + i * 0.0004,
                                    -3.7 + i * 0.0002, 1_100_000L + i * 5_000L)
                            }),
                        onConsentLaunch = {},
                        consentRequestedFor = null,
                        onConsentRequested = {}) {}
                }
            }
        }
        composeRule.waitForIdle()
        capture("external-route-sheet-map.png")
    }

    @Test fun externalRoutePreviewOpensAndClosesFullscreen() {
        composeRule.setContent {
            MaterialTheme {
                ExternalHealthDetailColumn(entry(),detail=null,loading=false,
                    routeRead=ExternalRouteRead.Points(listOf(
                        WorkoutRoutePoint(0,40.0,-3.7,1_100_000L),
                        WorkoutRoutePoint(1,40.001,-3.699,1_160_000L))),
                    onConsentLaunch={},consentRequestedFor=null,onConsentRequested={}) {}
            }
        }
        composeRule.onNodeWithContentDescription("Ampliar recorrido de Salud").performClick()
        composeRule.onNodeWithTag("fullscreen-route-map").assertExists()
        val bmp=composeRule.onNodeWithTag("fullscreen-route-root").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/external-route-fullscreen.png").use {
            bmp.compress(Bitmap.CompressFormat.PNG,100,it)
        }
        composeRule.onNodeWithTag("fullscreen-route-close").performClick()
        composeRule.onNodeWithTag("fullscreen-route-map").assertDoesNotExist()
    }

    @Test fun externalRouteFullscreenDarkContrast() {
        composeRule.setContent {
            MaterialTheme(colorScheme=dev.repera.mobile.reperaColorScheme(true)) {
                ExternalHealthDetailColumn(entry(),detail=null,loading=false,
                    routeRead=ExternalRouteRead.Points(listOf(
                        WorkoutRoutePoint(0,40.0,-3.7,1_100_000L),
                        WorkoutRoutePoint(1,40.001,-3.699,1_160_000L))),
                    onConsentLaunch={},consentRequestedFor=null,onConsentRequested={}) {}
            }
        }
        composeRule.onNodeWithContentDescription("Ampliar recorrido de Salud").performClick()
        composeRule.onNodeWithTag("fullscreen-route-map").assertExists()
        val bmp=composeRule.onNodeWithTag("fullscreen-route-root").captureToImage().asAndroidBitmap()
        File("build/reports/render").mkdirs()
        FileOutputStream("build/reports/render/external-route-fullscreen-dark.png").use {
            bmp.compress(Bitmap.CompressFormat.PNG,100,it)
        }
        composeRule.onNodeWithTag("fullscreen-route-close").performClick()
        composeRule.onNodeWithTag("fullscreen-route-map").assertDoesNotExist()
    }

    @Test fun sheetWithConsentNeeded() {
        composeRule.setContent {
            MaterialTheme {
                androidx.compose.foundation.layout.Box(Modifier.testTag("sheet_root")) {
                    ExternalHealthDetailColumn(entry(),
                        detail = dev.repera.mobile.ExternalHealthDetail(entry(),
                            heart = listOf(1_110_000L to 128, 1_170_000L to 141),
                            activeKcal = 210.0), loading = false,
                        routeRead = ExternalRouteRead.ConsentRequired,
                        onConsentLaunch = {},
                        consentRequestedFor = null,
                        onConsentRequested = {}) {}
                }
            }
        }
        composeRule.waitForIdle()
        capture("external-route-sheet-consent.png")
    }
}
