import Foundation

/// Línea detectada en una pizarra / TV (OCR).
public struct BoardImportLine: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var raw: String
    public var matchedExerciseId: UUID?
    public var matchedName: String?
    public var sets: Int
    public var reps: Int
    public var weightKg: Double?
    public var isIncluded: Bool

    public init(
        id: UUID = UUID(),
        raw: String,
        matchedExerciseId: UUID? = nil,
        matchedName: String? = nil,
        sets: Int = 3,
        reps: Int = 8,
        weightKg: Double? = nil,
        isIncluded: Bool = true
    ) {
        self.id = id
        self.raw = raw
        self.matchedExerciseId = matchedExerciseId
        self.matchedName = matchedName
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.isIncluded = isIncluded
    }
}

public enum BoardImportParser {
    /// Parsea texto OCR: una línea por ejercicio (fuerza clásica).
    public static func parse(ocrText: String, catalog: [Exercise]) -> [BoardImportLine] {
        let lines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 1 }

        return lines.compactMap { line -> BoardImportLine? in
            guard !isNoise(line), !isBlockHeader(line) else { return nil }
            let parsed = parseLine(line)
            let match = bestMatch(for: parsed.name, in: catalog)
            return BoardImportLine(
                raw: line,
                matchedExerciseId: match?.id,
                matchedName: match?.name ?? CrossFitGlossary.canonicalName(for: parsed.name),
                sets: parsed.sets,
                reps: parsed.reps,
                weightKg: parsed.weightKg,
                isIncluded: true
            )
        }
    }

    public static func buildRoutine(
        title: String,
        lines: [BoardImportLine],
        catalog: inout [Exercise],
        ocrText: String? = nil
    ) -> Routine {
        let joined = ocrText ?? lines.map(\.raw).joined(separator: "\n")
        let blocks = parseBlocks(ocrText: joined, catalog: catalog)
        // Bloque único "Desde pizarra" = salvamento sin cabeceras; si hay líneas tipadas, preferir fuerza clásica.
        let onlyHeaderlessSalvage = blocks.count == 1
            && blocks[0].title == "Desde pizarra"
            && blocks[0].wodFormat == .chipper
        if !blocks.isEmpty, !(onlyHeaderlessSalvage && lines.contains(where: \.isIncluded)) {
            return Routine(title: title, weekday: nil, blocks: blocks, progression: .off)
        }
        var exercises: [RoutineExercise] = []
        for line in lines where line.isIncluded {
            let exerciseId: UUID
            if let id = line.matchedExerciseId {
                exerciseId = id
            } else {
                let name = (line.matchedName ?? line.raw).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let custom = Exercise(name: name, muscleGroup: "Custom", isCustom: true)
                catalog.append(custom)
                exerciseId = custom.id
            }
            let planned = (0..<max(1, line.sets)).map { _ in
                PlannedSet(targetReps: max(1, line.reps), targetWeightKg: line.weightKg)
            }
            exercises.append(RoutineExercise(exerciseId: exerciseId, plannedSets: planned))
        }
        return Routine(title: title, weekday: nil, exercises: exercises, progression: .off)
    }

    /// Varios bloques en una pizarra (EMOM + EVERY 2' + AMRAP…).
    public static func parseBlocks(ocrText: String, catalog: [Exercise]) -> [RoutineBlock] {
        let lines = ocrText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [RoutineBlock] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]

            // Etiqueta de sección (Weightlifting / Metcon…): título + formato de la línea siguiente.
            if let sectionTitle = sectionLabelTitle(line) {
                index += 1
                if index < lines.count, let header = detectFormatHeader(lines[index]) {
                    index += 1
                    let merged = mergeSection(sectionTitle, into: header)
                    let (block, consumed) = buildBlock(
                        header: merged,
                        lines: lines,
                        start: index,
                        catalog: catalog
                    )
                    blocks.append(block)
                    index = consumed
                } else {
                    // Sección sin cabecera de formato → fuerza o metcon genérico.
                    let upper = line.uppercased()
                    let format: WODFormat =
                        (upper.contains("METCON") || upper.contains("CONDITION")) ? .forTime : .strength
                    let header = HeaderInfo(raw: line, format: format, title: sectionTitle)
                    let (block, consumed) = buildBlock(
                        header: header,
                        lines: lines,
                        start: index,
                        catalog: catalog
                    )
                    blocks.append(block)
                    index = consumed
                }
                continue
            }

            guard let header = detectFormatHeader(line) else {
                index += 1
                continue
            }
            index += 1
            let (block, consumed) = buildBlock(
                header: header,
                lines: lines,
                start: index,
                catalog: catalog
            )
            blocks.append(block)
            index = consumed
        }

        // Sin cabeceras tipadas: un bloque con todas las líneas legibles (no descartar el OCR).
        if blocks.isEmpty {
            let body = lines.filter { !isNoise($0) && sectionLabelTitle($0) == nil }
            if !body.isEmpty {
                var block = RoutineBlock.wod(format: .chipper, title: "Desde pizarra")
                block.movements = flattenMovements(body, catalog: catalog)
                block.wodNotes = body.joined(separator: "\n")
                blocks.append(block)
            }
        }
        return blocks
    }

    private static func mergeSection(_ section: String?, into header: HeaderInfo) -> HeaderInfo {
        guard let section, !section.isEmpty else { return header }
        var h = header
        // Preferir el nombre de la sección ("Squat Clean Work") sobre el formato crudo.
        if section.count >= 3 {
            h.title = section
        }
        return h
    }

    private static func buildBlock(
        header: HeaderInfo,
        lines: [String],
        start: Int,
        catalog: [Exercise]
    ) -> (RoutineBlock, Int) {
        var index = start
        var movementLines: [String] = []
        var footnotes: [String] = []
        while index < lines.count {
            let body = lines[index]
            // Nueva sección o nuevo formato → fin de bloque.
            if sectionLabelTitle(body) != nil || detectFormatHeader(body) != nil {
                break
            }
            if isFootnote(body) {
                footnotes.append(body.trimmingCharacters(in: CharacterSet(charactersIn: "*• ")))
            } else if !isNoise(body) {
                movementLines.append(body)
            }
            index += 1
        }

        var block = RoutineBlock.wod(format: header.format, title: header.title)
        block.timeCapMinutes = header.timeCapMinutes
        block.rounds = header.rounds ?? block.rounds
        block.emomIntervalSeconds = header.intervalSeconds ?? block.emomIntervalSeconds
        block.restBetweenRoundsSeconds = header.restBetween
        block.movements = flattenMovements(movementLines, catalog: catalog)
        var notesParts = [header.raw] + movementLines
        if !footnotes.isEmpty {
            notesParts.append(contentsOf: footnotes)
        }
        block.wodNotes = notesParts.joined(separator: "\n")
        return (block, index)
    }

    private static func flattenMovements(_ lines: [String], catalog: [Exercise]) -> [WODMovement] {
        var roundPrefix: String?
        var out: [WODMovement] = []
        for line in lines {
            if let round = roundMarker(line) {
                roundPrefix = "Ronda \(round)"
                continue
            }
            var moves = parseWODMovementLine(line, catalog: catalog)
            if let roundPrefix {
                moves = moves.map { mov in
                    var m = mov
                    let note = [roundPrefix, m.notes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
                    m.notes = note.isEmpty ? nil : note
                    return m
                }
            }
            out.append(contentsOf: moves)
        }
        if out.filter({ !$0.isRest }).isEmpty, !lines.isEmpty {
            out = lines.compactMap { line -> WODMovement? in
                if roundMarker(line) != nil { return nil }
                return WODMovement(name: CrossFitGlossary.expand(line), reps: firstInt(in: line) ?? 10)
            }
        }
        return out
    }

    /// Un solo bloque (compatibilidad).
    public static func parseWODBlock(ocrText: String, catalog: [Exercise]) -> RoutineBlock? {
        parseBlocks(ocrText: ocrText, catalog: catalog).first
    }

    // MARK: - Headers

    private struct HeaderInfo {
        var raw: String
        var format: WODFormat
        var title: String
        var timeCapMinutes: Int?
        var rounds: Int?
        var intervalSeconds: Int?
        var restBetween: Int?
    }

    private static func isBlockHeader(_ line: String) -> Bool {
        detectFormatHeader(line) != nil || sectionLabelTitle(line) != nil
    }

    /// Solo el formato del WOD (EMOM, For Time…). No incluye etiquetas Weightlifting/Metcon.
    private static func detectHeader(_ line: String) -> HeaderInfo? {
        detectFormatHeader(line)
    }

    /// Título de sección tipo `Weightlifting "Squat Clean Work"` / `Metcon`.
    private static func sectionLabelTitle(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        let labels = [
            "WEIGHTLIFTING", "WEIGHT LIFTING", "HALTERO", "HALTEROFILIA",
            "METCON", "MET CON", "CONDITIONING", "CONDICIONAMIENTO",
            "GYMNASTICS", "GIMNASIA", "STRENGTH", "FUERZA", "SKILL", "TECH",
            "WOD", "WORKOUT",
        ]
        guard labels.contains(where: {
            upper == $0
                || upper.hasPrefix($0 + " ")
                || upper.hasPrefix($0 + ":")
                || upper.hasPrefix($0 + "\"")
                || upper.hasPrefix($0 + "“")
                || upper.hasPrefix($0 + "«")
        }) else { return nil }

        if let q = trimmed.range(of: #"[\"“«](.+?)[\"”»]"#, options: .regularExpression) {
            let raw = String(trimmed[q])
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”«»"))
            if !raw.isEmpty { return raw }
        }
        // "Weightlifting Squat Clean Work" sin comillas → quitar etiqueta.
        for label in labels.sorted(by: { $0.count > $1.count }) {
            if upper.hasPrefix(label) {
                let rest = trimmed.dropFirst(label.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ":-\""))
                return rest.isEmpty ? trimmed : String(rest)
            }
        }
        return trimmed
    }

    private static func roundMarker(_ line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let r = trimmed.range(
            of: #"^ROUNDS?\s*(\d+)\s*:?\s*$"#,
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }
        return firstInt(in: String(trimmed[r]))
    }

    private static func isFootnote(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.hasPrefix("*") || t.hasPrefix("•")
    }

    private static func detectFormatHeader(_ line: String) -> HeaderInfo? {
        let upper = line.uppercased()
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // EVERY 90S FOR 12MIN (8 SERIES)  /  CADA 90\" PARA 12'
        if let everyFor = trimmed.range(
            of: #"(?:EVERY|CADA)\s+(\d+)\s*(S|SEC|SECS|SECONDS|["″']|MIN|MINS|MINUTES|M)?\s*(?:FOR|PARA)\s+(\d+)\s*(MIN|MINS|MINUTES|["′'])?"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let token = String(trimmed[everyFor])
            let nums = token.split { !$0.isNumber }.compactMap { Int($0) }
            let first = nums.first ?? 90
            let durationMin = nums.count > 1 ? nums[1] : 12
            // Unidad del intervalo (justo tras el 1.er número), no la de la duración (…12min).
            let intervalSeconds: Int = {
                if token.range(
                    of: #"(?:EVERY|CADA)\s+\d+\s*(?:S(?:EC(?:OND)?S?)?\b|["″])"#,
                    options: [.regularExpression, .caseInsensitive]
                ) != nil {
                    return first
                }
                if token.range(
                    of: #"(?:EVERY|CADA)\s+\d+\s*(?:MIN(?:UTE)?S?\b|['′]|M\b)"#,
                    options: [.regularExpression, .caseInsensitive]
                ) != nil {
                    return first * 60
                }
                // Sin unidad: ≥30 → segundos (90); si no → minutos.
                return first >= 30 ? first : first * 60
            }()
            var rounds: Int? = durationMin * 60 / max(intervalSeconds, 1)
            if let series = trimmed.range(
                of: #"\((\d+)\s*(?:SERIES|SETS|SETS?|RONDS?|ROUNDS?)?\)"#,
                options: [.regularExpression, .caseInsensitive]
            ) {
                rounds = firstInt(in: String(trimmed[series])) ?? rounds
            }
            return HeaderInfo(
                raw: trimmed,
                format: .emom,
                title: "Every \(intervalSeconds)s · \(durationMin)'",
                timeCapMinutes: durationMin,
                rounds: rounds,
                intervalSeconds: intervalSeconds
            )
        }

        // EVERY 2' X 4  /  CADA 2' x 4
        if let every = trimmed.range(
            of: #"(?:EVERY|CADA)\s+(\d+)\s*['′]?\s*[x×X]\s*(\d+)"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let token = String(trimmed[every])
            let nums = token.split { !$0.isNumber }.compactMap { Int($0) }
            let minutes = nums.first ?? 2
            let rounds = nums.count > 1 ? nums[1] : 4
            return HeaderInfo(
                raw: trimmed,
                format: .emom,
                title: "Every \(minutes)' × \(rounds)",
                timeCapMinutes: minutes * rounds,
                rounds: rounds,
                intervalSeconds: minutes * 60
            )
        }

        // E2MOM / E3MOM …
        if let eMom = trimmed.range(
            of: #"E\s*(\d+)\s*MOM"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let mins = firstInt(in: String(trimmed[eMom])) ?? 2
            let total = firstInt(in: trimmed.replacingOccurrences(of: String(trimmed[eMom]), with: "")) ?? (mins * 5)
            return HeaderInfo(
                raw: trimmed,
                format: .emom,
                title: "E\(mins)MOM \(total)'",
                timeCapMinutes: total,
                intervalSeconds: mins * 60
            )
        }

        if upper.contains("ON THE MINUTE") || upper.contains("OTM") {
            let mins = firstInt(in: trimmed) ?? 10
            return HeaderInfo(
                raw: trimmed,
                format: .emom,
                title: "OTM \(mins)'",
                timeCapMinutes: mins,
                intervalSeconds: 60
            )
        }

        if upper.contains("AMRAP") || upper.contains("AS MANY ROUNDS") || upper.contains("AS MANY REPS") {
            return HeaderInfo(
                raw: trimmed,
                format: .amrap,
                title: "AMRAP \(firstInt(in: trimmed) ?? 12)'",
                timeCapMinutes: firstInt(in: trimmed) ?? 12
            )
        }
        if upper.contains("EMOM") {
            let mins = firstInt(in: trimmed) ?? 10
            return HeaderInfo(
                raw: trimmed,
                format: .emom,
                title: "EMOM \(mins)'",
                timeCapMinutes: mins,
                intervalSeconds: 60
            )
        }

        // 21-15-9 como cabecera SOLO si la línea es el esquema (no "4-4-3-3 PUSH PRESS…").
        if trimmed.range(
            of: #"^\s*\d+(?:\s*[-–]\s*\d+){2,}\s*(?:FOR\s+TIME|WOD)?\s*$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
            || upper == "21-15-9" || upper == "21 15 9" {
            return HeaderInfo(raw: trimmed, format: .ladder, title: trimmed)
        }
        if upper.contains("LADDER") || upper.contains("ESCALERA") || upper.contains("PYRAMID") || upper.contains("PIRÁMIDE") || upper.contains("PIRAMIDE") {
            return HeaderInfo(raw: trimmed, format: .ladder, title: trimmed)
        }

        if upper.contains("BUY") && (upper.contains("IN") || upper.contains("-IN") || upper.contains("IN:"))
            || upper.contains("BUY-IN") || upper.contains("CASH OUT") || upper.contains("CASH-OUT") || upper.contains("CASHOUT") {
            return HeaderInfo(raw: trimmed, format: .buyInCashOut, title: trimmed)
        }

        if upper.contains("PARTNER") || upper.contains("YOU GO I GO") || upper.contains("YGIG") || upper.contains("YDIG") {
            return HeaderInfo(raw: trimmed, format: .partner, title: "Partner")
        }

        if upper.contains("FOR QUALITY") || upper.contains("RFQ") || upper.contains("ROUNDS FOR QUALITY") {
            return HeaderInfo(
                raw: trimmed,
                format: .roundsForQuality,
                title: trimmed,
                rounds: firstInt(in: trimmed)
            )
        }

        if upper.contains("CIRCUIT") || upper.contains("STATIONS") || upper.contains("ESTACIONES")
            || upper.contains("ROTATION") && upper.contains("STATION") {
            return HeaderInfo(raw: trimmed, format: .circuit, title: trimmed, rounds: firstInt(in: trimmed))
        }

        // Solo cabeceras claras de max effort (no líneas de movimiento tipo "MAX CAL ROW").
        if upper.hasPrefix("FIND A HEAVY") || upper.hasPrefix("MAX LOAD") || upper.hasPrefix("MAX REPS")
            || upper.hasPrefix("HEAVY SINGLE") || upper == "1RM" || upper.hasPrefix("1RM ")
            || (upper.hasPrefix("MAX ") && trimmed.split(whereSeparator: { $0.isWhitespace }).count <= 4) {
            return HeaderInfo(raw: trimmed, format: .maxEffort, title: trimmed, timeCapMinutes: firstInt(in: trimmed))
        }

        // AFAP como cabecera, no como sufijo de un movimiento ("300M RUN AFAP").
        if upper == "AFAP" || upper.hasPrefix("AFAP ") || upper.hasPrefix("AS FAST AS POSSIBLE") {
            return HeaderInfo(raw: trimmed, format: .afap, title: "AFAP", timeCapMinutes: firstInt(in: trimmed))
        }

        if upper.contains("RFT") || upper.contains("FOR TIME") || upper.contains("FOR COMPLETION") {
            var timeCap = 12
            if let tc = trimmed.range(of: #"TC\s*(\d+)"#, options: [.regularExpression, .caseInsensitive]) {
                timeCap = firstInt(in: String(trimmed[tc])) ?? 12
            } else if let cap = trimmed.range(
                of: #"(\d+)\s*(?:MIN|MINS|MINUTES|')?\s*CAP"#,
                options: [.regularExpression, .caseInsensitive]
            ) {
                timeCap = firstInt(in: String(trimmed[cap])) ?? 12
            } else if let paren = trimmed.range(
                of: #"\(\s*(\d+)\s*(?:MIN|MINS|MINUTES|')?"#,
                options: [.regularExpression, .caseInsensitive]
            ) {
                timeCap = firstInt(in: String(trimmed[paren])) ?? 12
            }
            // "3 RFT" → rounds; "For Time: (20min Cap)" sin N delante → nil
            let rounds: Int? = {
                if upper.contains("RFT") { return firstInt(in: trimmed) }
                if trimmed.range(of: #"^\s*\d+\s+ROUNDS?\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                    return firstInt(in: trimmed)
                }
                return nil
            }()
            return HeaderInfo(
                raw: trimmed,
                format: .forTime,
                title: trimmed,
                timeCapMinutes: timeCap,
                rounds: rounds
            )
        }

        // "3 ROUNDS" / "5 ROUNDS OF" sin "quality"
        if trimmed.range(
            of: #"^\s*\d+\s+ROUNDS?\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil {
            return HeaderInfo(
                raw: trimmed,
                format: .forTime,
                title: trimmed,
                timeCapMinutes: 12,
                rounds: firstInt(in: trimmed)
            )
        }

        if upper.contains("TABATA") {
            return HeaderInfo(raw: trimmed, format: .tabata, title: "Tabata", rounds: 8)
        }
        if upper.contains("CHIPPER") {
            return HeaderInfo(raw: trimmed, format: .chipper, title: "Chipper")
        }
        if upper.contains("DEATH BY") || upper.contains("MUERTE POR") {
            return HeaderInfo(raw: trimmed, format: .deathBy, title: "Muerte por")
        }

        // Cabeceras de formato fuerza (no Weightlifting/Metcon: van como sectionLabelTitle).
        let strengthTokens = [
            "TECHNIQUE", "TÉCNICA", "TECNICA",
            "S&C", "SUPERSET", "GIANT SET", "WARM-UP",
            "WARM UP", "CALENTAMIENTO", "COOL DOWN", "COOLDOWN",
        ]
        if strengthTokens.contains(where: { upper == $0 || upper.hasPrefix($0 + " ") || upper.hasPrefix($0 + ":") }) {
            return HeaderInfo(raw: trimmed, format: .strength, title: trimmed)
        }

        return nil
    }

    // MARK: - Movements

    /// Una línea → uno o más movimientos (complejos con `+` se parten para emparejar el catálogo).
    private static func parseWODMovementLine(_ line: String, catalog: [Exercise]) -> [WODMovement] {
        var working = line
        var scale: String?
        var notes: [String] = []

        // Sets 1-2: 3 Squat Clean #70%  /  Sets 5-8: 1 Squat Clean #>80%
        if let setsRange = working.range(
            of: #"^SETS?\s+(\d+)\s*[-–]\s*(\d+)\s*:\s*"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let token = String(working[setsRange])
            let nums = token.split { !$0.isNumber }.compactMap { Int($0) }
            if nums.count >= 2 {
                notes.append("Series \(nums[0])-\(nums[1])")
            }
            working.removeSubrange(setsRange)
        }

        // % de 1RM: #70% / #>80% / @70%
        if let pct = working.range(
            of: #"[#@]\s*(>?)(\d+)\s*%"#,
            options: .regularExpression
        ) {
            let token = String(working[pct]).trimmingCharacters(in: CharacterSet(charactersIn: "#@ "))
            notes.append(token.hasPrefix(">") ? ">\(token.filter(\.isNumber))%" : "\(token.filter(\.isNumber))%")
            working.removeSubrange(pct)
        }

        // RPE / intensidad @6-8
        if let rpe = working.range(of: #"@\s*(\d+)\s*[-–]\s*(\d+)"#, options: .regularExpression) {
            notes.append("RPE \(String(working[rpe]).replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespaces))")
            working.removeSubrange(rpe)
        } else if let at = working.range(of: #"@\s*(\d+(?:[.,]\d+)?)"#, options: .regularExpression) {
            notes.append(String(working[at]).trimmingCharacters(in: .whitespaces))
            working.removeSubrange(at)
        }

        // Escala "50 DU / 100 SU" (con espacios alrededor de /)
        let hasScaleAlternative = working.range(of: #"\s+/\s+"#, options: .regularExpression) != nil
            && working.range(of: #"#?\s*(\d+(?:[.,]\d+)?)\s*/\s*(\d+(?:[.,]\d+)?)\s*(?:kg|lb)?\s*$"#, options: .regularExpression) == nil
        if hasScaleAlternative {
            let parts = working.components(separatedBy: "/")
            if parts.count >= 2 {
                working = parts[0].trimmingCharacters(in: .whitespaces)
                scale = CrossFitGlossary.expand(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }

        var male: Double?
        var female: Double?
        // #40/25kg o 40/25
        if let wr = working.range(
            of: #"#?\s*(\d+(?:[.,]\d+)?)\s*/\s*(\d+(?:[.,]\d+)?)\s*(?:kg|lb)?"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let token = String(working[wr])
            let nums = token.split(separator: "/").compactMap {
                Double(
                    $0.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "#", with: "")
                        .replacingOccurrences(of: "kg", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: "lb", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: ",", with: ".")
                )
            }
            if nums.count == 2 {
                male = nums[0]
                female = nums[1]
            }
            working.removeSubrange(wr)
        }

        // Esquema de series "4-4-3-3 PUSH PRESS" (no confundir con cabecera ladder 21-15-9).
        var repScheme: [Int]?
        if let wave = working.range(
            of: #"^(\d+(?:\s*[-–]\s*\d+){1,})\s+"#,
            options: .regularExpression
        ) {
            let token = String(working[wave])
            let nums = token.split { !$0.isNumber }.compactMap { Int($0) }
            if nums.count >= 2 {
                repScheme = nums
                working.removeSubrange(wave)
            }
        }

        // Complejo "3X 1 PUSH PRESS + 1 OHSQ" → multiplicador de series del complejo
        var complexMultiplier: Int?
        if repScheme == nil, let cx = working.range(of: #"^(\d+)\s*[x×X]\s*"#, options: .regularExpression) {
            complexMultiplier = firstInt(in: String(working[cx]))
            working.removeSubrange(cx)
        }

        let u = working.uppercased()
        if u.contains("REST") || u.contains("DESCANSO") {
            let sec = (firstInt(in: line) ?? 1) * (u.contains("'") || u.contains("MIN") ? 60 : 1)
            return [WODMovement(name: "REST", isRest: true, restSeconds: sec)]
        }

        working = working.trimmingCharacters(in: .whitespacesAndNewlines)
        working = working.replacingOccurrences(of: #"\s*\+\s*"#, with: " + ", options: .regularExpression)

        // Partir complejos en movimientos tipados (mejor matching OHSQ / Push press BN…).
        let parts = working.components(separatedBy: " + ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let segments = parts.isEmpty ? [working] : parts

        var sharedNotes = notes
        if let complexMultiplier, segments.count > 1 {
            sharedNotes.append("Complejo ×\(complexMultiplier)")
        }
        if let repScheme, repScheme.count >= 2 {
            sharedNotes.append("Series \(repScheme.map(String.init).joined(separator: "-"))")
        }

        return segments.enumerated().map { idx, segment in
            var seg = segment
            var reps: Int?
            var meters: Int?
            var calories: Int?
            if let mr = seg.range(of: #"(\d+)\s*M\b"#, options: [.regularExpression, .caseInsensitive]) {
                meters = firstInt(in: String(seg[mr]))
                seg.removeSubrange(mr)
            }
            if let cr = seg.range(of: #"(\d+)\s*CAL\b"#, options: [.regularExpression, .caseInsensitive]) {
                calories = firstInt(in: String(seg[cr]))
                seg.removeSubrange(cr)
            }
            if repScheme == nil, let leading = seg.range(of: #"^\s*(\d+)\b"#, options: .regularExpression) {
                reps = Int(seg[leading].trimmingCharacters(in: .whitespaces))
                seg.removeSubrange(leading)
            }
            // Si no hay reps en el segmento y es un complejo con multiplicador, el ×N cuenta como series del bloque.
            if reps == nil, segments.count == 1, let complexMultiplier {
                reps = complexMultiplier
            }
            if reps == nil, let scheme = repScheme {
                reps = scheme.first
            }

            seg = seg.trimmingCharacters(in: .whitespacesAndNewlines)
            let expanded = CrossFitGlossary.expand(seg)
            let match = bestMatch(for: expanded, in: catalog)
                ?? bestMatch(for: seg, in: catalog)

            var movNotes = sharedNotes
            if segments.count > 1 {
                movNotes.insert("Parte \(idx + 1)/\(segments.count)", at: 0)
            }

            return WODMovement(
                exerciseId: match?.id,
                name: match?.name ?? expanded,
                reps: meters == nil && calories == nil ? reps : nil,
                repScheme: idx == 0 ? repScheme : nil,
                distanceMeters: meters,
                calories: calories,
                weightMaleKg: idx == 0 ? male : nil,
                weightFemaleKg: idx == 0 ? female : nil,
                scaleAlternative: idx == segments.count - 1 ? scale : nil,
                notes: movNotes.isEmpty ? nil : movNotes.joined(separator: " · ")
            )
        }
    }

    private static func firstInt(in text: String) -> Int? {
        guard let r = text.range(of: #"(\d+)"#, options: .regularExpression) else { return nil }
        return Int(text[r].filter(\.isNumber))
    }

    // MARK: - Fuerza clásica

    private struct Parsed {
        var name: String
        var sets: Int
        var reps: Int
        var weightKg: Double?
    }

    private static func parseLine(_ line: String) -> Parsed {
        var working = CrossFitGlossary.expand(line)
        var sets = 3
        var reps = 8
        var weight: Double?

        if let at = working.range(of: #"@\s*(\d+(?:[.,]\d+)?)\s*(kg|lb)?"#, options: .regularExpression) {
            let token = String(working[at])
            if let num = Double(token.replacingOccurrences(of: "@", with: "")
                .replacingOccurrences(of: "kg", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "lb", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: ",", with: ".")) {
                weight = num
            }
            working.removeSubrange(at)
        }

        if let xr = working.range(of: #"(\d+)\s*[x×X]\s*(\d+)"#, options: .regularExpression) {
            let token = String(working[xr])
            let parts = token.lowercased()
                .replacingOccurrences(of: "×", with: "x")
                .components(separatedBy: CharacterSet(charactersIn: "xX"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let s = Int(parts[0]), let r = Int(parts[1]) {
                sets = s
                reps = r
            }
            working.removeSubrange(xr)
        }

        working = working.replacingOccurrences(of: #"^[\d]+[.)\-:]?\s*"#, with: "", options: .regularExpression)
        working = working.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-•*|"))

        return Parsed(name: working.isEmpty ? line : working, sets: sets, reps: reps, weightKg: weight)
    }

    private static func isNoise(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.count < 2 { return true }
        let skip = ["sets", "reps", "warmup", "calentamiento", "circuito", "circuit"]
        if skip.contains(where: { lower == $0 }) { return true }
        if line.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) { return true }
        // Reloj en esquina de captura (22:02).
        if line.range(of: #"^\d{1,2}:\d{2}$"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func bestMatch(for name: String, in catalog: [Exercise]) -> Exercise? {
        let cleaned = stripMovementModifiers(name)
        let candidates = [
            CrossFitGlossary.normalize(CrossFitGlossary.canonicalName(for: cleaned)),
            CrossFitGlossary.normalize(CrossFitGlossary.expand(cleaned)),
            CrossFitGlossary.normalize(cleaned),
            CrossFitGlossary.normalize(CrossFitGlossary.canonicalName(for: name)),
        ].filter { !$0.isEmpty }

        for needle in candidates {
            if let exact = catalog.first(where: { CrossFitGlossary.normalize($0.name) == needle }) {
                return exact
            }
        }

        var best: (Exercise, Int)?
        for needle in candidates {
            for ex in catalog {
                let hay = CrossFitGlossary.normalize(ex.name)
                var score: Int?
                if hay == needle {
                    score = 0
                } else if hay.contains(needle) || needle.contains(hay) {
                    score = abs(hay.count - needle.count) + 1
                } else {
                    let tokens = needle.split(separator: " ").filter { $0.count >= 3 }
                    let hits = tokens.filter { hay.contains($0) }.count
                    if hits >= 2 || (tokens.count == 1 && hits == 1) {
                        score = 50 - hits * 10
                    }
                }
                if let score, best == nil || score < best!.1 {
                    best = (ex, score)
                }
            }
        }
        return best?.0
    }

    /// Quita sufijos de estilo WOD que no forman parte del nombre del ejercicio.
    private static func stripMovementModifiers(_ raw: String) -> String {
        var s = raw
        let junk = [
            #"\bt\s*&\s*g\b"#,
            #"\btouch\s+and\s+go\b"#,
            #"\bafap\b"#,
            #"\bbn\b"#,
            #"\bbtn\b"#,
            #"\bbehind\s+neck\b"#,
            #"\bunbroken\b"#,
            #"\buat\b"#,
        ]
        for pattern in junk {
            s = s.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        return s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Diccionario de nomenclatura / diminutivos habituales en pizarras CrossFit.
public enum CrossFitGlossary {
    /// Abreviatura (normalizada) → nombre canónico en catálogo o texto expandido.
    public static let aliases: [String: String] = [
        // Comba
        "du": "Dobles de comba",
        "dus": "Dobles de comba",
        "double under": "Dobles de comba",
        "double unders": "Dobles de comba",
        "su": "Simples de comba",
        "sus": "Simples de comba",
        "single under": "Simples de comba",
        "single unders": "Simples de comba",
        "tu": "Triples de comba",
        "triple unders": "Triples de comba",

        // Cargadas / arrancadas
        "hsc": "Cargada colgante completa",
        "hang squat clean": "Cargada colgante completa",
        "high hang squat clean": "Cargada colgante completa",
        "hhsc": "Cargada colgante completa",
        "power clean": "Cargada de potencia",
        "pc": "Cargada de potencia",
        "hang clean": "Cargada colgante",
        "hc": "Cargada colgante",
        "clean": "Cargada",
        "squat clean": "Cargada",
        "power snatch": "Arrancada de potencia",
        "ps": "Arrancada de potencia",
        "hang snatch": "Arrancada colgante",
        "snatch": "Arrancada",
        "c&j": "Cargada y envión",
        "cj": "Cargada y envión",
        "clean and jerk": "Cargada y envión",

        // Press / overhead
        "pp": "Push press",
        "push press": "Push press",
        "push press bn": "Press detrás de nuca",
        "pp bn": "Press detrás de nuca",
        "bn": "detrás de nuca",
        "btn": "detrás de nuca",
        "behind neck": "detrás de nuca",
        "ohsq": "Overhead squat",
        "ohs": "Overhead squat",
        "overhead squat": "Overhead squat",
        "strict press": "Strict press",
        "sp": "Strict press",
        "push jerk": "Push jerk",
        "push jek": "Push jerk",
        "push jer": "Push jerk",
        "pj": "Push jerk",
        "split jerk": "Split jerk",
        "burpee over the bar": "Bar facing burpee",
        "burpees over the bar": "Bar facing burpee",
        "burpee over bar": "Bar facing burpee",
        "bob": "Bar facing burpee",

        // Condicionamiento
        "wb": "Wall ball",
        "wall ball": "Wall ball",
        "wallballs": "Wall ball",
        "wall ball shot": "Wall ball",
        "bjo": "Box jump over",
        "box jump": "Salto al cajón",
        "bj": "Salto al cajón",
        "burpee": "Burpee",
        "bfb": "Bar facing burpee",
        "ttb": "Toes to bar",
        "t2b": "Toes to bar",
        "kte": "Knees to elbows",
        "k2e": "Knees to elbows",
        "ctb": "Chest to bar",
        "c2b": "Chest to bar",
        "hspu": "HSPU",
        "hsw": "Handstand walk",
        "mu": "Muscle-up barra",
        "bmú": "Muscle-up barra",
        "rmu": "Muscle-up anillas",
        "pull up": "Dominadas",
        "pull ups": "Dominadas",
        "pull-up": "Dominadas",
        "pull-ups": "Dominadas",
        "pullups": "Dominadas",
        "pu": "Dominadas",
        "chin up": "Dominadas supinas",
        "thruster": "Thruster",
        "thrusters": "Thruster",
        "kb swing": "Swing kettlebell",
        "american swing": "Swing americano",
        "american kb swing": "Swing americano",
        "american kettlebell swing": "Swing americano",
        "kb american swing": "Swing americano",
        "deadlift": "Peso muerto",
        "deadlifts": "Peso muerto",
        "deadlift t&g": "Peso muerto",
        "deadlift t and g": "Peso muerto",
        "deadlift touch and go": "Peso muerto",
        "dl": "Peso muerto",
        "dl t&g": "Peso muerto",
        "t&g": "",
        "touch and go": "",
        "push presses": "Push press",
        "cal": "Air bike",
        "cals": "Air bike",
        "calorie": "Air bike",
        "calories": "Air bike",
        "cal row": "Air bike",
        "cal ski": "SkiErg",
        "row": "Air bike",
        "ski": "SkiErg",
        "tgu": "Turkish get-up",
        "ghd": "GHD sit-up",
        "afap": "lo más rápido posible",
        "run": "Cinta / carrera",

        // Formatos (para reconocer cabeceras, no ejercicios)
        "amrap": "AMRAP",
        "emom": "EMOM",
        "rft": "RFT",
        "for time": "For Time",
        "tabata": "Tabata",
        "chipper": "Chipper",
    ]

    /// Expande abreviaturas sueltas y compuestos conocidos en una línea de movimiento.
    public static func expand(_ raw: String) -> String {
        var s = raw
        // Sustituir primero frases largas
        let ordered = aliases.keys.sorted { $0.count > $1.count }
        for key in ordered {
            guard let value = aliases[key] else { continue }
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: key) + #"\b"#
            s = s.replacingOccurrences(of: pattern, with: value, options: [.regularExpression, .caseInsensitive])
        }
        return s
    }

    /// Nombre canónico para matching de catálogo.
    public static func canonicalName(for raw: String) -> String {
        let n = normalize(raw)
        if let exact = aliases[n] { return exact }
        return expand(raw)
    }

    public static func normalize(_ s: String) -> String {
        s.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: #"[:\-_/]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
