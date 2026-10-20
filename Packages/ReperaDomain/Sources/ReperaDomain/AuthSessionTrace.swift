import Foundation
import os

/// Trazas de arranque auth — Consola (`subsystem com.app.repera`, categoría `AuthSession`)
/// y en DEBUG también `🔐 AUTH …` en Xcode.
public enum AuthSessionTrace {
    private static let logger = Logger(subsystem: "com.app.repera", category: "AuthSession")

    public static func event(_ message: String, file: String = #fileID, line: Int = #line) {
        let lineText = "[\(file):\(line)] \(message)"
        logger.info("\(lineText, privacy: .public)")
        #if DEBUG
        print("🔐 AUTH \(lineText)")
        #endif
    }
}
