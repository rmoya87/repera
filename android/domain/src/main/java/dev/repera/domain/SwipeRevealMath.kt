package dev.repera.domain

import kotlin.math.max
import kotlin.math.min

/**
 * Matemáticas del gesto swipe-to-delete de las tarjetas de registro en Inicio
 * (port 1:1 de SwipeRevealMath.swift iOS). Valores en píxeles; el offset es
 * negativo hacia la izquierda y nunca pasa de 0 a la derecha ni de
 * -revealWidth a la izquierda.
 */
object SwipeRevealMath {

    fun clampedOffset(start: Float, translation: Float, revealWidth: Float): Float =
        min(0f, max(start + translation, -revealWidth))

    /** `true` si el toque está fuera de la franja inferior de chips. */
    fun shouldBeginSwipe(locationY: Float, viewHeight: Float, chipsBandHeight: Float): Boolean =
        locationY <= viewHeight - chipsBandHeight

    fun shouldOpen(projected: Float, current: Float, revealWidth: Float): Boolean =
        projected < -revealWidth * 0.45f || current < -revealWidth * 0.45f
}
