package dev.repera.domain

/**
 * Pasos y distancia de UNA sesión (Apple HealthKitStore.workoutMovementMetrics, live main 26 Oct).
 * Nunca se estiman a partir de kcal, pulso ni zancada. `usesTimeWindow` = muestras de un único origen distinto del de la sesión dentro del
 * rango de la sesión asociada (Apple: «en horario»; aquí sin sumar orígenes), frente a muestras del origen de la sesión asociada.
 *
 * Mapeo Android (NO equivalencia): Health Connect no enlaza muestras a un ejercicio ni distingue modalidades en
 * `DistanceRecord`; «asociado» = mismo origen (paquete) que la sesión de Salud asociada y dentro de su rango;
 * la etiqueta sale del tipo de ejercicio, y en mixtos es «Distancia recorrida» (no se puede saber la modalidad).
 */
data class SessionMovement(
    val steps: Int?,
    val distanceMeters: Double?,
    val distanceLabel: String?,
    val usesTimeWindow: Boolean
)

object SessionMovementMetrics {
    private val mixed = setOf("crossTraining", "functionalStrengthTraining", "traditionalStrengthTraining",
        "highIntensityIntervalTraining")
    // Apple: la distancia de agua es del propio HKWorkout/GPX; nunca reutilizar distancia a pie.
    private val water = setOf("surfingSports", "paddleSports", "rowing", "sailing")

    /** null = este tipo no muestra distancia de muestras sueltas. */
    fun distanceLabel(typeKey: String?): String? = when (typeKey) {
        in water -> null
        "downhillSkiing", "snowboarding" -> "Distancia nieve"
        "cycling" -> "Distancia bici"
        "swimming" -> "Distancia nado"
        in mixed -> "Distancia recorrida"
        else -> "Distancia a pie"
    }

    /** Ventana sin asociación: solo con UN origen; varios orígenes pueden duplicar el mismo dato y no hay
     *  prioridad conocida aquí, así que no se suman ni se elige uno (fail-closed). */
    fun windowTotal(perOrigin: Map<String, Double>): Double? =
        perOrigin.values.singleOrNull()?.takeIf { it.isFinite() && it > 0 }

    private fun positive(v: Double?): Double? = v?.takeIf { it.isFinite() && it > 0 }

    fun resolve(typeKey: String?, associatedSteps: Double?, windowSteps: Double?,
                associatedMeters: Double?, windowMeters: Double?): SessionMovement? {
        val steps = positive(associatedSteps) ?: positive(windowSteps)
        val stepsTimed = positive(associatedSteps) == null && positive(windowSteps) != null
        val label = distanceLabel(typeKey)
        val meters = if (label == null) null else positive(associatedMeters) ?: positive(windowMeters)
        val metersTimed = label != null && positive(associatedMeters) == null && positive(windowMeters) != null
        if (steps == null && meters == null) return null
        return SessionMovement(steps?.let { Math.round(it).toInt() }, meters, label.takeIf { meters != null },
            stepsTimed || metersTimed)
    }
}
