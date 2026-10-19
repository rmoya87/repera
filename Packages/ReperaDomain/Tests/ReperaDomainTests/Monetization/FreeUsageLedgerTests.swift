import Foundation
import Testing
@testable import ReperaDomain

@Suite("FreeUsageLedger")
struct FreeUsageLedgerTests {

    private var cal: Calendar { FreeUsageLedger.utcCalendar }

    @Test("Primer escaneo consume")
    func firstScanConsumes() {
        var state = FreeUsageState()
        let ok = FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "a1", isPro: false)
        #expect(ok)
        #expect(state.boardScansConsumed == 1)
        #expect(state.consumedAttemptIDs.contains("a1"))
    }

    @Test("Cuarto OK, quinto no puede empezar")
    func fourthThenFifthBlocked() {
        var state = FreeUsageState(boardScanPeriodKey: FreeUsageLedger.periodKey())
        for i in 1...4 {
            #expect(FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "a\(i)", isPro: false))
        }
        #expect(FreeUsageLedger.canStartBoardScan(state: state, isPro: false) == false)
        #expect(FreeUsageLedger.boardScansRemaining(in: state) == 0)
    }

    @Test("Pro no consume cuota")
    func proDoesNotConsume() {
        var state = FreeUsageState()
        #expect(FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "p1", isPro: true) == false)
        #expect(state.boardScansConsumed == 0)
        #expect(FreeUsageLedger.canStartBoardScan(state: state, isPro: true))
    }

    @Test("Doble callback mismo intento no cuenta dos veces")
    func doubleCallbackIdempotent() {
        var state = FreeUsageState()
        #expect(FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "same", isPro: false))
        #expect(FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "same", isPro: false) == false)
        #expect(state.boardScansConsumed == 1)
    }

    @Test("Cambio de mes resetea")
    func monthRollover() {
        var state = FreeUsageState(
            boardScanPeriodKey: "2026-01",
            boardScansConsumed: 4,
            consumedAttemptIDs: ["x"]
        )
        let feb = cal.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        state = FreeUsageLedger.normalized(state, now: feb, calendar: cal)
        #expect(state.boardScanPeriodKey == "2026-02")
        #expect(state.boardScansConsumed == 0)
        #expect(state.consumedAttemptIDs.isEmpty)
    }

    @Test("Cambio de año")
    func yearRollover() {
        let state = FreeUsageState(boardScanPeriodKey: "2025-12", boardScansConsumed: 3)
        let jan = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        #expect(FreeUsageLedger.boardScansRemaining(in: state, now: jan, calendar: cal) == 4)
    }

    @Test("Reapertura tras varios meses")
    func reopenAfterMonths() {
        var state = FreeUsageState(boardScanPeriodKey: "2025-06", boardScansConsumed: 4)
        let oct = cal.date(from: DateComponents(year: 2026, month: 10, day: 19))!
        #expect(FreeUsageLedger.canStartBoardScan(state: state, isPro: false, now: oct, calendar: cal))
        #expect(FreeUsageLedger.consumeBoardScan(state: &state, attemptID: "new", isPro: false, now: oct, calendar: cal))
        #expect(state.boardScanPeriodKey == "2026-10")
        #expect(state.boardScansConsumed == 1)
    }

    @Test("Period key estable en UTC")
    func periodKeyUTC() {
        let key = FreeUsageLedger.periodKey(
            for: cal.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 23))!,
            calendar: cal
        )
        #expect(key == "2026-10")
    }
}
