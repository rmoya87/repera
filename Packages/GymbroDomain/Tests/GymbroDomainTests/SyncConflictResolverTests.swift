import XCTest
@testable import GymbroDomain

final class SyncConflictResolverTests: XCTestCase {
    private func state(
        revision: Int,
        updatedAt: Date,
        writer: String
    ) -> AppState {
        AppState(
            exercises: [],
            routines: [],
            workouts: [],
            bodyWeights: [],
            updatedAt: updatedAt,
            syncRevision: revision,
            lastWriterDeviceId: writer
        )
    }

    func testHigherRevisionWinsOverNewerDate() {
        let olderStamp = Date(timeIntervalSince1970: 1_000)
        let newerStamp = Date(timeIntervalSince1970: 2_000)
        let local = state(revision: 5, updatedAt: newerStamp, writer: "A")
        let remote = state(revision: 6, updatedAt: olderStamp, writer: "B")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: local, remote: remote)?.syncRevision, 6)
    }

    func testSameRevisionPrefersNewerUpdatedAt() {
        let local = state(revision: 3, updatedAt: Date(timeIntervalSince1970: 10), writer: "A")
        let remote = state(revision: 3, updatedAt: Date(timeIntervalSince1970: 20), writer: "B")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
    }

    func testTieBreakUsesWriterIdDeterministically() {
        let stamp = Date(timeIntervalSince1970: 42)
        let local = state(revision: 2, updatedAt: stamp, writer: "device-a")
        let remote = state(revision: 2, updatedAt: stamp, writer: "device-z")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
        XCTAssertEqual(SyncConflictResolver.winner(local: remote, remote: local), .local)
    }

    func testEqualDocuments() {
        let stamp = Date(timeIntervalSince1970: 7)
        let local = state(revision: 1, updatedAt: stamp, writer: "same")
        let remote = state(revision: 1, updatedAt: stamp, writer: "same")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .equal)
    }

    func testPickNewestNilCases() {
        let only = state(revision: 1, updatedAt: Date(), writer: "A")
        XCTAssertNil(SyncConflictResolver.pickNewest(local: nil, remote: nil))
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: only, remote: nil)?.lastWriterDeviceId, "A")
        XCTAssertEqual(SyncConflictResolver.pickNewest(local: nil, remote: only)?.lastWriterDeviceId, "A")
    }

    func testLegacyZeroRevisionFallsBackToUpdatedAt() {
        let local = state(revision: 0, updatedAt: Date(timeIntervalSince1970: 1), writer: "")
        let remote = state(revision: 0, updatedAt: Date(timeIntervalSince1970: 99), writer: "")
        XCTAssertEqual(SyncConflictResolver.winner(local: local, remote: remote), .remote)
    }
}
