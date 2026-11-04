import Foundation
import os

/// Trazas de arranque auth — Consola (`subsystem com.app.repera`, categoría `AuthSession`)
/// y en DEBUG también `🔐 AUTH …` en Xcode.
/// Messages may contain user UUIDs or paths: only the call site is public in
/// the unified log; the message body is redacted outside a debugging session.
public enum AuthSessionTrace {
    private static let logger = Logger(subsystem: "com.app.repera", category: "AuthSession")

    public static func event(_ message: String, file: String = #fileID, line: Int = #line) {
        logger.info("[\(file, privacy: .public):\(line, privacy: .public)] \(message, privacy: .private)")
        #if DEBUG
        print("🔐 AUTH [\(file):\(line)] \(message)")
        #endif
    }
}
