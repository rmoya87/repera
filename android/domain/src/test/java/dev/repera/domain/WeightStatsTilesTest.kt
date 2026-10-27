package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class WeightStatsTilesTest {
    @Test fun showsPlaceholdersWhenDataIsMissingAndSignedDeltaOtherwise() {
        // Expectativas actualizadas al formato recortado ReperaNumberFormat.decimal
        // (0b450bca: Apple sustituyó fractionLength(1) por decimal, que recorta
        // ceros y usa separadores españoles independientemente del locale).
        assertEquals(WeightStatsTiles.Labels("—", "—", "—"), WeightStatsTiles.labels(null, null))
        assertEquals(WeightStatsTiles.Labels("80 kg", "—", "—"), WeightStatsTiles.labels(80.0, null))
        assertEquals(WeightStatsTiles.Labels("—", "74 kg", "—"), WeightStatsTiles.labels(null, 74.0))
        assertEquals(WeightStatsTiles.Labels("80,5 kg", "74 kg", "+6,5 kg"), WeightStatsTiles.labels(80.5, 74.0))
        assertEquals("-1 kg", WeightStatsTiles.labels(73.0, 74.0).delta)
    }
}
