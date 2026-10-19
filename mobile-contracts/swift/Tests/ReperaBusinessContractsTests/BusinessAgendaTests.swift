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
}