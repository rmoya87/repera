import Foundation

/// Pure wall-clock helpers for countdown / count-up timers (testable without UIKit).
public enum WallClockTimer: Sendable {
    public static func remainingSeconds(until endDate: Date, now: Date = Date()) -> Int {
        max(0, Int(ceil(endDate.timeIntervalSince(now))))
    }

    public static func elapsedSeconds(since startDate: Date, now: Date = Date()) -> Int {
        max(0, Int(floor(now.timeIntervalSince(startDate))))
    }

    public static func endDate(from now: Date = Date(), lasting seconds: Int) -> Date {
        now.addingTimeInterval(TimeInterval(max(0, seconds)))
    }

    /// Remaining after a pause/resume cycle using frozen remaining at pause.
    public static func resumeEndDate(remaining: TimeInterval, now: Date = Date()) -> Date {
        now.addingTimeInterval(max(0, remaining))
    }
}
