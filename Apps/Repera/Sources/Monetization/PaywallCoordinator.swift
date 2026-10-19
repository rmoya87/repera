import Foundation
import ReperaDomain
import Observation

/// Evita paywalls simultáneos por pulsaciones rápidas.
@MainActor
@Observable
final class PaywallCoordinator {
    private(set) var isPresented = false
    private(set) var context: PaywallContext = .generic

    func present(_ context: PaywallContext) {
        guard !isPresented else {
            self.context = context
            return
        }
        self.context = context
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}

extension PaywallContext {
    var headline: String {
        switch self {
        case .routinesLimit: return "Todas tus rutinas, sin límites"
        case .customExercisesLimit: return "Tus ejercicios, sin límites"
        case .boardScansLimit: return "Cada pizarra, lista para entrenar"
        case .exerciseEvolution, .exerciseHistory: return "Descubre cómo estás progresando"
        case .wodHistory: return "Supera tus mejores marcas"
        case .progress: return "Analiza toda tu evolución"
        case .muscleAnalysis: return "Conoce tu equilibrio muscular"
        case .advancedProgression: return "Progresión a tu medida"
        case .settings, .generic: return "Repera Pro"
        case .onboarding: return "Lleva Repera al siguiente nivel"
        }
    }

    var subtitle: String {
        switch self {
        case .routinesLimit:
            return "Guarda todas las plantillas que necesites y organízalas a tu ritmo."
        case .customExercisesLimit:
            return "Añade todos los ejercicios propios que uses en el gym."
        case .boardScansLimit:
            return "Escanea pizarras sin cuota mensual."
        case .exerciseEvolution, .exerciseHistory:
            return "Consulta todas tus marcas, compara entrenos y ve tu evolución."
        case .wodHistory:
            return "Compara intentos, mejoras y tu mejor marca histórica."
        case .progress:
            return "Entrena como siempre. Descubre hasta dónde puedes llegar."
        case .muscleAnalysis:
            return "Visualiza grupos musculares y cómo se reparte tu entrenamiento."
        case .advancedProgression:
            return "Recomendaciones de carga según tu historial y esfuerzo."
        case .settings, .generic:
            return "Entrena como siempre. Descubre hasta dónde puedes llegar."
        case .onboarding:
            return "Historial completo, progreso avanzado, escáner ilimitado y más. También puedes empezar gratis."
        }
    }

    var prioritizedBenefits: [String] {
        var base = [
            "Historial y evolución por ejercicio",
            "Estadísticas completas de progreso",
            "Marcas y comparativas de WOD",
            "Mapa muscular y análisis avanzado",
            "Escaneos ilimitados de pizarra",
            "Rutinas ilimitadas",
        ]
        switch self {
        case .routinesLimit:
            base = ["Rutinas ilimitadas"] + base.filter { !$0.contains("Rutinas") }
        case .customExercisesLimit:
            base = ["Ejercicios personalizados ilimitados"] + base
        case .boardScansLimit:
            base = ["Escaneos ilimitados de pizarra"] + base.filter { !$0.contains("Escaneos") }
        case .exerciseEvolution, .exerciseHistory:
            base = ["Historial y evolución por ejercicio"] + base.filter { !$0.contains("evolución") }
        case .wodHistory:
            base = ["Marcas y comparativas de WOD"] + base.filter { !$0.contains("WOD") }
        case .progress, .muscleAnalysis:
            base = ["Estadísticas completas de progreso", "Mapa muscular y análisis avanzado"]
                + base.filter { !$0.contains("Estadísticas") && !$0.contains("Mapa") }
        default:
            break
        }
        return Array(base.prefix(6))
    }
}
