package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.ZoneOffset

class HistoricalWeatherLogicTest {
    @Test
    fun roundCoordinate_matchesWeatherKitPrecision() {
        assertEquals(48.86, HistoricalWeatherLogic.roundCoordinate(48.8566), 0.0)
        assertEquals(2.35, HistoricalWeatherLogic.roundCoordinate(2.3522), 0.0)
    }

    @Test
    fun parseOpenMeteoHourly_picksClosestHour() {
        val body = """
            {
              "hourly": {
                "time": ["2026-10-29T14:00","2026-10-29T15:00","2026-10-29T16:00"],
                "temperature_2m": [14.0, 15.0, 16.0],
                "relative_humidity_2m": [55.0, 60.0, 65.0],
                "wind_speed_10m": [8.0, 10.0, 12.0],
                "weather_code": [1, 2, 3]
              }
            }
        """.trimIndent()
        val target = java.time.LocalDateTime.of(2026, 10, 29, 15, 10)
            .atZone(ZoneOffset.UTC).toInstant().toEpochMilli()
        val reading = HistoricalWeatherLogic.parseOpenMeteoHourly(
            body, target, ZoneOffset.UTC
        )
        assertNotNull(reading)
        assertEquals(15.0, reading!!.temperatureC, 0.01)
        assertEquals(0.60, reading.humidityFraction, 0.001)
        assertEquals(10.0, reading.windKmh, 0.01)
        assertEquals("15 °C", reading.temperatureLabel)
        assertEquals("60 %", reading.humidityLabel)
        assertEquals("10 km/h", reading.windLabel)
    }

    @Test
    fun parseOpenMeteoHourly_rejectsFarHours() {
        val body = """
            {
              "hourly": {
                "time": ["2026-10-29T01:00"],
                "temperature_2m": [10.0],
                "relative_humidity_2m": [50.0],
                "wind_speed_10m": [5.0]
              }
            }
        """.trimIndent()
        val target = java.time.LocalDateTime.of(2026, 10, 29, 15, 0)
            .atZone(ZoneOffset.UTC).toInstant().toEpochMilli()
        assertNull(HistoricalWeatherLogic.parseOpenMeteoHourly(body, target, ZoneOffset.UTC))
    }

    @Test
    fun archiveUrl_containsRoundedCoordsAndDay() {
        val url = HistoricalWeatherLogic.archiveUrl(48.8566, 2.3522, "2026-10-29")
        assert(url.contains("latitude=48.86"))
        assert(url.contains("longitude=2.35"))
        assert(url.contains("start_date=2026-10-29"))
        assert(url.contains("wind_speed_unit=kmh"))
    }
}
