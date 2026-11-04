import Foundation
import Testing
@testable import ReperaDomain

struct WatchTransportTests {
    private func straightLine(count: Int, jitterMeters: Double = 0) -> [WorkoutRoutePoint] {
        (0..<count).map { i in
            let lateral = (i.isMultiple(of: 2) ? 1.0 : -1.0) * jitterMeters / 111_320
            return WorkoutRoutePoint(
                id: i,
                latitude: 40.0 + Double(i) * 0.00005,
                longitude: -3.7 + lateral,
                recordedAt: Date(timeIntervalSince1970: Double(i))
            )
        }
    }

    @Test func `a straight track collapses to its endpoints`() {
        let simplified = WatchRouteSimplifier.simplify(straightLine(count: 500, jitterMeters: 0.5))
        #expect(simplified.count == 2)
        #expect(simplified.first?.id == 0)
        #expect(simplified.last?.id == 499)
    }

    @Test func `corners survive and order is preserved`() {
        var points = straightLine(count: 50)
        let corner = points[49]
        for i in 1...50 {
            points.append(WorkoutRoutePoint(
                id: 49 + i,
                latitude: corner.latitude,
                longitude: corner.longitude + Double(i) * 0.00005
            ))
        }
        let simplified = WatchRouteSimplifier.simplify(points)
        #expect(simplified.map(\.id) == [0, 49, 99])
    }

    @Test func `the point cap is always respected and keeps endpoints`() {
        let zigzag = straightLine(count: 3_000, jitterMeters: 40)
        let simplified = WatchRouteSimplifier.simplify(zigzag, toleranceMeters: 1, maxPoints: 300)
        #expect(simplified.count <= 300)
        #expect(simplified.first?.id == 0)
        #expect(simplified.last?.id == 2_999)
        #expect(simplified.map(\.id) == simplified.map(\.id).sorted())
    }

    @Test func `short routes are untouched`() {
        let two = straightLine(count: 2)
        #expect(WatchRouteSimplifier.simplify(two) == two)
    }

    @Test func `payload limits reject oversized data before decoding`() {
        #expect(WatchTransportLimits.accepts(Data(count: 10)))
        #expect(!WatchTransportLimits.accepts(Data(count: WatchTransportLimits.maxPayloadBytes + 1)))
        #expect(!WatchTransportLimits.acceptsFile(byteCount: 0))
        #expect(!WatchTransportLimits.acceptsFile(byteCount: WatchTransportLimits.maxFileBytes + 1))
    }

    @Test func `ack clears the outbox unless a richer Health revision is pending`() {
        let local = UUID()
        #expect(WatchOutboxAckPolicy.shouldClear(
            localHealthKitUUID: nil, acknowledgedHealthKitUUID: nil, awaitingHealthSave: false))
        #expect(WatchOutboxAckPolicy.shouldClear(
            localHealthKitUUID: local, acknowledgedHealthKitUUID: local, awaitingHealthSave: false))
        #expect(WatchOutboxAckPolicy.shouldClear(
            localHealthKitUUID: local, acknowledgedHealthKitUUID: UUID(), awaitingHealthSave: false))
        #expect(!WatchOutboxAckPolicy.shouldClear(
            localHealthKitUUID: local, acknowledgedHealthKitUUID: nil, awaitingHealthSave: false))
        #expect(!WatchOutboxAckPolicy.shouldClear(
            localHealthKitUUID: nil, acknowledgedHealthKitUUID: nil, awaitingHealthSave: true))
    }
}
