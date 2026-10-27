package dev.repera.mobile

import androidx.health.connect.client.records.ExerciseRoute
import androidx.health.connect.client.units.Length
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class ExternalRouteSheetModelTest {

    private fun pt(lat: Double, lon: Double, t: Long) =
        WorkoutRoutePoint(id = 0, latitude = lat, longitude = lon, recordedAtEpochMs = t)

    @Test fun loadingWhileUnreadAndHiddenForUnavailableOrNoRoute() {
        assertEquals(ExternalRouteSheetModel.State.Loading,
            ExternalRouteSheetModel.present(null))
        assertEquals(ExternalRouteSheetModel.State.Hidden,
            ExternalRouteSheetModel.present(ExternalRouteRead.Unavailable))
        assertEquals(ExternalRouteSheetModel.State.Hidden,
            ExternalRouteSheetModel.present(ExternalRouteRead.NoRoute))
    }

    @Test fun consentRequiredMapsToConsentNeeded() {
        assertEquals(ExternalRouteSheetModel.State.ConsentNeeded,
            ExternalRouteSheetModel.present(ExternalRouteRead.ConsentRequired))
    }

    @Test fun twoOrMorePointsShownFewerHidden() {
        val one = ExternalRouteSheetModel.present(
            ExternalRouteRead.Points(listOf(pt(40.0, -3.7, 1000))))
        assertEquals(ExternalRouteSheetModel.State.Hidden, one)
        val points = listOf(pt(40.0, -3.7, 1000), pt(40.0001, -3.7, 2000))
        val shown = ExternalRouteSheetModel.present(ExternalRouteRead.Points(points))
        assertTrue(shown is ExternalRouteSheetModel.State.Shown)
        assertEquals(points, (shown as ExternalRouteSheetModel.State.Shown).points)
    }

    @Test fun exerciseRouteConvertsToDomainPoints() {
        val route = ExerciseRoute(listOf(
            ExerciseRoute.Location(
                time = Instant.ofEpochMilli(150_000),
                latitude = 40.0, longitude = -3.7,
                horizontalAccuracy = Length.meters(4.5),
                verticalAccuracy = Length.meters(9.0),
                altitude = Length.meters(666.0)),
            ExerciseRoute.Location(
                time = Instant.ofEpochMilli(160_000),
                latitude = 40.0001, longitude = -3.7001)
        ))
        val out = route.toWorkoutRoutePoints()
        assertEquals(2, out.size)
        assertEquals(40.0, out[0].latitude, 1e-9)
        assertEquals(-3.7, out[0].longitude, 1e-9)
        assertEquals(150_000L, out[0].recordedAtEpochMs)
        assertEquals(666.0, out[0].altitudeMeters!!, 1e-9)
        assertEquals(4.5, out[0].horizontalAccuracyMeters!!, 1e-9)
        assertEquals(9.0, out[0].verticalAccuracyMeters!!, 1e-9)
        assertNull(out[0].speedMps)          // HC Location no lleva velocidad
        assertNull(out[1].altitudeMeters)    // opcionales ausentes -> null
    }
}
