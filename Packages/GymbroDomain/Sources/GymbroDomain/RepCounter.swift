import Foundation

/// Detects reps from a stream of acceleration magnitudes (Watch CoreMotion).
/// Peak-based heuristic; always pair with manual ± in the UI.
public struct MotionRepCounter: Sendable {
    private var lastMagnitude: Double = 0
    private var rising = false
    private var lastRepAt: Date = .distantPast
    private let threshold: Double
    private let minInterval: TimeInterval

    public private(set) var count: Int = 0

    public init(threshold: Double = 1.35, minInterval: TimeInterval = 0.45) {
        self.threshold = threshold
        self.minInterval = minInterval
    }

    public mutating func reset() {
        count = 0
        lastMagnitude = 0
        rising = false
        lastRepAt = .distantPast
    }

    public mutating func ingest(magnitude: Double, at date: Date = Date()) {
        if magnitude > lastMagnitude {
            rising = true
        } else if rising, lastMagnitude >= threshold, magnitude < lastMagnitude {
            if date.timeIntervalSince(lastRepAt) >= minInterval {
                count += 1
                lastRepAt = date
            }
            rising = false
        }
        lastMagnitude = magnitude
    }

    public mutating func applyManualDelta(_ delta: Int) {
        count = max(0, count + delta)
    }
}
