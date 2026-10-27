import XCTest
@testable import ReperaDomain

final class KilometerVoiceAnnouncementTests: XCTestCase {
    func testWalkingAlwaysAnnouncesSplitTimeAndAverageSpeed() {
        let spoken = KilometerVoiceAnnouncement.message(
            kilometer: 1, splitSeconds: 750, elapsedSeconds: 750
        )
        XCTAssertEqual(
            spoken,
            "Kilómetro 1 completado. Tiempo del tramo: 12 minutos y 30 segundos. " +
            "Velocidad media del tramo: 4,8 kilómetros por hora."
        )
    }

    func testLaterSplitIncludesCorrectOverallAverageAtBoundary() {
        let spoken = KilometerVoiceAnnouncement.message(
            kilometer: 2, splitSeconds: 720, elapsedSeconds: 1470
        )
        XCTAssertEqual(
            spoken,
            "Kilómetro 2 completado. Tiempo del tramo: 12 minutos. " +
            "Velocidad media del tramo: 5,0 kilómetros por hora. " +
            "Velocidad media desde el inicio: 4,9 kilómetros por hora."
        )
    }

    func testShortAndLongSplitsUseNaturalSpanishDurations() {
        XCTAssertTrue(
            KilometerVoiceAnnouncement.message(
                kilometer: 1, splitSeconds: 45, elapsedSeconds: 45
            )?.contains("45 segundos") == true
        )
        XCTAssertTrue(
            KilometerVoiceAnnouncement.message(
                kilometer: 1, splitSeconds: 3661, elapsedSeconds: 3661
            )?.contains("1 hora, 1 minuto y 1 segundo") == true
        )
    }

    func testInvalidGPSCrossingDoesNotCreateAnAnnouncement() {
        XCTAssertNil(KilometerVoiceAnnouncement.message(
            kilometer: 0, splitSeconds: 720, elapsedSeconds: 720
        ))
        XCTAssertNil(KilometerVoiceAnnouncement.message(
            kilometer: 1, splitSeconds: 0, elapsedSeconds: 720
        ))
        XCTAssertNil(KilometerVoiceAnnouncement.message(
            kilometer: 1, splitSeconds: .infinity, elapsedSeconds: 720
        ))
        XCTAssertNil(KilometerVoiceAnnouncement.message(
            kilometer: 1, splitSeconds: 720, elapsedSeconds: 700
        ))
    }

    func testBackgroundDeliveryUsesGpsCrossingTimeNotDeliveryTime() {
        // El GPS puede entregar lotes de posiciones al reactivar la app.
        let first = KilometerVoiceAnnouncement.message(
            kilometer: 3, splitSeconds: 810, elapsedSeconds: 2440
        )
        let delayed = KilometerVoiceAnnouncement.message(
            kilometer: 3, splitSeconds: 810, elapsedSeconds: 2440
        )
        XCTAssertEqual(first, delayed)
        XCTAssertTrue(first?.contains("Velocidad media del tramo: 4,4") == true)
    }
}
