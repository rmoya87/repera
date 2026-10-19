import XCTest
@testable import ReperaBusinessContracts
final class BusinessAgendaTests: XCTestCase {
    func testDecodeMobileContract() throws {
        let json = """
        {"schema_version":1,"org_id":"org","client_id":"c1","cursor":null,
         "events":[{"id":"a1:2026-10-19","kind":"training","date":"2026-10-19", "title":"Fuerza", "source":"professional", "assignment_id":"a1", "booking_id":null, "exercise_text":"3x8", "deep_link":"repera://diary/a1"}]}
        """
        let response=try JSONDecoder().decode(BusinessAgendaResponse.self,from:Data(json.utf8))
        XCTAssertEqual(response.schemaVersion,1)
        XCTAssertEqual(response.events.first?.assignmentId,"a1")
    }
    func testMultipleSessionsAndSafety() {
        let a=BusinessAgendaEvent(id:"x",kind:.training,date:"2026-10-19",title:"Antes",deepLink:"repera://diary/x")
        let b=BusinessAgendaEvent(id:"y",kind:.class,date:"2026-10-19",title:"Clase",deepLink:"repera://classes/y")
        let updated=BusinessAgendaEvent(id:"x",kind:.training,date:"2026-10-19",title:"Después",deepLink:"repera://diary/x")
        let malicious=BusinessAgendaEvent(id:"bad",kind:.training,date:"2026-10-19",title:"Phishing",deepLink:"https://evil.example")
        let merged=BusinessAgendaMerger.merge(existing:[a,b],incoming:[updated,malicious])
        XCTAssertEqual(merged.count,2)
        XCTAssertEqual(merged.first(where:{$0.id=="x"})?.title,"Después")
    }

    func testPersonalTrainingAppointmentOnTheSameDay() throws {
        let json = """
        {"schema_version":1,"org_id":"org","client_id":"c1","cursor":null,
         "events":[{"id":"booking-pt-1","kind":"appointment","date":"2026-10-19",
         "title":"Sesión individual","source":"professional","assignment_id":null,
         "booking_id":"booking-pt-1","exercise_text":null,
         "deep_link":"repera://appointments/appointment-1"}]}
        """
        let response = try JSONDecoder().decode(BusinessAgendaResponse.self, from: Data(json.utf8))
        let appointment = try XCTUnwrap(response.events.first)
        XCTAssertEqual(appointment.kind, .appointment)
        XCTAssertEqual(appointment.bookingId, "booking-pt-1")
        XCTAssertTrue(appointment.isValidLink)

        let workout = BusinessAgendaEvent(
            id: "local-overlay", kind: .training, date: "2026-10-19",
            title: "Entrenamiento del coach", deepLink: "repera://diary/workout-1"
        )
        let merged = BusinessAgendaMerger.merge(existing: [workout], incoming: [appointment])
        XCTAssertEqual(merged.count, 2)
        XCTAssertFalse(BusinessAgendaEvent(
            id: "wrong", kind: .appointment, date: "2026-10-19",
            title: "No permitida", deepLink: "https://external.example/appointment"
        ).isValidLink)
    }
}
