package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class ExerciseEquipmentGroupTest {

    private fun cat(name: String, equipment: String? = null) =
        ExerciseEquipmentGroup.category(name, equipment)

    @Test fun specificMachinesBeatGenericEquipmentLabel() {
        assertEquals("SkiErg / esquí de aire", cat("SkiErg", "Máquina"))
        assertEquals("Remoergómetros", cat("Remo máquina", "Máquina"))
        assertEquals("GHD", cat("GHD sit-up", "Máquina"))
        assertEquals("Bicicletas y Air Bikes", cat("Echo Bike", "Máquina"))
    }

    @Test fun hyroxStationsClassifyByName() {
        assertEquals("Trineos", cat("Sled push", "Trineo"))
        assertEquals("Trineos", cat("Sled pull", "Trineo"))
        assertEquals("Sacos de arena", cat("Sandbag Lunges", "Saco"))
        assertEquals("Wall Balls", cat("Wall ball", "Balón medicinal"))
        assertEquals("Sacos de arena", cat("Farmer carry", "Saco"))
    }

    @Test fun primaryChipWinsWithMultipleEquipment() {
        // «Barra, Banco» se ordena por la barra (primer chip), como iOS.
        assertEquals("Barras", cat("Press banca", "Barra, Banco"))
        assertEquals("Mancuernas", cat("Press banca", "Mancuernas, Banco"))
    }

    @Test fun bodyweightVariantsAndUnknowns() {
        assertEquals("Peso corporal", cat("Flexiones", "Peso corporal"))
        assertEquals("Sin material", cat("Estiramiento", null))
        assertEquals("Sin material", cat("Estiramiento", ""))
        // Etiqueta de usuario desconocida: se preserva, nunca se descarta.
        assertEquals("TRX", cat("Remo TRX", "TRX"))
    }

    @Test fun normalizationIgnoresAccentsAndCase() {
        assertEquals("Anillas", cat("Muscle-up anillas", "Peso corporal"))
        assertEquals("Combas", cat("Double-under", "Comba"))
        assertEquals("Barras de dominadas", cat("Chest to bar", "Barra fija"))
        assertEquals("Paredes", cat("Wall walk", "Peso corporal"))
        assertEquals("Cajones", cat("Burpee Box Jump Over", "Peso corporal"))
    }
}
