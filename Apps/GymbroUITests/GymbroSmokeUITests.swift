import XCTest

/// Smoke UI tests — require a signed simulator run. Marked for CI continue-on-error until green.
final class GymbroSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsRootTabs() throws {
        let app = XCUIApplication()
        app.launch()
        // Tab labels from RootTabView.
        XCTAssertTrue(app.tabBars.buttons["Inicio"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Diario"].exists)
        XCTAssertTrue(app.tabBars.buttons["Crear"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ejercicios"].exists)
    }

    @MainActor
    func testOpenExercisesTab() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Ejercicios"].tap()
        XCTAssertTrue(app.navigationBars["Ejercicios"].waitForExistence(timeout: 5))
    }
}
