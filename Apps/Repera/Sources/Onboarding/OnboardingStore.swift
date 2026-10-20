import Foundation
import Observation

enum OnboardingStep: String, Codable, Sendable {
    case appleSignIn
    case choosePlan
    case permissions
    case done
}

/// Progreso del wizard obligatorio (primer acceso y usuarios existentes).
@MainActor
@Observable
final class OnboardingStore {
    static let shared = OnboardingStore()

    private let stepKey = "repera.onboarding.step"
    private let flowVersionKey = "repera.onboarding.flowVersion"
    private let priceAlreadySeenKey = "repera.onboarding.priceAlreadySeen"
    private let defaults = UserDefaults.standard
    private(set) var priceAlreadySeen = false

    private(set) var step: OnboardingStep

    var isComplete: Bool { step == .done }

    private init() {
        let previous = defaults.string(forKey: stepKey).flatMap(OnboardingStep.init(rawValue:)) ?? .appleSignIn
        if defaults.integer(forKey: flowVersionKey) < 2 {
            // v1: Apple → precio → permisos. v2: Apple → permisos → precio.
            // An old user already on permissions has SEEN prices: never show again.
            priceAlreadySeen = previous == .permissions || previous == .done
            step = previous == .done ? .done
                : previous == .appleSignIn ? .appleSignIn : .permissions
            defaults.set(step.rawValue, forKey: stepKey)
            defaults.set(priceAlreadySeen, forKey: priceAlreadySeenKey)
            defaults.set(2, forKey: flowVersionKey)
        } else {
            step = previous
            priceAlreadySeen = defaults.bool(forKey: priceAlreadySeenKey)
        }
    }

    func advance(to next: OnboardingStep) {
        step = next
        defaults.set(next.rawValue, forKey: stepKey)
    }

    /// Completes permissions before any new user sees subscription prices.
    /// Returning users migrating from the old flow are not asked twice.
    func finishPermissions() {
        advance(to: priceAlreadySeen ? .done : .choosePlan)
    }

    func finishPrices() {
        priceAlreadySeen = true
        defaults.set(true, forKey: priceAlreadySeenKey)
        advance(to: .done)
    }

    func resetToSignIn() {
        priceAlreadySeen = false
        defaults.set(false, forKey: priceAlreadySeenKey)
        advance(to: .appleSignIn)
    }

    /// Si hay sesión completa (Apple+Supabase): avanza el wizard.
    /// Si no hay sesión: **no** tocar el paso — bajar de `.done` a `.appleSignIn` dejaba
    /// `OnboardingFlowView` en un `OG.bg` vacío tras reconectar (pantalla en blanco).
    /// La puerta de login/migración la decide `ReperaApp` con Apple/Supabase.
    func reconcile(isSignedIn: Bool) {
        guard isSignedIn else { return }
        if step == .appleSignIn {
            advance(to: priceAlreadySeen ? .done : .permissions)
        } else if priceAlreadySeen, step != .done {
            // Reauth / update: ya vio precios; no repetir wizard a medias.
            advance(to: .done)
        }
    }
}
