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
    private let defaults = UserDefaults.standard

    private(set) var step: OnboardingStep

    var isComplete: Bool { step == .done }

    private init() {
        if let raw = defaults.string(forKey: stepKey),
           let saved = OnboardingStep(rawValue: raw) {
            step = saved
        } else {
            step = .appleSignIn
        }
    }

    func advance(to next: OnboardingStep) {
        step = next
        defaults.set(next.rawValue, forKey: stepKey)
    }

    func resetToSignIn() {
        advance(to: .appleSignIn)
    }

    /// Tras validar SIWA: si el wizard estaba en done pero la sesión cayó, vuelve a login;
    /// si hay sesión y el paso quedó a medias, reanuda; si done + sesión OK, no toca.
    func reconcile(isSignedIn: Bool) {
        if !isSignedIn {
            if step != .appleSignIn {
                advance(to: .appleSignIn)
            }
            return
        }
        if step == .appleSignIn {
            advance(to: .choosePlan)
        }
    }
}
