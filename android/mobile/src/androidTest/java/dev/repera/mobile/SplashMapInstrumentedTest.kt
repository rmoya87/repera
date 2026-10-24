package dev.repera.mobile

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.test.ext.junit.runners.AndroidJUnit4
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Splash y mapa con fixtures sintéticos:
 * - LaunchSplashScreen: el fondo verde de marca (0xFF30D158) domina la captura
 *   (gate de píxeles; la mascota ocupa el centro).
 * - RouteMapView: con o sin red, nunca un hueco en blanco — mapa real
 *   (tag route_map) o degradado Canvas con atribución (tag route_map_fallback).
 */
@RunWith(AndroidJUnit4::class)
class SplashMapInstrumentedTest {

    @get:Rule
    val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()

    @Test fun splashShowsBrandGreenBackground() {
        compose.setContent { LaunchSplashScreen() }
        compose.waitForIdle()
        val bmp = compose.onRoot().captureToImage().asAndroidBitmap()
        var green = 0
        var total = 0
        for (x in 0 until bmp.width step 12) {
            for (y in 0 until bmp.height step 12) {
                val c = bmp.getPixel(x, y)
                total++
                if (android.graphics.Color.green(c) > 150 &&
                    android.graphics.Color.red(c) < 120 &&
                    android.graphics.Color.blue(c) < 140) green++
            }
        }
        assertTrue("el fondo verde de marca debe dominar el splash " +
            "($green/$total)", green * 2 > total)
    }

    @Test fun routeMapNeverBlankWithSyntheticPoints() {
        val points = listOf(
            WorkoutRoutePoint(id = 1, latitude = 40.4168, longitude = -3.7038,
                recordedAtEpochMs = 1_000L, speedMps = 2.0),
            WorkoutRoutePoint(id = 2, latitude = 40.4178, longitude = -3.7028,
                recordedAtEpochMs = 2_000L, speedMps = 2.4),
            WorkoutRoutePoint(id = 3, latitude = 40.4188, longitude = -3.7018,
                recordedAtEpochMs = 3_000L, speedMps = 1.8)
        )
        compose.setContent {
            androidx.compose.material3.MaterialTheme {
                RouteMapView(points = points, isInteractive = false)
            }
        }
        compose.waitForIdle()
        val real = runCatching {
            compose.onNodeWithTag("route_map").assertIsDisplayed(); true
        }.getOrDefault(false)
        val fallback = runCatching {
            compose.onNodeWithTag("route_map_fallback").assertIsDisplayed(); true
        }.getOrDefault(false)
        assertTrue("el mapa real o su degradado deben estar presentes, nunca un hueco",
            real || fallback)
    }
}
