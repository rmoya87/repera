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
        // La tercera pestaña se llama «Comenzar» desde el rediseño.
        XCTAssertTrue(app.tabBars.buttons["Comenzar"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
        XCTAssertTrue(app.tabBars.buttons["Ejercicios"].exists)
    }

    /// Regression check for size changes (rotation, and re-layout on Duo).
    /// Folding itself must additionally be exercised on a Duo simulator/device.
    @MainActor
    func testProgressNavigationSurvivesSizeChange() throws {
        let app = makeTestApp()
        app.launch()
        let progressTab = app.tabBars.buttons["Progreso"]
        XCTAssertTrue(progressTab.waitForExistence(timeout: 8))
        progressTab.tap()
        let title = app.staticTexts["Progreso"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Progreso"].exists)
    }

    @MainActor
    func testOpenExercisesTab() throws {
        let app = makeTestApp()
        app.launch()
        app.tabBars.buttons["Ejercicios"].tap()
        XCTAssertTrue(app.navigationBars["Ejercicios"].waitForExistence(timeout: 5))
    }
}
