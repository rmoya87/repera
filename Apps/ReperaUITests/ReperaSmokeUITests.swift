import XCTest

/// Smoke UI tests run in an explicit, Debug-only tab shell on a clean iOS simulator.
final class ReperaSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeTestApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--repera-ui-test-tabs")
        app.launchEnvironment["REPERA_UI_TEST_MODE"] = "1"
        return app
    }

    @MainActor
    func testLaunchShowsRootTabs() throws {
        let app = makeTestApp()
        app.launch()
        // Tab labels from RootTabView.
        XCTAssertTrue(app.tabBars.buttons["Inicio"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Diario"].exists)
        // Sin vínculo a gimnasio/entrenador la pestaña es Crear; con vínculo, Center.
        XCTAssertTrue(
            app.tabBars.buttons["Crear"].exists || app.tabBars.buttons["Center"].exists
        )
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ejercicios"].exists)
    }

    @MainActor
    func testOpenExercisesTab() throws {
        let app = makeTestApp()
        app.launch()
        app.tabBars.buttons["Ejercicios"].tap()
        XCTAssertTrue(app.navigationBars["Ejercicios"].waitForExistence(timeout: 5))
    }
}
