import Foundation

/// Clock math independent of UI timers. It remains correct if watchOS suspends
/// view updates while an active HKWorkoutSession continues running.
public struct WorkoutClockStep: Sendable, Equatable {
    public let advancedSeconds: Int
    public let sessionElapsed: Int
    public let blockElapsed: Int
    public let restRemaining: Int
    public let reachedTimeCap: Bool
}

public enum WorkoutClockMath {
    /// Treat a timer callback as a repaint request, never as one elapsed second.
    /// Rest counts toward timed WODs, but is excluded from an untimed strength
    /// block's active clock. No artificial one-hour truncation is applied.
    public static func advance(
        from previous: Date,
        to now: Date,
        sessionElapsed: Int,
        blockElapsed: Int,
        restRemaining: Int,
        isCounting: Bool,
        isWOD: Bool,
        timeCapSeconds: Int
    ) -> WorkoutClockStep {
        let delta = max(0, Int(now.timeIntervalSince(previous)))
        let rest = max(0, restRemaining)
        let restConsumed = min(rest, delta)
        let nextRest = rest - restConsumed
        let increment = isWOD ? delta : delta - restConsumed
        let nextBlock: Int
        if isCounting {
            let elapsed = max(0, blockElapsed) + increment
            nextBlock = isWOD && timeCapSeconds > 0 ? min(elapsed, timeCapSeconds) : elapsed
        } else {
            nextBlock = max(0, blockElapsed)
        }
        return WorkoutClockStep(
            advancedSeconds: delta,
            sessionElapsed: max(0, sessionElapsed) + delta,
            blockElapsed: nextBlock,
            restRemaining: nextRest,
            reachedTimeCap: isCounting && isWOD
                && timeCapSeconds > 0 && nextBlock >= timeCapSeconds
        )
    }
}
