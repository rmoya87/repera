import Foundation
import ReperaDomain
import OSLog

/// Trazas de Progreso (Consola → subsystem `com.app.repera` / category `Progress`).
enum ProgressLog {
    private static let logger = Logger(subsystem: "com.app.repera", category: "Progress")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        #if DEBUG
        print("[Progress] \(message)")
        #endif
    }

    static func rangeTap(from: ProgressTimeRange, to: ProgressTimeRange) {
        info("range tap \(from.rawValue) → \(to.rawValue)")
    }

    static func rangeApplied(_ range: ProgressTimeRange, elapsedMs: Double) {
        info(String(format: "range applied \(range.rawValue) in %.1fms", elapsedMs))
    }

    static func healthCacheHit(days: Int, hr: Int, kcal: Int) {
        info("HK cache hit days≥\(days) hr=\(hr) kcal=\(kcal)")
    }

    static func healthFetchStart(days: Int) {
        info("HK fetch start days=\(days)")
    }

    static func healthFetchStep(_ step: String, count: Int, elapsedMs: Double) {
        info(String(format: "HK \(step) n=\(count) %.1fms", elapsedMs))
    }

    static func healthFetchDone(totalMs: Double, activities: Int, hr: Int, kcal: Int) {
        info(String(format: "HK fetch done %.1fms activities=\(activities) hr=\(hr) kcal=\(kcal)", totalMs))
    }

    static func chartBuild(_ name: String, range: ProgressTimeRange, points: Int, elapsedMs: Double) {
        info(String(format: "chart \(name) \(range.rawValue) points=\(points) %.1fms", elapsedMs))
    }
}
