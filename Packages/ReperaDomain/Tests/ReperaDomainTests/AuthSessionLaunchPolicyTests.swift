import XCTest
@testable import ReperaDomain

final class AuthSessionLaunchPolicyTests: XCTestCase {
    func testEnterAppWhenCachedSessionEvenIfNotYetConnectedFlag() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: true,
                hasCachedSupabaseSession: true,
                isConnected: false,
                hasPriorSupabaseBinding: false,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .enterApp)
    }

    func testEnterAppWhenConnected() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: true,
                hasCachedSupabaseSession: false,
                isConnected: true,
                hasPriorSupabaseBinding: false,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .enterApp)
    }

    /// Tras un refresh fallido el SDK puede borrar Keychain; el binding en UserDefaults
    /// debe seguir dejando entrar sin re-SIWA.
    func testEnterAppWhenPriorBindingEvenWithoutCache() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: true,
                hasCachedSupabaseSession: false,
                isConnected: false,
                hasPriorSupabaseBinding: true,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .enterApp)
    }

    func testShowLoginWhenNoCacheNotConnectedNoBinding() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: true,
                hasCachedSupabaseSession: false,
                isConnected: false,
                hasPriorSupabaseBinding: false,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .showLogin)
    }

    func testShowLoginWhenOnboardingIncomplete() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: true,
                hasCachedSupabaseSession: true,
                isConnected: true,
                hasPriorSupabaseBinding: true,
                onboardingFinished: false
            )
        )
        XCTAssertEqual(decision, .showLogin)
    }

    /// Trazas reales: cache=true binding=true apple userID=false → antes showLogin eterno.
    func testEnterAppWhenAppleKeychainMissingButRemoteSessionIntact() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: false,
                hasCachedSupabaseSession: true,
                isConnected: false,
                hasPriorSupabaseBinding: true,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .enterApp)
    }

    func testShowLoginWhenNothingAtAll() {
        let decision = AuthSessionLaunchPolicy.decide(
            .init(
                appleSignedIn: false,
                hasCachedSupabaseSession: false,
                isConnected: false,
                hasPriorSupabaseBinding: false,
                onboardingFinished: true
            )
        )
        XCTAssertEqual(decision, .showLogin)
    }

    func testNeverSignOutWhenBindingMissingKeepsKeychainSession() {
        XCTAssertFalse(
            AuthSessionLaunchPolicy.shouldSignOutBeforeConnect(
                storedBinding: nil,
                expectedBinding: "abc"
            )
        )
    }

    func testSignOutOnlyOnAppleAccountSwitch() {
        XCTAssertTrue(
            AuthSessionLaunchPolicy.shouldSignOutBeforeConnect(
                storedBinding: "old",
                expectedBinding: "new"
            )
        )
        XCTAssertFalse(
            AuthSessionLaunchPolicy.shouldSignOutBeforeConnect(
                storedBinding: "same",
                expectedBinding: "same"
            )
        )
    }

    func testNoInteractiveSIWAWhenCacheOrBindingExists() {
        XCTAssertFalse(
            AuthSessionLaunchPolicy.shouldPresentInteractiveAppleSignIn(
                appleSignedIn: true,
                isConnected: false,
                hasCachedSupabaseSession: true,
                hasPriorSupabaseBinding: false
            )
        )
        XCTAssertFalse(
            AuthSessionLaunchPolicy.shouldPresentInteractiveAppleSignIn(
                appleSignedIn: true,
                isConnected: false,
                hasCachedSupabaseSession: false,
                hasPriorSupabaseBinding: true
            )
        )
    }

    func testInteractiveSIWAOnlyWithoutCacheOrBinding() {
        XCTAssertTrue(
            AuthSessionLaunchPolicy.shouldPresentInteractiveAppleSignIn(
                appleSignedIn: true,
                isConnected: false,
                hasCachedSupabaseSession: false,
                hasPriorSupabaseBinding: false
            )
        )
    }
}
