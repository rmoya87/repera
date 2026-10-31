import XCTest
@testable import ReperaDomain

final class ActivityConditionsLogicTests: XCTestCase {
    func testFamilyForWaterAndSnow() {
        XCTAssertEqual(ActivityConditionsSnapshot.family(forLiveSportID: "surfing"), .water)
        XCTAssertEqual(ActivityConditionsSnapshot.family(forLiveSportID: "skiing"), .snow)
        XCTAssertEqual(ActivityConditionsSnapshot.family(forLiveSportID: "running"), .outdoor)
        XCTAssertEqual(ActivityConditionsSnapshot.family(forLiveSportID: "yoga"), .none)
    }

    func testParseMarineTideTrend() throws {
        let forecast = """
        {"hourly":{"time":["2026-10-31T12:00","2026-10-31T13:00","2026-10-31T14:00"],\
        "temperature_2m":[18.0,18.5,19.0],"wind_speed_10m":[12.0,13.0,14.0],\
        "snowfall":[0,0,0],"snow_depth":[0,0,0]}}
        """.data(using: .utf8)
        let marine = """
        {"hourly":{"time":["2026-10-31T12:00","2026-10-31T13:00","2026-10-31T14:00"],\
        "sea_level_height_msl":[0.10,0.25,0.40],"wave_height":[0.8,0.9,1.0]}}
        """.data(using: .utf8)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let at = try XCTUnwrap(fmt.date(from: "2026-10-31T13:00"))
        let snap = ActivityConditionsLogic.parse(
            family: .water, forecastJSON: forecast, marineJSON: marine, at: at
        )
        let result = try XCTUnwrap(snap)
        XCTAssertEqual(result.tideTrend, .rising)
        XCTAssertEqual(result.waveHeightMeters ?? -1, 0.9, accuracy: 0.01)
        XCTAssertNotNil(result.temperatureC)
    }
}
