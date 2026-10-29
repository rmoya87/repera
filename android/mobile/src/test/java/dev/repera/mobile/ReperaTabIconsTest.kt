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
    fun selectedTabDoesNotChangeIconsOnUnrelatedTabs() {
        val home = reperaMainTabs.single { it.route == "inicio" }
        val exercises = reperaMainTabs.single { it.route == "ejercicios" }
        assertEquals(home.iconFor(false), home.iconFor(true))
        assertEquals(exercises.iconFor(false), exercises.iconFor(true))
    }
}
