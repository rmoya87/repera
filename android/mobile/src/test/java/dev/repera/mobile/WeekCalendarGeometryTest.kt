package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Test

/** Formulas calcadas de HomeView.weekSelectorCard en el corte Apple 0a640da8. */
class WeekCalendarGeometryTest {
    @Test fun compactKeepsSevenDays() {
        // iPhone retrato 393pt: 7 dias, hueco 4, lado (393-24)/7.
        assertEquals(7, WeekCalendarGeometry.visibleDays(393f))
        assertEquals(4f, WeekCalendarGeometry.spacingDp(393f), 0.01f)
        assertEquals(52.71f, WeekCalendarGeometry.sideDp(393f), 0.01f)
    }
    @Test fun compactSideCappedAtSixtyFour() {
        // 500pt sigue compacto: (500-24)/7 = 68 -> tapa 64.
        assertEquals(64f, WeekCalendarGeometry.sideDp(500f), 0.01f)
    }
    @Test fun expandedShowsMoreThanSevenDays() {
        // 1000pt: (1000+4)/(64+12) = 13, lado 64, hueco (1000-832)/12 = 14.
        assertEquals(13, WeekCalendarGeometry.visibleDays(1000f))
        assertEquals(64f, WeekCalendarGeometry.sideDp(1000f), 0.01f)
        assertEquals(14f, WeekCalendarGeometry.spacingDp(1000f), 0.01f)
    }
    @Test fun expandedBoundaryAt620() {
        assertEquals(false, WeekCalendarGeometry.isExpanded(619f))
        assertEquals(true, WeekCalendarGeometry.isExpanded(620f))
        // 620: (624)/76 = 8 dias; lado 64; hueco (620-512)/7 = 15.43.
        assertEquals(8, WeekCalendarGeometry.visibleDays(620f))
        assertEquals(15.43f, WeekCalendarGeometry.spacingDp(620f), 0.01f)
    }
}
