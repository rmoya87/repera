import Foundation
import os

/// Cold-start probes — filter Console by subsystem `app.gymbroapp.ios` / category `Launch`.
enum LaunchTiming {
    private static let logger = Logger(subsystem: "app.gymbroapp.ios", category: "Launch")
    private static let processStart = CFAbsoluteTimeGetCurrent()

    static func mark(_ label: String) {
        let ms = (CFAbsoluteTimeGetCurrent() - processStart) * 1000
        logger.info("+\(ms, format: .fixed(precision: 1))ms \(label, privacy: .public)")
    }

    static func span(_ label: String, from start: CFAbsoluteTime) {
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        let sinceProcess = (CFAbsoluteTimeGetCurrent() - processStart) * 1000
        logger.info("\(label, privacy: .public) took \(ms, format: .fixed(precision: 1))ms (T+\(sinceProcess, format: .fixed(precision: 1))ms)")
    }
}
