package dev.repera.mobile

import dev.repera.domain.ProgressTimeRange
import java.time.DayOfWeek
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Fixture con fechas REALES (main 25/10): weekday/columna/fila afirmados,
 *  no semejanza visual. */
class HeatmapGridModelTest {

    private fun levelsEnding(today: LocalDate, days: Int): List<Pair<LocalDate, Int>> =
        (0 until days).map { i -> today.minusDays((days - 1 - i).toLong()) to (i % 5) }

    @Test
    fun rejillaDomingo_hoyEnUltimaColumnaFila6_yFilasEmpiezanEnLunes() {
        // 25/10/2026 = DOMINGO. 90 días = 13 semanas atrás + la actual.
        val today = LocalDate.of(2026, 10, 25)
        val grid = buildHeatmapGrid(levelsEnding(today, 98), ProgressTimeRange.DAYS_90)
        assertFalse(grid.isStrip)
        assertEquals(14, grid.columns.size)
        // Cada columna empieza en lunes y sus filas son lun..dom.
        grid.columns.forEach { col ->
            assertEquals(DayOfWeek.MONDAY, col.cells[0].first!!.dayOfWeek)
            (0..6).forEach { d ->
                assertEquals(DayOfWeek.of(d + 1), col.cells[d].first!!.dayOfWeek)
            }
        }
        // Hoy = domingo = última columna, fila 6; sin celdas futuras ese día.
        val last = grid.columns.last()
        assertEquals(today, last.cells[6].first)
        assertFalse(last.cells[6].third)
        // Semana cerrada en domingo: ninguna celda futura en toda la rejilla.
        assertTrue(grid.columns.all { col -> col.cells.none { it.third } })
        // Nivel de hoy llega desde los niveles (último = (97 % 5) = 2).
        assertEquals(2, last.cells[6].second)
    }

    @Test
    fun rejillaMiercoles_celdasFuturasSoloTrasHoy_enUltimaColumna() {
        // 21/10/2026 = MIÉRCOLES: la última columna tiene futuro jue-dom.
        val today = LocalDate.of(2026, 10, 21)
        val grid = buildHeatmapGrid(levelsEnding(today, 35), ProgressTimeRange.MONTH)
        assertEquals(5, grid.columns.size)
        val last = grid.columns.last()
        assertEquals(today, last.cells[2].first) // miércoles = fila 2
        assertFalse(last.cells[2].third)
        assertTrue(last.cells[3].third) // jueves futuro
        assertTrue(last.cells[6].third) // domingo futuro
        assertEquals(0, last.cells[3].second) // futuro pinta nivel 0
    }

    @Test
    fun gutterEtiquetas_lunesMiercolesViernesReales() {
        val lunes = LocalDate.of(2026, 10, 19)
        assertEquals(listOf("L", "", "X", "", "V", "", ""), heatmapGutterLabels(lunes))
    }

    @Test
    fun etiquetasMes_septYOctEn90dTerminandoEl25Oct() {
        val today = LocalDate.of(2026, 10, 25)
        val grid = buildHeatmapGrid(levelsEnding(today, 98), ProgressTimeRange.DAYS_90)
        assertEquals(14, grid.monthLabels.size)
        val nonEmpty = grid.monthLabels.filter { it.isNotEmpty() }
        // Columnas con día ≤ 7 del mes y cambio de mes: ago, sept (oct queda
        // fuera por wk < weeksBack si su primera semana es la última).
        assertTrue(nonEmpty.contains("sept"))
        assertTrue(nonEmpty.contains("ago"))
    }

    @Test
    fun franjaSemana_sieteDiasConEtiquetasYHoyAlFinal() {
        val today = LocalDate.of(2026, 10, 25)
        val grid = buildHeatmapGrid(levelsEnding(today, 7), ProgressTimeRange.WEEK)
        assertTrue(grid.isStrip)
        assertEquals(7, grid.columns.size)
        assertEquals(DayOfWeek.MONDAY, grid.columns.first().cells[0].first!!.dayOfWeek)
        assertEquals(today, grid.columns.last().cells[0].first)
        assertEquals(7, grid.dayLabels.size)
        assertEquals("lun", grid.dayLabels.first())
        assertEquals("dom", grid.dayLabels.last())
    }
}
