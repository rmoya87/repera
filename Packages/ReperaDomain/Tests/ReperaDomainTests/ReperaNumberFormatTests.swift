import XCTest
@testable import ReperaDomain

final class ReperaNumberFormatTests: XCTestCase {
    func testSpanishDecimalsAndGrouping() {
        XCTAssertEqual(ReperaNumberFormat.decimal(1234.56), "1.234,56")
        XCTAssertEqual(ReperaNumberFormat.decimal(1234567.8), "1.234.567,8")
        XCTAssertEqual(ReperaNumberFormat.decimal(1000), "1.000")
        XCTAssertEqual(ReperaNumberFormat.decimal(1.2), "1,2")
        XCTAssertEqual(ReperaNumberFormat.decimal(1.23456), "1,23")
        XCTAssertEqual(ReperaNumberFormat.decimal(-1234.5), "-1.234,5")
        XCTAssertEqual(ReperaNumberFormat.decimal(42.0), "42")
    }

    func testDecimalLimitAndIntegers() {
        XCTAssertEqual(ReperaNumberFormat.decimal(12.346, maximumFractionDigits: 6), "12,35")
        XCTAssertEqual(ReperaNumberFormat.decimal(42.9, maximumFractionDigits: 0), "43")
        XCTAssertEqual(ReperaNumberFormat.decimal(5, minimumFractionDigits: 1), "5,0")
        XCTAssertEqual(ReperaNumberFormat.integer(1234), "1.234")
        XCTAssertEqual(ReperaNumberFormat.integer(-1234567), "-1.234.567")
    }

    func testSpanishAndLegacyInput() {
        XCTAssertEqual(ReperaNumberFormat.parse("1.234,56"), 1234.56)
        XCTAssertEqual(ReperaNumberFormat.parse(" 1.234,5 "), 1234.5)
        XCTAssertEqual(ReperaNumberFormat.parse("1.234"), 1234)
        XCTAssertEqual(ReperaNumberFormat.parse("1234.56"), 1234.56)
        XCTAssertEqual(ReperaNumberFormat.parse("-12,5"), -12.5)
        XCTAssertEqual(ReperaNumberFormat.parse("0,25"), 0.25)
        XCTAssertNil(ReperaNumberFormat.parse(""))
        XCTAssertNil(ReperaNumberFormat.parse("1,2,3"))
        XCTAssertNil(ReperaNumberFormat.parse("infinito"))
    }

    func testFormattingDoesNotChangeDataPrecision() {
        let recorded = 1234.56789
        XCTAssertEqual(ReperaNumberFormat.decimal(recorded), "1.234,57")
        XCTAssertEqual(recorded, 1234.56789) // solo cambia la presentación
    }
}
