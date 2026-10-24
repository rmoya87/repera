package dev.repera.domain

/**
 * Port exacto de MotionRepCounter (RepCounter.swift): heurística de picos
 * sobre la magnitud de la aceleración de usuario (sin gravedad), en unidades
 * G. La conversión desde m/s² (SensorManager) la hace el emisor dividiendo
 * por 9.80665, igual que userAcceleration de CoreMotion. La UI siempre
 * ofrece corrección manual ± (applyManualDelta).
 */
class MotionRepCounter(
    private val threshold: Double = 1.35,
    private val minIntervalSeconds: Double = 0.45
) {
    private var lastMagnitude: Double = 0.0
    private var rising = false
    private var lastRepAtSeconds: Double = Double.NEGATIVE_INFINITY

    var count: Int = 0
        private set

    fun reset() {
        count = 0
        lastMagnitude = 0.0
        rising = false
        lastRepAtSeconds = Double.NEGATIVE_INFINITY
    }

    fun ingest(magnitude: Double, atSeconds: Double) {
        if (magnitude > lastMagnitude) {
            rising = true
        } else if (rising && lastMagnitude >= threshold && magnitude < lastMagnitude) {
            if (atSeconds - lastRepAtSeconds >= minIntervalSeconds) {
                count += 1
                lastRepAtSeconds = atSeconds
            }
            rising = false
        }
        lastMagnitude = magnitude
    }

    fun applyManualDelta(delta: Int) {
        count = maxOf(0, count + delta)
    }
}
