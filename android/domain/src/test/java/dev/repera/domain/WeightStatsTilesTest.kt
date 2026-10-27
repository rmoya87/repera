package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Locale

class WeightStatsTilesTest {
    @Test fun showsPlaceholdersWhenDataIsMissingAndSignedDeltaOtherwise() {
        val old = Locale.getDefault(); Locale.setDefault(Locale.US)
        try {
            assertEquals(WeightStatsTiles.Labels("—", "—", "—"), WeightStatsTiles.labels(null, null))
            assertEquals(WeightStatsTiles.Labels("80.0 kg", "—", "—"), WeightStatsTiles.labels(80.0, null))
            assertEquals(WeightStatsTiles.Labels("—", "74.0 kg", "—"), WeightStatsTiles.labels(null, 74.0))
            assertEquals(WeightStatsTiles.Labels("80.5 kg", "74.0 kg", "+6.5 kg"), WeightStatsTiles.labels(80.5, 74.0))
            assertEquals("-1.0 kg", WeightStatsTiles.labels(73.0, 74.0).delta)
        } finally { Locale.setDefault(old) }
    }
}
