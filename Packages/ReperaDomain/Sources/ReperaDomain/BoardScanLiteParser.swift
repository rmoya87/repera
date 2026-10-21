import Foundation

/// Parser mínimo de pizarra: cabeceras + líneas tipadas vía `CrossFitGlossary.parseMovementLine`.
/// Sin BoardImportParser pesado / hilos / IA. Objetivo: nunca bloquear.
public enum BoardScanLiteParser {
    public struct Output: Sendable {
        public var blocks: [RoutineBlock]
        public var lines: [BoardImportLine]
    }

    public static func parse(ocrText: String, catalog: [Exercise] = []) -> Output {
        let rawLines = normalizeOCRNoise(ocrText)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [RoutineBlock] = []
        var sectionTitle: String?
        var intervalDescription: String?
        var current: (header: String, format: WODFormat, cap: Int?, rounds: Int?, interval: Int?, body: [String])?

        func flush() {
            guard let cur = current else { return }
            if let strength = Self.structuredStrength(
                cur.header, cur.body, interval: cur.interval,
                cap: cur.cap, rounds: cur.rounds, catalog: catalog
            ) {
                blocks.append(strength)
                current = nil
                return
            }
            var block = RoutineBlock.wod(
                format: cur.format,
                title: cur.header.isEmpty ? cur.format.rawValue : cur.header
            )
            block.timeCapMinutes = cur.cap
            // El TC pertenece al bloque entero; no crear rondas por defecto.
            block.rounds = cur.format == .forTime ? cur.rounds : (cur.rounds ?? block.rounds)
            if cur.format == .emom {
                block.emomIntervalSeconds = cur.interval ?? 60
            }
            block.movements = cur.body.filter { line in
                let upper = line.uppercased()
                return !upper.contains("CAP: 4 INTERVALOS") &&
                    !upper.hasPrefix("REALIZA AMBOS") &&
                    !upper.hasPrefix("NO TOUCH")
            }.map { movement(from: $0) }
            if let values = Self.capture(
                #"(?i)(\d+)\s*MIN\s*ON.*?(\d+)\s*MIN\s*OFF"#, from: cur.header
            ), values.count == 2, let work = Int(values[0]), let rest = Int(values[1]) {
                block.workSeconds = work * 60
                block.restSeconds = rest * 60
            }
            // 'REST BTWN' describe el descanso *entre* pasadas, no un ejercicio
            // extra al final de la última. Se preserva la anotación original.
            if cur.format == .forTime {
                for (position, line) in cur.body.enumerated().reversed() {
                    if line.uppercased().contains("BTWN") || line.uppercased().contains("BETWEEN") || line.uppercased().contains("ENTRE RONDAS") {
                        if block.movements.indices.contains(position),
                           block.movements[position].isRest {
                            block.restBetweenRoundsSeconds = block.movements[position].restSeconds
                            block.movements.remove(at: position)
                        }
                    }
                }
                if block.restBetweenRoundsSeconds == nil,
                   let rest = block.movements.first(where: { $0.isRest }) {
                    block.restBetweenRoundsSeconds = rest.restSeconds
                }
            }
            block.wodNotes = ([cur.header] + cur.body).joined(separator: "\n")
            block.deriveEmomRoundsIfNeeded()
            blocks.append(block)
            current = nil
        }

        for line in rawLines {
            let upper = line.uppercased()
            if upper == "METCON" || upper.hasPrefix("WEIGHTLIFTING")
                || upper == "PULLING STRENGTH & POWER" {
                flush()
                sectionTitle = line
                continue
            }
            if upper.contains("INTERVALOS DE") && upper.contains("ON") && upper.contains("OFF") {
                intervalDescription = line
                continue
            }
            if let header = detectHeader(line) {
                flush()
                let title = [sectionTitle, intervalDescription, header.title]
                    .compactMap { $0 }.joined(separator: " · ")
                current = (title, header.format, header.cap, header.rounds, header.interval, [])
                sectionTitle = nil
                intervalDescription = nil
            } else if isQualityAnnotation(line) {
                // Vision puede separar «EMOM 9' @FOR QUALITY» en @FOR + QUALITY.
                // Es una instrucción de ejecución, nunca un ejercicio.
                if let title = current?.header, !title.uppercased().contains("QUALITY") {
                    current?.header = title.uppercased().hasSuffix("@FOR")
                        ? title + " QUALITY" : title + " · FOR QUALITY"
                }
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

    /// Vision a menudo pega tokens (`4RFf`, `8BOB`) o lee T→F (`RFF`).
    public static func normalizeOCRNoise(_ text: String) -> String {
        text
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "×", with: "X")
            // 4RFf / 4RFF / 4RFT → "4 RFT"
            .replacingOccurrences(
                of: #"(?i)(\d+)\s*RF[TF]\b"#,
                with: "$1 RFT",
                options: .regularExpression
            )
            // TC12 / TC12? → TC 12
            .replacingOccurrences(
                of: #"(?i)\bTC\s*[:=]?\s*(\d+)"#,
                with: "TC $1",
                options: .regularExpression
            )
            // 10BBJO / 10BBJ0 (Vision confunde O y 0) → "10 BBJO"
            .replacingOccurrences(
                of: #"(?i)(\d+)\s*BBJ[O0]\b"#,
                with: "$1 BBJO",
                options: .regularExpression
            )
            // 8BOB / 8BFB → "8 BOB"
            .replacingOccurrences(
                of: #"(?i)(\d+)(BOB|BFB)\b"#,
                with: "$1 $2",
                options: .regularExpression
            )
            // EVERY2'X4 → EVERY 2' X 4
            .replacingOccurrences(
                of: #"(?i)\b(EVERY|CADA)\s*(\d+)\s*'?\s*X\s*(\d+)\b"#,
                with: "$1 $2' X $3",
                options: .regularExpression
            )
    }

    /// Metadatos breves de calidad, incluso cuando el OCR corta «@FOR QUALITY».
    /// No captura líneas como «5 KIPPING RING DIPS» ni cabeceras con rondas.
    static func isQualityAnnotation(_ line: String) -> Bool {
        let normalized = line.uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: " @:.-"))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return ["QUALITY", "FOR QUALITY", "FQ", "RFQ", "FOR"].contains(normalized)
    }

    private static func detectHeader(_ line: String) -> Header? {
        let upper = line.uppercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "×", with: "X")

        if upper.range(of: #"^\d+\s+ROUNDS?\s+(?:FOR\s+QUALITY|RFQ)\b"#,
                       options: .regularExpression) != nil {
            return Header(title: line, format: .roundsForQuality, cap: nil, rounds: firstInt(upper))
        }
        if let values = Self.capture(
            #"(?i)^EVERY\s+(\d+)\s*S\s+FOR\s+(\d+)\s*MIN"#, from: line
        ), values.count == 2,
           let seconds = Int(values[0]), let minutes = Int(values[1]) {
            let rounds = Self.capture(
                #"(?i)\((\d+)\s*(?:SERIES|RONDAS?)\)"#, from: line
            )?.first.flatMap(Int.init)
            return Header(title: line, format: .emom,
                          cap: minutes, rounds: rounds, interval: seconds)
        }
        if upper.hasPrefix("EMOM") {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .emom, cap: mins)
        }
        if upper.hasPrefix("AMRAP") {
            let mins = firstInt(upper) ?? 10
            return Header(title: line, format: .amrap, cap: mins)
        }
        // 4 RFT (TC 12') — también OCR «4RFf(TC 12?» (T leída como F).
        let rftMatch = upper.range(of: #"^\d+\s*RF[TF]\b"#, options: .regularExpression)
        if rftMatch != nil || upper.hasPrefix("RFT") || upper.hasPrefix("RFF")
            || upper.contains("FOR TIME")
        {
            // El número de TC 14' es un límite de TIEMPO del bloque completo.
            // Nunca usarlo como número de rondas ni de series de cada movimiento.
            let rounds = rftMatch.flatMap { firstInt(String(upper[$0])) }
                ?? upper.range(of: #"^\s*(\d+)\s+ROUNDS?\b"#, options: .regularExpression)
                    .flatMap { firstInt(String(upper[$0])) }
            let timeCap = upper.range(of: #"(?:TC|TIME\s*CAP|CAP)\s*[:=]?\s*\d+"#,
                                      options: .regularExpression)
                .flatMap { firstInt(String(upper[$0])) }
            let altCap = Self.capture(#"(?i)(\d+)\s*MIN\s*CAP"#, from: line)?.first.flatMap(Int.init)
            let title = rftMatch != nil
                ? line.replacingOccurrences(
                    of: #"(?i)(\d+)\s*RF[TF]\b"#,
                    with: "$1 RFT",
                    options: .regularExpression
                )
                : line
            return Header(title: title, format: .forTime, cap: timeCap ?? altCap, rounds: rounds)
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

    private static func capture(_ pattern: String, from text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        return (1..<match.numberOfRanges).compactMap { index in
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
    }

    private static func structuredStrength(
        _ header: String, _ lines: [String], interval: Int?,
        cap: Int?, rounds: Int?, catalog: [Exercise]
    ) -> RoutineBlock? {
        let name = CrossFitGlossary.normalize
        if lines.contains(where: { $0.uppercased().contains("SQUAT SNATCH") && $0.uppercased().contains("SETS") }) {
            var plan: [Int: PlannedSet] = [:]
            for line in lines {
                guard let fields = capture(
                    #"(?i)SETS?\s*(\d+)\s*[-–]\s*(\d+)\s*:\s*(\d+)\s+SQUAT\s+SNATCH\s*#?\s*>?\s*(\d+)\s*%"#,
                    from: line
                ), fields.count == 4,
                   let start = Int(fields[0]), let end = Int(fields[1]),
                   let reps = Int(fields[2]), let percent = Double(fields[3]),
                   start > 0 && end <= 30 && start <= end else { continue }
                for index in start...end {
                    plan[index] = PlannedSet(targetReps: reps, targetPercent1RM: percent)
                }
            }
            let expected = rounds ?? plan.count
            guard expected > 0, plan.count == expected,
                  let exercise = catalog.first(where: { name($0.name) == name("Arrancada") })
            else { return nil }
            let sets = (1...expected).compactMap { plan[$0] }
            guard sets.count == expected else { return nil }
            var block = RoutineBlock.strength(
                title: header,
                exercises: [RoutineExercise(exerciseId: exercise.id, plannedSets: sets)]
            )
            block.emomIntervalSeconds = interval
            block.timeCapMinutes = cap
            block.wodNotes = ([header] + lines).joined(separator: "\n")
            return block
        }
        guard let a = lines.first(where: { $0.uppercased().hasPrefix("A:") }),
              let b = lines.first(where: { $0.uppercased().hasPrefix("B:") }),
              let roundCount = rounds, roundCount > 0 && roundCount <= 30,
              let left = capture(#"(?i)^A:\s*(\d+)\s+(.+)$"#, from: a),
              let right = capture(#"(?i)^B:\s*(\d+)\s+(.+)$"#, from: b),
              left.count == 2, right.count == 2,
              let lReps = Int(left[0]), let rReps = Int(right[0]),
              let pull = catalog.first(where: { name($0.name) == name("Dominadas") }),
              let row = catalog.first(where: { name($0.name) == name("Remo en anillas") })
        else { return nil }
        let percent = capture(#"#\s*(\d+)\s*%"#, from: left[1])?.first.flatMap(Double.init)
        var block = RoutineBlock.strength(title: header, exercises: [
            RoutineExercise(exerciseId: pull.id, plannedSets: (0..<roundCount).map { _ in
                PlannedSet(targetReps: lReps, targetPercent1RM: percent)
            }),
            RoutineExercise(exerciseId: row.id, plannedSets: (0..<roundCount).map { _ in
                PlannedSet(targetReps: rReps)
            }),
        ])
        block.emomIntervalSeconds = interval
        block.timeCapMinutes = cap
        block.wodNotes = ([header] + lines).joined(separator: "\n")
        return block
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
        // Alternativas de escala "3 BMU / 6 C2B / 9 Pull-ups" o "40 DU / 80 SU".
        // El slash con espacios NO representa carga H/M.
        var scaleAlternative: String?
        let caloriePair = working.range(
            of: #"(?i)^\s*\d+\s*/\s*\d+\s*CALS?(?:ORIES)?\b"#,
            options: .regularExpression
        ) != nil
        // «20 / 16 CAL» sigue siendo objetivo H/M aunque OCR añada espacios.
        let alternatives = caloriePair ? [working] : working.components(separatedBy: #" / "#)
        if alternatives.count >= 2 {
            working = alternatives[0].trimmingCharacters(in: .whitespaces)
            scaleAlternative = alternatives.dropFirst()
                .map { CrossFitGlossary.expand($0.trimmingCharacters(in: .whitespaces)) }
                .joined(separator: " / ")
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
            scaleAlternative: scaleAlternative,
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
