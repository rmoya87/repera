import XCTest
@testable import GymbroDomain

final class Wave5Tests: XCTestCase {
    func testRestPauseSumsClustersAndVolume() {
        let set = LoggedSet(
            reps: 0,
            weightKg: 60,
            kind: .restpause,
            clusters: [
                RestPauseCluster(reps: 8, restSeconds: 15),
                RestPauseCluster(reps: 4, restSeconds: 15),
                RestPauseCluster(reps: 2, restSeconds: 15),
            ]
        )
        XCTAssertEqual(set.kind, .restpause)
        XCTAssertEqual(set.reps, 14)
        XCTAssertEqual(set.volumeKg, 60 * 14)
    }
}
