import Foundation
import os

/// Timing del buscador de Ejercicios (Consola → `subsystem:app.gymbroapp.ios category:LibrarySearch`).
enum LibrarySearchLog {
    private static let logger = Logger(subsystem: "app.gymbroapp.ios", category: "LibrarySearch")
    private static let focusLock = OSAllocatedUnfairLock<CFAbsoluteTime?>(initialState: nil)
    private static let tapLock = OSAllocatedUnfairLock<CFAbsoluteTime?>(initialState: nil)

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        #if DEBUG
        print("[LibrarySearch] \(message)")
        #endif
    }

    /// Toque en el campo (antes o junto al foco).
    static func tapField(alreadyFocused: Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        tapLock.withLock { $0 = now }
        info(alreadyFocused ? "tap field (already focused)" : "tap field → request focus")
    }

    static func focusChanged(_ focused: Bool, sections: Int = 0, rows: Int = 0, queryLen: Int = 0) {
        if focused {
            focusLock.withLock { $0 = CFAbsoluteTimeGetCurrent() }
            let sinceTap: String = tapLock.withLock { t0 in
                guard let t0 else { return "n/a" }
                return String(format: "%.1fms", (CFAbsoluteTimeGetCurrent() - t0) * 1000)
            }
            info("focus BEGIN (tap→focus \(sinceTap)) sections=\(sections) rows=\(rows) queryLen=\(queryLen)")
        } else {
            let t0 = focusLock.withLock { started -> CFAbsoluteTime? in
                let v = started
                started = nil
                return v
            }
            tapLock.withLock { $0 = nil }
            if let t0 {
                info(String(format: "focus END after %.1fms", (CFAbsoluteTimeGetCurrent() - t0) * 1000))
            } else {
                info("focus END")
            }
        }
    }

    /// Trabajo en main tras el foco (1.er / 2.º yield) — anima teclado + posible layout.
    static func postFocusFrame(_ label: String, ms: Double) {
        info(String(format: "post-focus %@ %.1fms", label, ms))
    }

    static func rebuildSections(reason: String, count: Int, queryEmpty: Bool, ms: Double) {
        info(
            String(
                format: "rebuild reason=%@ items=%d queryEmpty=%@ %.2fms",
                reason,
                count,
                queryEmpty ? "true" : "false",
                ms
            )
        )
    }

    static func debounceApply(_ query: String, waitMs: Double) {
        info(String(format: "debounce apply \"%@\" after %.0fms", query, waitMs))
    }

    static func thumbMiss(name: String, ms: Double) {
        info(String(format: "thumb MISS %@ %.2fms", name, ms))
    }

    static func prefetch(count: Int, ms: Double) {
        info(String(format: "prefetch %d thumbs %.1fms", count, ms))
    }

    static func fieldAppear() {
        info("search field appear")
    }
}
