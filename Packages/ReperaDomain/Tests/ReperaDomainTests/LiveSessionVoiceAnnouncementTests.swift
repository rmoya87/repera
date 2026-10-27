import XCTest
@testable import ReperaDomain

final class LiveSessionVoiceAnnouncementTests: XCTestCase {
    func testOnlyPauseAndResumeAreSpokenAnnouncements() {
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.paused, "Entrenamiento pausado."
        )
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.resumed, "Entrenamiento reanudado."
        )
        // Inicio y fin usan RestFeedback, no texto para sintetizar.
    }
}
