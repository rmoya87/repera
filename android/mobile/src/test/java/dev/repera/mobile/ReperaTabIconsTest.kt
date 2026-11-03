package dev.repera.mobile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.PlayCircle
import org.junit.Assert.assertEquals
import org.junit.Test

class ReperaTabIconsTest {
    @Test
    fun startTabUsesOutlinedPlayWhenInactiveAndFilledPlayWhenSelected() {
        val start = reperaMainTabs.single { it.route == "en-vivo" }
        assertEquals(Icons.Outlined.PlayCircle, start.iconFor(false))
        assertEquals(Icons.Filled.PlayCircle, start.iconFor(true))
    }

    @Test
    fun progressTabUsesOutlinedBarsWhenInactiveAndFilledBarsWhenSelected() {
        val progress = reperaMainTabs.single { it.route == "progreso" }
        assertEquals(Icons.Outlined.BarChart, progress.iconFor(false))
        assertEquals(Icons.Filled.BarChart, progress.iconFor(true))
    }

    @Test
    fun plusTabHasNoVisibleTextButRetainsAccessibleName() {
        val plus = reperaMainTabs.single { it.route == "plus" }
        assertEquals(null, plus.visibleLabel)
        assertEquals("Clases y centro", plus.accessibilityLabel)
        assertEquals(
            listOf("Inicio", "Comenzar", "Progreso", "Ejercicios"),
            reperaMainTabs.filter { it.route != "plus" }.mapNotNull { it.visibleLabel }
        )
    }

    @Test
    fun plusTabOnlyExistsWithActiveCenterLink() {
        assertEquals(
            listOf("inicio", "en-vivo", "progreso", "ejercicios"),
            reperaTabsForCenter(hasLinkedCenter = false).map { it.route }
        )
        assertEquals(
            listOf("inicio", "en-vivo", "plus", "progreso", "ejercicios"),
            reperaTabsForCenter(hasLinkedCenter = true).map { it.route }
        )
    }

    @Test
    fun selectedTabDoesNotChangeIconsOnUnrelatedTabs() {
        val home = reperaMainTabs.single { it.route == "inicio" }
        val exercises = reperaMainTabs.single { it.route == "ejercicios" }
        assertEquals(home.iconFor(false), home.iconFor(true))
        assertEquals(exercises.iconFor(false), exercises.iconFor(true))
    }
}
