import Foundation
import os
import UIKit

/// Trazas del flujo escanear pizarra → OCR → parser (consola Xcode / Console.app).
enum BoardScanLog {
    private static let logger = Logger(subsystem: "app.gymbroapp.ios", category: "BoardScan")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        #if DEBUG
        print("[BoardScan] \(message)")
        #endif
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        #if DEBUG
        print("[BoardScan][ERROR] \(message)")
        #endif
    }

    static func image(_ image: UIImage, step: String) {
        let cg = image.cgImage
        info(
            "\(step): size=\(Int(image.size.width))x\(Int(image.size.height)) scale=\(image.scale) "
                + "orientation=\(image.imageOrientation.rawValue) "
                + "cgImage=\(cg.map { "\($0.width)x\($0.height)" } ?? "nil")"
        )
    }

    static func ocr(_ text: String) {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        info("OCR: \(text.count) chars, \(lines.count) lines")
        for (i, line) in lines.prefix(40).enumerated() {
            info("  [\(i)] \(line)")
        }
        if lines.count > 40 {
            info("  … +\(lines.count - 40) líneas más")
        }
    }

    static func parse(blocks: Int, lines: Int, movements: Int) {
        info("Parse: blocks=\(blocks) lines=\(lines) movements=\(movements)")
    }
}
