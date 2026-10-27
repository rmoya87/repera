import XCTest
@testable import ReperaDomain

final class LiveSessionVoiceAnnouncementTests: XCTestCase {
    func testStartUsesSelectedSportName() {
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.started(sportName: "Caminata"),
            "Iniciando caminata."
        )
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.started(sportName: "Ciclismo de carretera"),
            "Iniciando ciclismo de carretera."
        )
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.started(sportName: "CrossFit"),
            "Iniciando crossfit."
        )
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.started(sportName: "  Senderismo  "),
            "Iniciando senderismo."
        )
    }

    func testEmptySportNameUsesGenericAnnouncement() {
        XCTAssertEqual(
            LiveSessionVoiceAnnouncement.started(sportName: " "),
            "Entrenamiento iniciado."
        )
    }

    func testPauseResumeAndFinishHaveBriefSpanishAnnouncements() {
        XCTAssertEqual(LiveSessionVoiceAnnouncement.paused, "Entrenamiento pausado.")
        XCTAssertEqual(LiveSessionVoiceAnnouncement.resumed, "Entrenamiento reanudado.")
        XCTAssertEqual(LiveSessionVoiceAnnouncement.finished, "Entrenamiento finalizado.")
    }
}
