package dev.repera.domain

import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class ActivityConditionsLogicTest {
    @Test
    fun familyForWaterSnowOutdoorNone() {
        assertEquals(ActivityConditionsFamily.WATER, ActivityConditionsSnapshot.familyForLiveSportId("surfing"))
        assertEquals(ActivityConditionsFamily.SNOW, ActivityConditionsSnapshot.familyForLiveSportId("skiing"))
        assertEquals(ActivityConditionsFamily.OUTDOOR, ActivityConditionsSnapshot.familyForLiveSportId("running"))
        assertEquals(ActivityConditionsFamily.NONE, ActivityConditionsSnapshot.familyForLiveSportId("yoga"))
    }

    @Test
    fun parseMarineTideTrendRising() {
        val forecast = """
            {"hourly":{"time":["2026-10-31T12:00","2026-10-31T13:00","2026-10-31T14:00"],
            "temperature_2m":[18.0,18.5,19.0],"wind_speed_10m":[12.0,13.0,14.0],
            "snowfall":[0,0,0],"snow_depth":[0,0,0]}}
        """.trimIndent()
        val marine = """
            {"hourly":{"time":["2026-10-31T12:00","2026-10-31T13:00","2026-10-31T14:00"],
            "sea_level_height_msl":[0.10,0.25,0.40],"wave_height":[0.8,0.9,1.0]}}
        """.trimIndent()
        val zone = ZoneId.systemDefault()
        val at = LocalDateTime.parse("2026-10-31T13:00", DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"))
            .atZone(zone).toInstant().toEpochMilli()
        val snap = ActivityConditionsLogic.parse(
            ActivityConditionsFamily.WATER, forecast, marine, at, zone
        )
        assertNotNull(snap)
        assertEquals(TideTrend.RISING, snap!!.tideTrend)
        assertEquals(0.9, snap.waveHeightMeters!!, 0.01)
        assertNotNull(snap.temperatureC)
    }

    @Test
    fun parseNoneFamilyReturnsNull() {
        assertNull(
            ActivityConditionsLogic.parse(
                ActivityConditionsFamily.NONE, "{}", null, System.currentTimeMillis()
            )
        )
    }
}
