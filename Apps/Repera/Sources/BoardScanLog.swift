import Foundation
import ReperaDomain
import os
import UIKit

/// Trazas del flujo escanear pizarra → OCR → parser → IA → revisión.
/// Filtra en Xcode / Console.app: subsystem `com.app.repera` · category `BoardScan`
/// o busca `[BoardScan]`.
enum BoardScanLog {
    private static let logger = Logger(subsystem: "com.app.repera", category: "BoardScan")

    /// Reloj de la pasada actual (ms desde `beginPass`).
    private final class PassState: @unchecked Sendable {
        let lock = NSLock()
        var passStartedAt: CFAbsoluteTime?
        var passId: String = "—"
        var lastStepAt: CFAbsoluteTime?
    }

    private static let state = PassState()

    // MARK: - Pass lifecycle

    /// Empieza una pasada de escaneo (cámara/galería → revisión).
    @discardableResult
    static func beginPass(_ label: String) -> String {
        let id = String(UUID().uuidString.prefix(8))
        let now = CFAbsoluteTimeGetCurrent()
        state.lock.lock()
        state.passId = id
        state.passStartedAt = now
        state.lastStepAt = now
        state.lock.unlock()
        emit("▶ PASS \(id) START · \(label)", level: .notice)
        return id
    }

    static func endPass(ok: Bool, detail: String = "") {
        let elapsed = elapsedMs()
        let id = currentPassId()
        let summary =
            "◀ PASS \(id) \(ok ? "OK" : "FAIL") · total=\(elapsed)ms"
                + (detail.isEmpty ? "" : " · \(detail)")
        emit(summary, level: ok ? .notice : .error)
        if let url = lastPassURL {
            let body = "\(ISO8601DateFormatter().string(from: Date()))\n\(summary)\n"
            try? body.write(to: url, atomically: true, encoding: .utf8)
        }
        state.lock.lock()
        state.passStartedAt = nil
        state.lastStepAt = nil
        state.passId = "—"
        state.lock.unlock()
    }

    // MARK: - Steps

    static func step(_ name: String, _ detail: String = "") {
        let sinceStart = elapsedMs()
        let sinceLast = stepDeltaMs()
        let msg = detail.isEmpty
            ? "• \(name)  [+\(sinceLast)ms · Σ\(sinceStart)ms]"
            : "• \(name)  [+\(sinceLast)ms · Σ\(sinceStart)ms] \(detail)"
        emit(msg, level: .info)
    }

    static func info(_ message: String) {
        emit(message, level: .info)
    }

    static func error(_ message: String) {
        emit("[ERROR] \(message)", level: .error)
    }

    static func image(_ image: UIImage, step stepName: String) {
        let cg = image.cgImage
        step(
            stepName,
            "size=\(Int(image.size.width))x\(Int(image.size.height)) scale=\(image.scale) "
                + "orientation=\(image.imageOrientation.rawValue) "
                + "cg=\(cg.map { "\($0.width)x\($0.height)" } ?? "nil") "
                + "mem~\(approxImageBytes(image) / 1024)KB"
        )
    }

    static func jpegPrepared(bytes: Int, path: String) {
        step("jpeg.ready", "bytes=\(bytes) path=\(path)")
    }

    static func ocr(_ text: String) {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        // Solo resumen en archivo (las líneas van a print/Logger; evitar I/O masivo en MainActor).
        step("ocr.text", "chars=\(text.count) lines=\(lines.count)")
        for (i, line) in lines.prefix(20).enumerated() {
            print("[BoardScan]     ocr[\(i)] \(line)")
        }
        if lines.count > 20 {
            print("[BoardScan]     ocr… +\(lines.count - 20) líneas")
        }
    }

    static func parse(blocks: Int, lines: Int, movements: Int) {
        step("parse.counts", "blocks=\(blocks) lines=\(lines) movements=\(movements)")
    }

    static func blocksSummary(_ blocks: [RoutineBlock], prefix: String) {
        if blocks.isEmpty {
            step("\(prefix).blocks", "vacío")
            return
        }
        step("\(prefix).blocks", "count=\(blocks.count)")
        for (i, block) in blocks.enumerated() {
            let moves = block.movements.filter { !$0.isRest }.count
            let rests = block.movements.filter(\.isRest).count
            let ex = block.exercises.count
            emit(
                "    block[\(i)] kind=\(block.kind.rawValue) format=\(block.wodFormat?.rawValue ?? "—") "
                    + "title=\(block.headerLabel) "
                    + "cap=\(block.timeCapMinutes.map(String.init) ?? "—")' "
                    + "rounds=\(block.rounds.map(String.init) ?? "—") "
                    + "interval=\(block.emomIntervalSeconds.map(String.init) ?? "—")s "
                    + "moves=\(moves) rest=\(rests) strengthEx=\(ex)",
                level: .debug
            )
            for (j, m) in block.movements.prefix(12).enumerated() {
                let bits: [String] = [
                    m.isRest ? "REST" : m.name,
                    m.reps.map { "reps=\($0)" },
                    m.repScheme.map { "wave=\($0)" },
                    m.distanceMeters.map { "m=\($0)" },
                    m.exerciseId != nil ? "id✓" : "id✗",
                ].compactMap { $0 }
                emit("      mov[\(j)] \(bits.joined(separator: " "))", level: .debug)
            }
            if block.movements.count > 12 {
                emit("      mov… +\(block.movements.count - 12)", level: .debug)
            }
        }
    }

    static func aiAvailability(available: Bool, reason: String? = nil) {
        if available {
            step("ai.availability", "available=YES")
        } else {
            step("ai.availability", "available=NO reason=\(reason ?? "?")")
        }
    }

    static func actorHint(_ where_: String) {
        let main = Thread.isMainThread
        step("actor", "\(where_) mainThread=\(main)")
    }

    // MARK: - Internals

    private enum Level { case debug, info, notice, error }

    private static func emit(_ message: String, level: Level) {
        let id = currentPassId()
        let line = "[\(id)] \(message)"
        // Siempre a stdout (Xcode console) para depurar en dispositivo.
        print("[BoardScan] \(line)")
        appendToFile(line)
        switch level {
        case .debug:
            logger.debug("\(line, privacy: .public)")
        case .info:
            logger.info("\(line, privacy: .public)")
        case .notice:
            logger.notice("\(line, privacy: .public)")
        case .error:
            logger.error("\(line, privacy: .public)")
        }
    }

    /// Ruta del log persistente (Documents/BoardScan.log) — copiar del iPhone vía Xcode Devices / Finder.
    static var logFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("BoardScan.log")
    }

    /// Resumen de la última pasada (Documents/BoardScanLastPass.txt).
    static var lastPassURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("BoardScanLastPass.txt")
    }

    private static let fileLock = NSLock()

    private static func appendToFile(_ line: String) {
        guard let url = logFileURL else { return }
        let stamp = ISO8601DateFormatter().string(from: Date())
        let row = "\(stamp) \(line)\n"
        guard let data = row.data(using: .utf8) else { return }
        fileLock.lock()
        defer { fileLock.unlock() }
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        do {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }
        // Recortar solo con el handle ya cerrado (evitar deadlock Data+FileHandle).
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber,
              size.intValue > 512_000,
              let existing = try? Data(contentsOf: url),
              existing.count > 256_000
        else { return }
        try? Data(existing.suffix(256_000)).write(to: url, options: .atomic)
    }

    private static func currentPassId() -> String {
        state.lock.lock(); defer { state.lock.unlock() }
        return state.passId
    }

    private static func elapsedMs() -> Int {
        state.lock.lock(); defer { state.lock.unlock() }
        guard let start = state.passStartedAt else { return 0 }
        return Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
    }

    private static func stepDeltaMs() -> Int {
        state.lock.lock()
        let last = state.lastStepAt ?? state.passStartedAt ?? CFAbsoluteTimeGetCurrent()
        let now = CFAbsoluteTimeGetCurrent()
        state.lastStepAt = now
        state.lock.unlock()
        return Int((now - last) * 1000)
    }

    private static func approxImageBytes(_ image: UIImage) -> Int {
        guard let cg = image.cgImage else {
            return Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        }
        return cg.bytesPerRow * cg.height
    }
}
