import Foundation
import GymbroDomain

/// Parser mínimo de pizarra: cabeceras + líneas tipadas vía `CrossFitGlossary.parseMovementLine`.
/// Sin BoardImportParser pesado / hilos / IA. Objetivo: nunca bloquear.
enum BoardScanLiteParser {
    struct Output: Sendable {
        var blocks: [RoutineBlock]
        var lines: [BoardImportLine]
    }

    static func parse(ocrText: String, catalog: [Exercise] = []) -> Output {
        let rawLines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [RoutineBlock] = []
        var current: (header: String, format: WODFormat, cap: Int?, body: [String])?

        func flush() {
            guard let cur = current else { return }
            var block = RoutineBlock.wod(
                format: cur.format,
                title: cur.header.isEmpty ? cur.format.rawValue : cur.header
            )
            block.timeCapMinutes = cur.cap
            if cur.format == .emom {
                block.emomIntervalSeconds = 60
            }
            block.movements = cur.body.map { movement(from: $0) }
            block.wodNotes = ([cur.header] + cur.body).joined(separator: "\n")
            block.deriveEmomRoundsIfNeeded()
            blocks.append(block)
            current = nil
        }

        for line in rawLines {
            if let header = detectHeader(line) {
                flush()
                current = (header.title, header.format, header.cap, [])
            } else if current != nil {
                current?.body.append(line)
            } else {
                current = ("Añadir entreno", .chipper, nil, [line])
            }
        }
        flush()

        if blocks.isEmpty, !rawLines.isEmpty {
            var block = RoutineBlock.wod(format: .chipper, title: "Añadir entreno")
            block.movements = rawLines.map { movement(from: $0) }
            block.wodNotes = ocrText
            blocks = [block]
        }

        // Match catálogo por nombre canónico.
        if !catalog.isEmpty {
            let index = Dictionary(
                catalog.map { (norm($0.name), $0) },
                uniquingKeysWith: { a, _ in a }
            )
            blocks = blocks.map { block in
                var b = block
                b.movements = block.movements.map { move in
                    guard !move.isRest else { return move }
                    var m = move
                    let canonical = CrossFitGlossary.canonicalName(for: move.name)
                    let keys = [norm(move.name), norm(canonical)]
                    if let ex = keys.lazy.compactMap({ index[$0] }).first {
                        m.exerciseId = ex.id
                        m.name = ex.name
                    } else if canonical != move.name {
                        m.name = canonical
                    }
                    return m
                }
                return b
            }
        }

        let lines: [BoardImportLine] = blocks.flatMap { block in
            block.movements.filter { !$0.isRest }.map { move in
                BoardImportLine(
                    raw: move.summaryLine,
                    matchedExerciseId: move.exerciseId,
                    matchedName: move.name,
                    sets: 1,
                    reps: move.reps ?? move.repScheme?.first ?? 1
                )
            }
        }

        return Output(blocks: blocks, lines: lines)
    }

    // MARK: - Internals

    private struct Header {
        var title: String
        var format: WODFormat
        var cap: Int?
    }

    private static func detectHeader(_ line: String) -> Header? {
        let upper = line.uppercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")

        if upper.contains("EMOM") {
            let mins = firstInt(upper) ?? 10
            return Header(title: "EMOM \(mins)'", format: .emom, cap: mins)
        }
        if upper.contains("AMRAP") {
            let mins = firstInt(upper) ?? 10
            return Header(title: "AMRAP \(mins)'", format: .amrap, cap: mins)
        }
        if upper.contains("FOR TIME") || upper.hasPrefix("RFT") {
            return Header(title: line, format: .forTime, cap: firstInt(upper))
        }
        if upper.contains("TABATA") {
            return Header(title: "Tabata", format: .tabata, cap: nil)
        }
        if upper.contains("EVERY") && (upper.contains("MIN") || upper.contains("'") || upper.contains("SEC")) {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .emom, cap: mins)
        }
        return nil
    }

    private static func movement(from line: String) -> WODMovement {
        let parsed = CrossFitGlossary.parseMovementLine(line)
        if parsed.isRest {
            return WODMovement(
                name: "REST",
                isRest: true,
                restSeconds: parsed.restSeconds
            )
        }
        return WODMovement(
            name: parsed.name,
            reps: parsed.reps,
            repScheme: parsed.repScheme,
            distanceMeters: parsed.distanceMeters,
            calories: parsed.calories,
            weightMaleKg: parsed.weightMaleKg,
            weightFemaleKg: parsed.weightFemaleKg,
            notes: parsed.equipmentNote
        )
    }

    private static func firstInt(_ text: String) -> Int? {
        var digits = ""
        for ch in text {
            if ch.isNumber {
                digits.append(ch)
            } else if !digits.isEmpty {
                break
            }
        }
        return Int(digits)
    }

    private static func norm(_ s: String) -> String {
        CrossFitGlossary.normalize(s)
    }
}
