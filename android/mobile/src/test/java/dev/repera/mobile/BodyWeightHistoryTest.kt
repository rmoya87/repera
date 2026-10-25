package dev.repera.mobile
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
import java.time.*
class BodyWeightHistoryTest {
    @Test fun datesUseLocalCalendarAndHistoryIsNotLimitedToChartRange() {
        val zone=ZoneId.of("Europe/Madrid")
        assertEquals(LocalDate.of(2026,10,25),BodyWeightHistory.day("2026-10-24T22:30:00Z",zone))
        val state=JSONObject("""{"bodyWeights":[{"id":"old","date":"2020-01-01","weightKg":70,"source":"health"},{"id":"new","date":"2026-10-24T22:30:00Z","weightKg":80,"source":"manual"},{"id":"bad","date":"bad","weightKg":75}]}""")
        val entries=BodyWeightHistory.entries(state,zone)
        assertEquals(listOf("new","old"),entries.map {it.id})
        assertEquals("health",entries.last().source)
    }
    @Test fun invalidValuesCannotBecomeEntries() {
        val state=JSONObject("""{"bodyWeights":[{"id":"a","date":"2026-10-25","weightKg":0},{"date":"2026-10-25","weightKg":80},{"id":"b","date":"2026-10-25","weightKg":80}]}""")
        assertEquals(listOf("b"),BodyWeightHistory.entries(state).map {it.id})
    }
}
