import Foundation

/// Parser mínimo de pizarra: cabeceras + líneas tipadas vía `CrossFitGlossary.parseMovementLine`.
/// Sin BoardImportParser pesado / hilos / IA. Objetivo: nunca bloquear.
public enum BoardScanLiteParser {
    public struct Output: Sendable {
        public var blocks: [RoutineBlock]
        public var lines: [BoardImportLine]
    }

    public static func parse(ocrText: String, catalog: [Exercise] = []) -> Output {
        let rawLines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [RoutineBlock] = []
        var current: (header: String, format: WODFormat, cap: Int?, rounds: Int?, interval: Int?, body: [String])?

        func flush() {
            guard let cur = current else { return }
            var block = RoutineBlock.wod(
                format: cur.format,
                title: cur.header.isEmpty ? cur.format.rawValue : cur.header
            )
            block.timeCapMinutes = cur.cap
            block.rounds = cur.rounds ?? block.rounds
            if cur.format == .emom {
                block.emomIntervalSeconds = cur.interval ?? 60
            }
            block.movements = cur.body.map { movement(from: $0) }
            if cur.format == .forTime, let rest = block.movements.first(where: { $0.isRest }) {
                block.restBetweenRoundsSeconds = rest.restSeconds
            }
            block.wodNotes = ([cur.header] + cur.body).joined(separator: "\n")
            block.deriveEmomRoundsIfNeeded()
            blocks.append(block)
            current = nil
        }

        for line in rawLines {
            if let header = detectHeader(line) {
                flush()
                current = (header.title, header.format, header.cap, header.rounds, header.interval, [])
            } else if current != nil {
                current?.body.append(line)
            } else {
                current = ("Añadir entreno", .chipper, nil, nil, nil, [line])
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
                // Un único movimiento, una onda de 4 series y «Every 2'×4»:
                // registrarlo como fuerza editable (no como EMOM de estaciones).
                if b.wodFormat == .emom,
                   b.title.uppercased().hasPrefix("EVERY ") || b.title.uppercased().hasPrefix("CADA "),
                   let interval = b.emomIntervalSeconds, interval > 0,
                   b.movements.count == 1,
                   let move = b.movements.first, !move.isRest,
                   let exerciseID = move.exerciseId,
                   let scheme = move.repScheme, scheme.count == b.rounds {
                    let rir = rpeMidpointRIR(from: move.notes)
                    let sets = scheme.map { PlannedSet(targetReps: $0, targetWeightKg: move.weightMaleKg, targetRir: rir) }
                    var strength = RoutineBlock.strength(
                        title: b.title,
                        exercises: [RoutineExercise(exerciseId: exerciseID, plannedSets: sets)]
                    )
                    strength.emomIntervalSeconds = interval
                    strength.timeCapMinutes = b.timeCapMinutes
                    strength.wodNotes = b.wodNotes
                    return strength
                }
                return b
            }
        }

        let byExerciseID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0.name) })
        let lines: [BoardImportLine] = blocks.flatMap { block -> [BoardImportLine] in
            if block.kind == .strength {
                return block.exercises.map { ex in
                    BoardImportLine(
                        raw: block.wodNotes ?? "",
                        matchedExerciseId: ex.exerciseId,
                        matchedName: byExerciseID[ex.exerciseId],
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
        var rounds: Int? = nil
        var interval: Int? = nil
    }

    private static func detectHeader(_ line: String) -> Header? {
        let upper = line.uppercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "×", with: "X")

        if upper.hasPrefix("EMOM") {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .emom, cap: mins)
        }
        if upper.hasPrefix("AMRAP") {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .amrap, cap: mins)
        }
        // 4 RFT (TC 12') → 4 rondas, límite 12 min. El primer 4 NO es el time cap.
        if upper.range(of: #"^\d+\s*RFT\b"#, options: .regularExpression) != nil ||
           upper.hasPrefix("RFT") || upper.contains("FOR TIME") {
            let rounds = upper.range(of: #"^\d+\s*RFT\b"#, options: .regularExpression)
                .flatMap { firstInt(String(upper[$0])) }
            let timeCap = upper.range(of: #"(?:TC|TIME\s*CAP|CAP)\s*[:=]?\s*\d+"#,
                                      options: .regularExpression)
                .flatMap { firstInt(String(upper[$0]).filter { $0.isNumber }) }
            return Header(title: line, format: .forTime, cap: timeCap, rounds: rounds)
        }
        if upper.contains("TABATA") {
            return Header(title: line, format: .tabata, cap: nil)
        }
        // Every 2' x 4 / Every 2 min x 4. Conserva el intervalo y las cuatro series.
        if let match = upper.range(of: #"^(?:EVERY|CADA)\s+\d+\s*(?:'|MIN(?:UTES?)?)?\s*X\s*\d+"#,
                                   options: .regularExpression) {
            let values = String(upper[match]).split { !$0.isNumber }.compactMap { Int($0) }
            if values.count == 2 {
                let seconds = values[0] * 60
                return Header(title: line, format: .emom,
                              cap: values[0] * values[1], rounds: values[1], interval: seconds)
            }
        }
        if upper.hasPrefix("EVERY") || upper.hasPrefix("CADA") {
            let value = firstInt(upper) ?? 1
            if upper.contains("SEC") || upper.contains("\"") {
                return Header(title: line, format: .emom, cap: nil, interval: value)
            }
            return Header(title: line, format: .emom, cap: nil, interval: value * 60)
        }
        return nil
    }

    /// RPE 6–8 es un rango de esfuerzo. Guardamos íntegro el rango en notas
    /// y empleamos el punto medio RPE 7 (≈ RIR 3) como objetivo editable de fuerza.
    private static func rpeMidpointRIR(from notes: String?) -> Double? {
        guard let notes,
              let match = notes.range(of: #"RPE\s*(\d+(?:[.,]\d+)?)\s*[-–]\s*(\d+(?:[.,]\d+)?)"#,
                                      options: .regularExpression) else { return nil }
        let numbers = String(notes[match]).split { !$0.isNumber && $0 != "." && $0 != "," }
            .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        guard numbers.count == 2 else { return nil }
        return Effort.toRIR(value: (numbers[0] + numbers[1]) / 2, unit: .rpe)
    }

    private static func movement(from line: String) -> WODMovement {
        var working = line
        var notes: [String] = []
        if let rpe = working.range(of: #"@\s*\d+(?:[.,]\d+)?\s*[-–]\s*\d+(?:[.,]\d+)?"#,
                                   options: .regularExpression) {
            notes.append("RPE " + String(working[rpe]).replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces))
            working.removeSubrange(rpe)
        }
        let parsed = CrossFitGlossary.parseMovementLine(working)
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
            notes: (notes + [parsed.equipmentNote].compactMap { $0 }).isEmpty ? nil : (notes + [parsed.equipmentNote].compactMap { $0 }).joined(separator: " · ")
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
