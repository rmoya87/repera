import Foundation
import XCTest
@testable import ReperaDomain

final class FallbackActivityKindTests: XCTestCase {
    func testDefaultIsGymStrength() {
        XCTAssertEqual(FallbackActivityKind.resolving(title: "Clase de las 18:00"), .strength)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "Gimnasio"), .strength)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "").liveSportID, "strength")
    }

    func testIntervalTitlesResolveToHIIT() {
        XCTAssertEqual(FallbackActivityKind.resolving(title: "HIIT 30'"), .hiit)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "Tabata express"), .hiit)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "WOD del día"), .hiit)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "CrossFit Open"), .hiit)
        XCTAssertEqual(FallbackActivityKind.resolving(title: "Circuito funcional"), .hiit)
    }
}
