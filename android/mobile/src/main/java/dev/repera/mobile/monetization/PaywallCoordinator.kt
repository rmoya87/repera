package dev.repera.mobile.monetization

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import dev.repera.domain.monetization.PaywallContext

/** Evita paywalls simultáneos por pulsaciones rápidas. Port 1:1 de PaywallCoordinator.swift. */
class PaywallCoordinator {
    var isPresented by mutableStateOf(false)
        private set
    var context: PaywallContext by mutableStateOf(PaywallContext.GENERIC)
        private set

    fun present(context: PaywallContext) {
        if (isPresented) {
            this.context = context
            return
        }
        this.context = context
        isPresented = true
    }

    fun dismiss() {
        isPresented = false
    }
}

val PaywallContext.headline: String
    get() = when (this) {
        PaywallContext.ROUTINES_LIMIT -> "Todas tus rutinas, sin límites"
        PaywallContext.CUSTOM_EXERCISES_LIMIT -> "Tus ejercicios, sin límites"
        PaywallContext.BOARD_SCANS_LIMIT -> "Cada pizarra, lista para entrenar"
        PaywallContext.EXERCISE_EVOLUTION, PaywallContext.EXERCISE_HISTORY -> "Descubre cómo estás progresando"
        PaywallContext.WOD_HISTORY -> "Supera tus mejores marcas"
        PaywallContext.PROGRESS -> "Analiza toda tu evolución"
        PaywallContext.MUSCLE_ANALYSIS -> "Conoce tu equilibrio muscular"
        PaywallContext.ADVANCED_PROGRESSION -> "Progresión a tu medida"
        PaywallContext.SETTINGS, PaywallContext.GENERIC -> "Repera Pro"
        PaywallContext.ONBOARDING -> "Lleva Repera al siguiente nivel"
    }

val PaywallContext.subtitle: String
    get() = when (this) {
        PaywallContext.ROUTINES_LIMIT ->
            "Guarda todas las plantillas que necesites y organízalas a tu ritmo."
        PaywallContext.CUSTOM_EXERCISES_LIMIT ->
            "Añade todos los ejercicios propios que uses en el gym."
        PaywallContext.BOARD_SCANS_LIMIT ->
            "Escanea pizarras sin cuota mensual."
        PaywallContext.EXERCISE_EVOLUTION, PaywallContext.EXERCISE_HISTORY ->
            "Consulta todas tus marcas, compara entrenos y ve tu evolución."
        PaywallContext.WOD_HISTORY ->
            "Compara intentos, mejoras y tu mejor marca histórica."
        PaywallContext.PROGRESS ->
            "Entrena como siempre. Descubre hasta dónde puedes llegar."
        PaywallContext.MUSCLE_ANALYSIS ->
            "Visualiza grupos musculares y cómo se reparte tu entrenamiento."
        PaywallContext.ADVANCED_PROGRESSION ->
            "Recomendaciones de carga según tu historial y esfuerzo."
        PaywallContext.SETTINGS, PaywallContext.GENERIC ->
            "Entrena como siempre. Descubre hasta dónde puedes llegar."
        PaywallContext.ONBOARDING ->
            "Historial completo, progreso avanzado, escáner ilimitado y más. También puedes empezar gratis."
    }

val PaywallContext.prioritizedBenefits: List<String>
    get() {
        var base = listOf(
            "Historial y evolución por ejercicio",
            "Estadísticas completas de progreso",
            "Marcas y comparativas de WOD",
            "Mapa muscular y análisis avanzado",
            "Escaneos ilimitados de pizarra",
            "Rutinas ilimitadas"
        )
        when (this) {
            PaywallContext.ROUTINES_LIMIT ->
                base = listOf("Rutinas ilimitadas") + base.filter { !it.contains("Rutinas") }
            PaywallContext.CUSTOM_EXERCISES_LIMIT ->
                base = listOf("Ejercicios personalizados ilimitados") + base
            PaywallContext.BOARD_SCANS_LIMIT ->
                base = listOf("Escaneos ilimitados de pizarra") + base.filter { !it.contains("Escaneos") }
            PaywallContext.EXERCISE_EVOLUTION, PaywallContext.EXERCISE_HISTORY ->
                base = listOf("Historial y evolución por ejercicio") + base.filter { !it.contains("evolución") }
            PaywallContext.WOD_HISTORY ->
                base = listOf("Marcas y comparativas de WOD") + base.filter { !it.contains("WOD") }
            PaywallContext.PROGRESS, PaywallContext.MUSCLE_ANALYSIS ->
                base = listOf("Estadísticas completas de progreso", "Mapa muscular y análisis avanzado") +
                    base.filter { !it.contains("Estadísticas") && !it.contains("Mapa") }
            else -> Unit
        }
        return base.take(6)
    }
