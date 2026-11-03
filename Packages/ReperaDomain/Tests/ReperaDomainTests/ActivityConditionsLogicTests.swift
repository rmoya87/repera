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
        XCTAssertNil(result.temperatureC)
    }

    func testWaveOnlyMarineDoesNotCrashWithoutSeaLevels() throws {
        let marine = """
        {"hourly":{"time":["2026-10-31T12:00","2026-10-31T13:00","2026-10-31T14:00"],
        "wave_height":[0.8,0.9,1.0]}}
        """.data(using: .utf8)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let date = try XCTUnwrap(formatter.date(from: "2026-10-31T13:00"))
        let result = try XCTUnwrap(ActivityConditionsLogic.parse(
            family: .water, forecastJSON: nil, marineJSON: marine, at: date
        ))
        XCTAssertNil(result.tideHeightMeters)
        XCTAssertNil(result.nextTideLabel)
        XCTAssertEqual(result.waveHeightMeters ?? -1, 0.9, accuracy: 0.01)
    }

    func testSpecializedSnowRequestOnlyAsksForDepth() throws {
        let url = try XCTUnwrap(ActivityConditionsLogic.snowDepthURL(
            latitude: 40.42, longitude: -3.70
        ))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let hourly = components.queryItems?.first(where: { $0.name == "hourly" })?.value
        XCTAssertEqual(hourly, "snow_depth")
        XCTAssertFalse(url.absoluteString.contains("temperature_2m"))
        XCTAssertFalse(url.absoluteString.contains("snowfall"))
    }

    func testConditionProviderMetadataRoundTripAndLegacyDecode() throws {
        var snapshot = ActivityConditionsSnapshot(
            family: .snow, temperatureC: 2, windKmh: 9,
            snowfallCm: 1.4, snowDepthMeters: 0.65, attribution: "Apple Weather + Open-Meteo"
        )
        snapshot.humidity = 0.71
        snapshot.airSource = .appleWeather
        snapshot.snowfallSource = .appleWeather

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let decoded = try JSONDecoder().decode(ActivityConditionsSnapshot.self, from: data)
        XCTAssertEqual(decoded.airSource, .appleWeather)
        XCTAssertEqual(decoded.snowfallSource, .appleWeather)
        XCTAssertEqual(decoded.humidity ?? -1, 0.71, accuracy: 0.001)

        // Copias ya guardadas en iCloud/Watch no contienen los campos añadidos.
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        legacy.removeValue(forKey: "humidity")
        legacy.removeValue(forKey: "airSource")
        legacy.removeValue(forKey: "snowfallSource")
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        let restored = try JSONDecoder().decode(ActivityConditionsSnapshot.self, from: legacyData)
        XCTAssertNil(restored.airSource)
        XCTAssertNil(restored.snowfallSource)
        XCTAssertNil(restored.humidity)
        XCTAssertEqual(restored.snowDepthMeters ?? -1, 0.65, accuracy: 0.001)
    }
}
