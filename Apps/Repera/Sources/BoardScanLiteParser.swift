import Foundation
import ReperaDomain

/// Analizador local y lineal para fotos de pizarra.
/// Interpreta cada cabecera antes de asociar movimientos; evita hacer matching
/// difuso O(N×catálogo) en el hilo principal.
enum BoardScanLiteParser {
    struct Output: Sendable {
        var blocks: [RoutineBlock]
        var lines: [BoardImportLine]
    }

    private struct Header {
        var title: String
        var format: WODFormat
        var timeCapMinutes: Int?
        var rounds: Int?
        var intervalSeconds: Int?
    }

    static func parse(ocrText: String, catalog: [Exercise] = []) -> Output {
        let rawLines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Construir una sola vez: el OCR consulta claves exactas/canónicas.
        let index = Dictionary(
            catalog.map { (norm($0.name), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        func matchingExercise(_ name: String) -> Exercise? {
            let canonical = CrossFitGlossary.canonicalName(for: name)
            return index[norm(name)] ?? index[norm(canonical)]
        }

        var blocks: [RoutineBlock] = []
        var current: (header: Header, body: [String])?

        func flush() {
            guard let group = current else { return }
            let header = group.header
            let parsed = group.body.map { movement(from: $0) }
            let notes = ([header.title] + group.body).joined(separator: "\n")

            if header.format == .strength {
                // EVERY 2' × 4 con 4-3-3-2 es FUERZA, no un EMOM.
                // Si falta un ejercicio del catálogo, conservarlo como WOD de
                // fuerza editable: nunca descartarlo ni fingir que hizo match.
                var exercises: [RoutineExercise] = []
                for (source, move) in zip(group.body, parsed) where !move.isRest {
                    guard let match = matchingExercise(move.name) else { break }
                    let schemes = move.repScheme?.isEmpty == false
                        ? move.repScheme!
                        : Array(repeating: move.reps ?? 1, count: max(1, header.rounds ?? 1))
                    let rir = explicitSingleRIR(in: source)
                    let sets = schemes.map {
                        PlannedSet(targetReps: $0, targetRir: rir)
                    }
                    exercises.append(RoutineExercise(exerciseId: match.id, plannedSets: sets))
                }
                if !exercises.isEmpty && exercises.count == parsed.filter({ !$0.isRest }).count {
                    var strength = RoutineBlock.strength(title: header.title, exercises: exercises)
                    strength.wodNotes = notes
                    blocks.append(strength)
                } else {
                    var fallback = RoutineBlock.wod(format: .strength, title: header.title)
                    fallback.timeCapMinutes = nil
                    fallback.rounds = header.rounds
                    fallback.movements = parsed.map { resolved($0, index: index) }
                    fallback.wodNotes = notes
                    blocks.append(fallback)
                }
            } else {
                var wod = RoutineBlock.wod(format: header.format, title: header.title)
                wod.timeCapMinutes = header.timeCapMinutes
                wod.rounds = header.rounds ?? wod.rounds
                wod.emomIntervalSeconds = header.intervalSeconds ?? wod.emomIntervalSeconds
                wod.movements = parsed.map { resolved($0, index: index) }
                wod.wodNotes = notes
                wod.deriveEmomRoundsIfNeeded()
                blocks.append(wod)
            }
            current = nil
        }

        for line in rawLines {
            if let header = detectHeader(line) {
                flush()
                current = (header, [])
            } else if current != nil {
                current?.body.append(line)
            } else {
                current = (
                    Header(title: "Añadir entreno", format: .strength, timeCapMinutes: nil,
                           rounds: nil, intervalSeconds: nil),
                    [line]
                )
            }
        }
        flush()

        let lines: [BoardImportLine] = blocks.flatMap { block in
            if block.kind == .strength {
                return block.exercises.compactMap { ex -> BoardImportLine? in
                    guard let catalogExercise = catalog.first(where: { $0.id == ex.exerciseId }) else { return nil }
                    return BoardImportLine(
                        raw: catalogExercise.name,
                        matchedExerciseId: ex.exerciseId,
                        matchedName: catalogExercise.name,
                        sets: ex.plannedSets.count,
                        reps: ex.plannedSets.first?.targetReps ?? 1
                    )
                }
            }
            return block.movements.filter { !$0.isRest }.map { move in
                BoardImportLine(
                    raw: move.summaryLine,
                    matchedExerciseId: move.exerciseId,
                    matchedName: move.name,
                    sets: move.repScheme?.count ?? 1,
                    reps: move.reps ?? move.repScheme?.first ?? 1
                )
            }
        }
        return Output(blocks: blocks, lines: lines)
    }

    // MARK: - Cabeceras

    private static func detectHeader(_ line: String) -> Header? {
        let upper = line.uppercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "‘", with: "'")

        // Programación de fuerza: intervalo de inicio y número de series.
        if let range = upper.range(
            of: #"\b(?:EVERY|CADA)\s+(\d+)\s*(?:'|MIN(?:UTES?)?)?\s*[X×]\s*(\d+)"#,
            options: .regularExpression
        ) {
            let nums = String(upper[range]).split(whereSeparator: { !$0.isNumber })
                .compactMap { Int($0) }
            if nums.count >= 2 {
                return Header(
                    title: "Every \(nums[0])' × \(nums[1])",
                    format: .strength,
                    timeCapMinutes: nil,
                    rounds: nums[1],
                    intervalSeconds: nums[0] * 60
                )
            }
        }

        if upper.contains("EMOM") {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .emom, timeCapMinutes: mins,
                          rounds: nil, intervalSeconds: 60)
        }
        if upper.contains("AMRAP") {
            return Header(title: line, format: .amrap,
                          timeCapMinutes: firstInt(upper) ?? 10, rounds: nil, intervalSeconds: nil)
        }
        if upper.contains("RFT") || upper.contains("FOR TIME") {
            let cap: Int?
            if let tc = upper.range(of: #"\bTC\s*\d+"#, options: .regularExpression) {
                cap = firstInt(String(upper[tc]))
            } else if let tc = upper.range(of: #"\b\d+\s*(?:MIN)?\s*CAP\b"#, options: .regularExpression) {
                cap = firstInt(String(upper[tc]))
            } else {
                cap = nil
            }
            let rounds = upper.contains("RFT") ? firstInt(upper) : nil
            return Header(title: line, format: .forTime, timeCapMinutes: cap,
                          rounds: rounds, intervalSeconds: nil)
        }
        if upper.contains("TABATA") {
            return Header(title: line, format: .tabata, timeCapMinutes: 4,
                          rounds: 8, intervalSeconds: nil)
        }
        if upper.contains("EVERY") || upper.contains("CADA") {
            // Every N sec/min sin X sigue siendo intervalo cronometrado.
            let value = firstInt(upper) ?? 1
            let seconds = upper.contains("SEC") || upper.contains("\"") ? value : value * 60
            return Header(title: line, format: .emom, timeCapMinutes: nil,
                          rounds: nil, intervalSeconds: seconds)
        }
        return nil
    }

    // MARK: - Movimientos

    private static func movement(from line: String) -> WODMovement {
        let intensity = line.range(of: #"@\s*\d+(?:[.,]\d+)?\s*[-–]\s*\d+(?:[.,]\d+)?"#,
                                   options: .regularExpression)
        let rpeNote = intensity.map {
            "RPE " + String(line[$0]).replacingOccurrences(of: "@", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        let parsed = CrossFitGlossary.parseMovementLine(line)
        if parsed.isRest {
            return WODMovement(name: "REST", isRest: true, restSeconds: parsed.restSeconds)
        }
        let notes = [parsed.equipmentNote, rpeNote].compactMap { $0 }
            .filter { !$0.isEmpty }.joined(separator: " · ")
        return WODMovement(
            name: parsed.name,
            reps: parsed.reps,
            repScheme: parsed.repScheme,
            distanceMeters: parsed.distanceMeters,
            calories: parsed.calories,
            weightMaleKg: parsed.weightMaleKg,
            weightFemaleKg: parsed.weightFemaleKg,
            notes: notes.isEmpty ? nil : notes
        )
    }

    private static func resolved(_ movement: WODMovement, index: [String: Exercise]) -> WODMovement {
        guard !movement.isRest else { return movement }
        var move = movement
        let canonical = CrossFitGlossary.canonicalName(for: movement.name)
        if let match = index[norm(movement.name)] ?? index[norm(canonical)] {
            move.exerciseId = match.id
            move.name = match.name
        } else {
            move.name = canonical
        }
        return move
    }

    private static func explicitSingleRIR(in line: String) -> Double? {
        guard let range = line.range(of: #"@\s*RIR\s*\d+(?:[.,]\d+)?\b"#,
                                     options: [.regularExpression, .caseInsensitive]) else { return nil }
        let value = String(line[range]).replacingOccurrences(
            of: #"(?i)^@\s*RIR\s*"#, with: "", options: .regularExpression
        ).replacingOccurrences(of: ",", with: ".")
        return Double(value)
    }

    private static func firstInt(_ text: String) -> Int? {
        guard let token = text.range(of: #"\d+"#, options: .regularExpression) else { return nil }
        return Int(text[token])
    }

    private static func norm(_ string: String) -> String {
        CrossFitGlossary.normalize(string)
    }
}
