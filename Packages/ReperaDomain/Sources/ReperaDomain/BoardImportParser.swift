import Foundation

/// Línea detectada en una pizarra / TV (OCR).
public struct BoardImportLine: Identifiable, Sendable, Equatable, Hashable {
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
            guard !isNoise(line), !isBlockHeader(line),
                  !BoardScanLiteParser.isQualityAnnotation(line) else { return nil }
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
        // Bloque único "Añadir entreno" / legado "Desde pizarra" = salvamento sin cabeceras.
        let salvageTitles: Set<String> = ["Añadir entreno", "Desde pizarra"]
        let onlyHeaderlessSalvage = blocks.count == 1 && salvageTitles.contains(blocks[0].title)
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
        var orphanLines: [String] = []
        var index = 0

        func flushOrphans() {
            guard !orphanLines.isEmpty else { return }
            if let strength = strengthBlockFromLines(orphanLines, catalog: catalog) {
                blocks.append(strength)
            }
            orphanLines = []
        }

        while index < lines.count {
            let line = lines[index]

            // Etiqueta de sección (Weightlifting / Metcon…): título + formato de la línea siguiente.
            if let sectionTitle = sectionLabelTitle(line) {
                flushOrphans()
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

            if let header = detectFormatHeader(line) {
                flushOrphans()
                index += 1
                let (block, consumed) = buildBlock(
                    header: header,
                    lines: lines,
                    start: index,
                    catalog: catalog
                )
                blocks.append(block)
                index = consumed
                continue
            }

            // Ejercicios independientes (sin cabecera) → bloque de fuerza.
            if !isNoise(line), !BoardScanLiteParser.isQualityAnnotation(line) {
                orphanLines.append(line)
            }
            index += 1
        }
        flushOrphans()

        return blocks
    }

    /// Líneas sueltas / sin cabecera WOD → bloque de fuerza (series×reps) o strength tipado.
    private static func strengthBlockFromLines(_ lines: [String], catalog: [Exercise]) -> RoutineBlock? {
        let body = lines.filter {
            !isNoise($0) && sectionLabelTitle($0) == nil
                && !BoardScanLiteParser.isQualityAnnotation($0)
        }
        guard !body.isEmpty else { return nil }

        var exercises: [RoutineExercise] = []
        var allMatched = true
        for line in body {
            let parsed = parseLine(line)
            guard let match = bestMatch(for: parsed.name, in: catalog) else {
                allMatched = false
                break
            }
            let planned = (0..<max(1, parsed.sets)).map { _ in
                PlannedSet(targetReps: max(1, parsed.reps), targetWeightKg: parsed.weightKg)
            }
            exercises.append(RoutineExercise(exerciseId: match.id, plannedSets: planned))
        }

        if allMatched, !exercises.isEmpty {
            return RoutineBlock.strength(title: "Añadir entreno", exercises: exercises)
        }

        var block = RoutineBlock.wod(format: .strength, title: "Añadir entreno")
        block.movements = flattenMovements(body, catalog: catalog)
        block.wodNotes = body.joined(separator: "\n")
        return block
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
            // Metadatos @FOR QUALITY pueden parecer una cabecera RFQ cuando
            // Vision los separa del EMOM. Deben pertenecer al bloque actual.
            if BoardScanLiteParser.isQualityAnnotation(body) {
                footnotes.append("FOR QUALITY")
                index += 1
                continue
            }
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

        let movements = flattenMovements(movementLines, catalog: catalog)
        // «Every 2' × 4» con un solo ejercicio 4-3-3-2 es fuerza por series,
        // no un circuito EMOM. El esfuerzo RPE original se conserva en notas.
        if header.format == .emom,
           (header.raw.uppercased().hasPrefix("EVERY ") || header.raw.uppercased().hasPrefix("CADA ")),
           movements.count == 1, let movement = movements.first,
           !movement.isRest, let exerciseID = movement.exerciseId,
           let scheme = movement.repScheme, scheme.count == header.rounds {
            let notes = ([header.raw] + movementLines + footnotes).joined(separator: "\n")
            let rir = midpointRIR(from: movement.notes)
            let sets = scheme.map {
                PlannedSet(targetReps: $0, targetWeightKg: movement.weightMaleKg, targetRir: rir)
            }
            var strength = RoutineBlock.strength(
                title: header.title,
                exercises: [RoutineExercise(exerciseId: exerciseID, plannedSets: sets)]
            )
            strength.emomIntervalSeconds = header.intervalSeconds
            strength.timeCapMinutes = header.timeCapMinutes
            strength.wodNotes = notes
            return (strength, index)
        }

        var block = RoutineBlock.wod(format: header.format, title: header.title)
        block.timeCapMinutes = header.timeCapMinutes
        // For Time sin «N RFT»: TC 14' no son 14 rondas ni series.
        block.rounds = header.format == .forTime ? header.rounds : (header.rounds ?? block.rounds)
        block.emomIntervalSeconds = header.intervalSeconds ?? block.emomIntervalSeconds
        block.restBetweenRoundsSeconds = header.restBetween
        block.movements = movements
        block.deriveEmomRoundsIfNeeded()
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
        // Vision OCR y pizarras usan comillas tipográficas (’ / ′ / ‘).
        // Normalizarlas antes del análisis de cadencias y time caps.
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
        let upper = trimmed.uppercased()
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
                // RFT (TC 14') sin N delante sigue siendo una secuencia,
                // no 14 rondas. Solo "3 RFT" define 3 rondas.
                if trimmed.range(
                    of: #"^\s*\d+\s*(?:RFT|ROUNDS?)\b"#,
                    options: [.regularExpression, .caseInsensitive]
                ) != nil {
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
        var working = line.replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
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
                scale = parts.dropFirst()
                    .map { CrossFitGlossary.expand($0.trimmingCharacters(in: .whitespaces)) }
                    .joined(separator: " / ")
            }
        }

        // "20/16 CAL*" es Air Bike por sexos, no una carga de barra.
        if working.range(of: #"(?i)^\s*\d+\s*/\s*\d+\s*CALS?(?:ORIES)?\b"#,
                         options: .regularExpression) != nil {
            let parsed = CrossFitGlossary.parseMovementLine(working)
            let match = bestMatch(for: parsed.name, in: catalog)
            return [WODMovement(
                exerciseId: match?.id,
                name: match?.name ?? parsed.name,
                calories: parsed.calories,
                notes: parsed.equipmentNote
            )]
        }

        var male: Double?
        var female: Double?
        // #40/25kg o 40/25 — mayor = hombre, menor = mujer.
        if let pair = CrossFitGlossary.parseMaleFemaleWeights(in: working) {
            male = pair.male
            female = pair.female
            working = pair.remaining
        }

        // Ola "4-4-3-3 PUSH PRESS". Rango "5-10 HSPU" / "6-8 DB…" no es ola → lo deja parseMovementLine.
        var repScheme: [Int]?
        var rangeHint: String?
        if let wave = working.range(
            of: #"^(\d+(?:\s*[-–]\s*\d+){1,})\s+"#,
            options: .regularExpression
        ) {
            let token = String(working[wave])
            let nums = token.split { !$0.isNumber }.compactMap { Int($0) }
            if nums.count >= 2 {
                if WODMovement.isAscendingRepRange(nums) {
                    rangeHint = nums.map(String.init).joined(separator: "-")
                    // No quitar del working: parseMovementLine tipa reps + nota.
                } else {
                    repScheme = nums
                    working.removeSubrange(wave)
                }
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
            var parsed = CrossFitGlossary.parseMovementLine(segment)
            // Si la línea padre traía ola 4-3-3-2, aplícala al primer segmento.
            if idx == 0, let repScheme, parsed.repScheme == nil, !WODMovement.isAscendingRepRange(repScheme) {
                parsed.repScheme = repScheme
                parsed.reps = nil
            }
            if parsed.reps == nil, parsed.distanceMeters == nil, parsed.calories == nil,
               parsed.repScheme == nil, segments.count == 1, let complexMultiplier {
                parsed.reps = complexMultiplier
            }
            // Cargas del padre (45/30 al final de línea) si el segmento no las trae.
            if idx == 0 {
                if parsed.weightMaleKg == nil { parsed.weightMaleKg = male }
                if parsed.weightFemaleKg == nil { parsed.weightFemaleKg = female }
            }

            let match = bestMatch(for: parsed.name, in: catalog)

            var movNotes = sharedNotes
            if idx == 0, let rangeHint, parsed.equipmentNote?.contains(rangeHint) != true {
                movNotes.append(rangeHint)
            }
            if let eq = parsed.equipmentNote { movNotes.append(eq) }
            if segments.count > 1 {
                movNotes.insert("Parte \(idx + 1)/\(segments.count)", at: 0)
            }

            return WODMovement(
                exerciseId: match?.id,
                name: match?.name ?? parsed.name,
                reps: parsed.reps,
                repScheme: parsed.repScheme,
                distanceMeters: parsed.distanceMeters,
                calories: parsed.calories,
                weightMaleKg: parsed.weightMaleKg,
                weightFemaleKg: parsed.weightFemaleKg,
                scaleAlternative: idx == segments.count - 1 ? scale : nil,
                notes: movNotes.isEmpty ? nil : movNotes.joined(separator: " · ")
            )
        }
    }

    private static func midpointRIR(from notes: String?) -> Double? {
        guard let notes,
              let found = notes.range(of: #"RPE\s*(\d+(?:[.,]\d+)?)\s*[-–]\s*(\d+(?:[.,]\d+)?)"#,
                                      options: .regularExpression) else { return nil }
        let values = String(notes[found])
            .split { !$0.isNumber && $0 != "." && $0 != "," }
            .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        guard values.count == 2 else { return nil }
        return Effort.toRIR(value: (values[0] + values[1]) / 2, unit: .rpe)
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
        guard !catalog.isEmpty else { return nil }
        let cleaned = stripMovementModifiers(CrossFitGlossary.cleanMovementLabel(name))
        let candidates = [
            CrossFitGlossary.normalize(CrossFitGlossary.canonicalName(for: name)),
            CrossFitGlossary.normalize(CrossFitGlossary.canonicalName(for: cleaned)),
            CrossFitGlossary.normalize(CrossFitGlossary.expand(cleaned)),
            CrossFitGlossary.normalize(cleaned),
        ].filter { !$0.isEmpty }

        for needle in candidates {
            if let exact = catalog.first(where: { CrossFitGlossary.normalize($0.name) == needle }) {
                return exact
            }
        }

        var best: (Exercise, Int)?
        for needle in candidates {
            // `hay.contains("")` es true para todo en Swift — no usar needles vacíos.
            guard needle.count >= 2 else { continue }
            for ex in catalog {
                let hay = CrossFitGlossary.normalize(ex.name)
                guard hay.count >= 2 else { continue }
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

        // Movimientos habituales de pizarra con abreviaturas de posición.
        // R. = reverse: no confundir con walking lunges ni front rack lunges.
        "back squat": "Sentadilla",
        "high hsq snatch": "Arrancada colgante completa",
        "high hang squat snatch": "Arrancada colgante completa",
        "high hang sq snatch": "Arrancada colgante completa",
        "back rack r lunges": "Zancadas inversas con barra",
        "back rack r. lunges": "Zancadas inversas con barra",
        "back rack r. lunge": "Zancadas inversas con barra",
        "back rack r lunge": "Zancadas inversas con barra",
        "back rack reverse lunges": "Zancadas inversas con barra",
        "back rack reverse lunge": "Zancadas inversas con barra",
        "rear rack reverse lunges": "Zancadas inversas con barra",
        "barbell reverse lunges": "Zancadas inversas con barra",
        "power snatches": "Arrancada de potencia",

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
        "high hang snatch": "Arrancada colgante completa",
        "hsq snatch": "Arrancada colgante completa",
        "hang squat snatch": "Arrancada colgante completa",
        "back squats": "Sentadilla",
        "sentadilla trasera": "Sentadilla",
        "zancadas caminando": "Walking lunge",
        "lunges": "Zancadas",
        "lunge": "Zancadas",
        "reverse lunges back rack": "Zancadas inversas con barra",
        "power snatch": "Arrancada de potencia",
        "ps": "Arrancada de potencia",
        "hang snatch": "Arrancada colgante",
        "snatch": "Arrancada",
        "c&j": "Cargada y envión",
        "cj": "Cargada y envión",
        "clean and jerk": "Cargada y envión",

        // Acrónimos de CrossFit, nombre largo EN, español y variantes OCR.
        "gtoh": "Ground to overhead",
        "g2oh": "Ground to overhead",
        "g2o": "Ground to overhead",
        "g to oh": "Ground to overhead",
        "ground to overhead": "Ground to overhead",
        "ground-to-overhead": "Ground to overhead",
        "suelo a overhead": "Ground to overhead",
        "suelo sobre cabeza": "Ground to overhead",
        "bmu": "Muscle-up barra",
        "bar muscle up": "Muscle-up barra",
        "bar muscle-up": "Muscle-up barra",
        "bar muscle ups": "Muscle-up barra",
        "bar muscle-ups": "Muscle-up barra",
        "muscle up barra": "Muscle-up barra",
        "akbs": "Swing americano",
        "akb": "Swing americano",
        "american kettlebell swings": "Swing americano",
        "american kb swings": "Swing americano",
        "swing americano": "Swing americano",
        "wall balls": "Wall ball",
        "wallball": "Wall ball",
        "airbike": "Air bike",
        "assault bike": "Air bike",
        "assaultbike": "Air bike",
        "cal air bike": "Air bike",

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
        "bar facing burpee": "Bar facing burpee",
        "burpee over the bar": "Bar facing burpee",
        "burpees over the bar": "Bar facing burpee",
        "burpee over bar": "Bar facing burpee",
        "bob": "Bar facing burpee",
        "bobs": "Bar facing burpee",
        "b.o.b": "Bar facing burpee",
        "b.o.b.": "Bar facing burpee",
        // OCR a veces pega reps: "8bob" / "8BOB"
        "8bob": "Bar facing burpee",

        // Condicionamiento
        "wb": "Wall ball",
        "wall ball": "Wall ball",
        "wallballs": "Wall ball",
        "wall ball shot": "Wall ball",
        "bjo": "Box jump over",
        // BBJO añade un burpee antes de saltar el cajón: no es BJO.
        "bbjo": "Burpee box jump over",
        "bbjos": "Burpee box jump over",
        "burpee box jump over": "Burpee box jump over",
        "burpee box jump overs": "Burpee box jump over",
        "burpee box jump-over": "Burpee box jump over",
        "burpee box jump-overs": "Burpee box jump over",
        "burpee box jump": "Burpee box jump over",
        "burpee box jump over(s)": "Burpee box jump over",
        "kipping ring dip": "Fondos en anillas kipping",
        "kipping ring dips": "Fondos en anillas kipping",
        "ring dip": "Fondos en anillas",
        "ring dips": "Fondos en anillas",
        "strict ring dips": "Fondos en anillas",
        "box jump": "Salto al cajón",
        "bj": "Salto al cajón",
        "burpee": "Burpee",
        "bfb": "Bar facing burpee",
        "ttb": "Toes to bar",
        "t2b": "Toes to bar",
        "toes to bar": "Toes to bar",
        "toes-to-bar": "Toes to bar",
        "toes to bars": "Toes to bar",
        "kte": "Knees to elbows",
        "k2e": "Knees to elbows",
        "knees to elbows": "Knees to elbows",
        "ctb": "Chest to bar",
        "c2b": "Chest to bar",
        "chest to bar": "Chest to bar",
        "chest-to-bar": "Chest to bar",
        "devil press": "Devil press",
        "devil presses": "Devil press",
        "db devil press": "Devil press",
        "ddb devil press": "Devil press",
        "hspu": "HSPU",
        "kipping hspu": "HSPU",
        "kipping hspus": "HSPU",
        "strict hspu": "HSPU",
        "hsw": "Handstand walk",
        "dominadas": "Dominadas",
        "dominada": "Dominadas",
        "kipping pull up": "Dominadas kipping",
        "kipping pull-up": "Dominadas kipping",
        "kipping pull ups": "Dominadas kipping",
        "kipping dominadas": "Dominadas kipping",
        "hang snatch db": "Snatch mancuerna",
        "db hang snatch": "Snatch mancuerna",
        "db alt hang snatch": "Snatch mancuerna",
        "alt hang snatch db": "Snatch mancuerna",
        "alt hang snatch": "Arrancada colgante",
        "dumbbell hang snatch": "Snatch mancuerna",
        "db snatch": "Snatch mancuerna",
        "dumbbell snatch": "Snatch mancuerna",
        "snatch mancuerna": "Snatch mancuerna",
        "snatch db": "Snatch mancuerna",
        "db thruster": "Thruster mancuernas",
        "ddb thruster": "Thruster mancuernas",
        "dumbbell thruster": "Thruster mancuernas",
        "db clean": "Clean mancuerna",
        "ddb clean": "Clean mancuerna",
        "dumbbell clean": "Clean mancuerna",
        "db hang clean": "Clean mancuerna",
        "kb thruster": "Thruster kettlebell",
        "kettlebell thruster": "Thruster kettlebell",
        "kb snatch": "Snatch kettlebell",
        "kettlebell snatch": "Snatch kettlebell",
        "kb clean": "Clean kettlebell",
        "kettlebell clean": "Clean kettlebell",
        "db press": "Press mancuernas",
        "dumbbell press": "Press mancuernas",
        "db bench": "Press mancuernas",
        "db bench press": "Press mancuernas",
        "db row": "Remo mancuerna",
        "dumbbell row": "Remo mancuerna",
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
        "chin ups": "Dominadas supinas",
        "chin-up": "Dominadas supinas",
        "chin-ups": "Dominadas supinas",
        "chinup": "Dominadas supinas",
        "chinups": "Dominadas supinas",
        "strict pull up": "Dominadas estrictas",
        "strict pull-up": "Dominadas estrictas",
        "strict pull ups": "Dominadas estrictas",
        "butterfly pull up": "Dominadas butterfly",
        "butterfly pull-up": "Dominadas butterfly",
        "ring pull up": "Dominadas en anillas",
        "ring pull-up": "Dominadas en anillas",
        "ring pull ups": "Dominadas en anillas",
        // Variantes concretas (completar glosario; sin duplicar claves ya definidas arriba).
        "walking lunge": "Walking lunge",
        "walking lunges": "Walking lunge",
        "front rack lunge": "Front rack lunge",
        "front rack lunges": "Front rack lunge",
        "jumping lunge": "Jumping lunge",
        "jumping lunges": "Jumping lunge",
        "air squat": "Air squat",
        "goblet squat": "Goblet squat",
        "pistol squat": "Pistol squat",
        "pistol": "Pistol squat",
        "rdl": "Peso muerto rumano",
        "romanian deadlift": "Peso muerto rumano",
        "sumo deadlift": "Peso muerto sumo",
        "incline bench press": "Press banca inclinada",
        "decline bench press": "Press banca declinado",
        "deficit hspu": "HSPU deficit",
        "hspu deficit": "HSPU deficit",
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
        "runs": "Cinta / carrera",
        "running": "Cinta / carrera",
        "carrera": "Cinta / carrera",
        "cinta": "Cinta / carrera",
        "cinta carrera": "Cinta / carrera",
        "cinta / carrera": "Cinta / carrera",
        "cinta/carrera": "Cinta / carrera",
        "jog": "Cinta / carrera",
        "shuttle run": "Cinta / carrera",

        // Formatos (para reconocer cabeceras, no ejercicios)
        "amrap": "AMRAP",
        "emom": "EMOM",
        "rft": "RFT",
        "for time": "For Time",
        "tabata": "Tabata",
        "chipper": "Chipper",
    ]

    /// Equipo / modalidad en pizarra (no es el nombre del ejercicio).
    /// Fuentes: glosarios CrossFit habituales (DDB=double dumbbell, etc.).
    public static let equipmentAliases: [String: String] = [
        "ddb": "Doble mancuerna",
        "double db": "Doble mancuerna",
        "double dumbbell": "Doble mancuerna",
        "double dumbbells": "Doble mancuerna",
        "sdb": "Mancuerna",
        "single db": "Mancuerna",
        "single dumbbell": "Mancuerna",
        "db": "Mancuerna",
        "dumbbell": "Mancuerna",
        "dumbbells": "Mancuerna",
        "dkb": "Doble kettlebell",
        "double kb": "Doble kettlebell",
        "double kettlebell": "Doble kettlebell",
        "skb": "Kettlebell",
        "single kb": "Kettlebell",
        "single kettlebell": "Kettlebell",
        "kb": "Kettlebell",
        "kettlebell": "Kettlebell",
        "kettlebells": "Kettlebell",
        "bb": "Barra",
        "barbell": "Barra",
        "ab": "Air bike",
        "assault bike": "Air bike",
        "bike erg": "Air bike",
        "rower": "Remo",
        "ski erg": "SkiErg",
    ]

    /// Resultado tipado de una línea de movimiento de pizarra.
    public struct ParsedMovementLine: Sendable, Equatable {
        public var name: String
        public var reps: Int?
        public var repScheme: [Int]?
        public var distanceMeters: Int?
        public var calories: Int?
        public var weightMaleKg: Double?
        public var weightFemaleKg: Double?
        public var equipmentNote: String?
        public var isRest: Bool
        public var restSeconds: Int?

        public init(
            name: String,
            reps: Int? = nil,
            repScheme: [Int]? = nil,
            distanceMeters: Int? = nil,
            calories: Int? = nil,
            weightMaleKg: Double? = nil,
            weightFemaleKg: Double? = nil,
            equipmentNote: String? = nil,
            isRest: Bool = false,
            restSeconds: Int? = nil
        ) {
            self.name = name
            self.reps = reps
            self.repScheme = repScheme
            self.distanceMeters = distanceMeters
            self.calories = calories
            self.weightMaleKg = weightMaleKg
            self.weightFemaleKg = weightFemaleKg
            self.equipmentNote = equipmentNote
            self.isRest = isRest
            self.restSeconds = restSeconds
        }
    }

    /// Parsea «10 T2B», «200M RUN», «5 DDB DEVIL PRESS 20/12,5» → campos tipados.
    public static func parseMovementLine(_ raw: String) -> ParsedMovementLine {
        var working = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "′", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
        working = working.replacingOccurrences(of: #"(?i)^(ODD|EVEN)\s*:\s*"#, with: "", options: .regularExpression)

        let upper = working.uppercased()
        if upper.contains("REST") || upper.contains("DESCANSO") {
            let sec: Int
            if let m = firstIntToken(in: working),
               upper.contains("'") || upper.contains("MIN") {
                sec = m * 60
            } else {
                sec = firstIntToken(in: working) ?? 60
            }
            return ParsedMovementLine(name: "REST", isRest: true, restSeconds: sec)
        }

        var scheme: [Int]?
        var reps: Int?
        var meters: Int?
        var calories: Int?
        var male: Double?
        var female: Double?
        var equipment: String?
        var rangeNote: String?

        // Onda 4-3-3-2 / 21-15-9 al inicio. Rango 5-10 / 6-8 → techo de reps (no ola).
        if let wave = matchLeadingWave(working) {
            if WODMovement.isAscendingRepRange(wave.scheme) {
                rangeNote = wave.scheme.map(String.init).joined(separator: "-")
                reps = wave.scheme[1]
                working = wave.rest
            } else {
                scheme = wave.scheme
                working = wave.rest
            }
        }

        // Objetivo de cardio por sexo: 20/16 CAL* no es 20/16 kg.
        // La variante femenina se conserva explícitamente en notas.
        if let pair = working.range(
            of: #"(?i)^\s*(\d+)\s*/\s*(\d+)\s*CALS?(?:ORIES)?\b"#,
            options: .regularExpression
        ) {
            let nums = String(working[pair])
                .split { !$0.isNumber }
                .compactMap { Int($0) }
            if nums.count == 2 {
                return ParsedMovementLine(
                    name: "Air bike",
                    calories: nums[0],
                    equipmentNote: "Cal mujeres: \(nums[1])" + (working.contains("*") ? " · *" : "")
                )
            }
        }

        // Metros: 200M / 200 m / 200metros (antes que reps, para no confundir).
        if let mr = working.range(
            of: #"(\d+)\s*(?:m|metros?|meters?)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            meters = firstIntToken(in: String(working[mr]))
            working.removeSubrange(mr)
        }

        // Calorías: 10 CAL / 15 cals
        if let cr = working.range(
            of: #"(\d+)\s*cals?\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            calories = firstIntToken(in: String(working[cr]))
            working.removeSubrange(cr)
        }

        // Carga M/F al final: 20/12,5 o 45/30. Siempre mayor = hombre, menor = mujer.
        if let pair = parseMaleFemaleWeights(in: working) {
            male = pair.male
            female = pair.female
            working = pair.remaining
        }

        // Equipo DDB / DB / DKB… (antes de canonicalizar el nombre).
        let equipKeys = equipmentAliases.keys.sorted { $0.count > $1.count }
        for key in equipKeys {
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: key) + #"\b"#
            if working.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                equipment = equipmentAliases[key]
                working = working.replacingOccurrences(
                    of: pattern,
                    with: " ",
                    options: [.regularExpression, .caseInsensitive]
                )
                break
            }
        }

        // Reps al inicio: «10 toes to bar» o pegado OCR «8BOB» → reps=8, nombre sin el 8.
        if scheme == nil, meters == nil, calories == nil,
           let leading = working.range(
            of: #"^\s*(\d+)(?:\b|(?=[A-Za-zÁÉÍÓÚÑáéíóúñ]))"#,
            options: .regularExpression
           ) {
            reps = Int(working[leading].filter(\.isNumber))
            working.removeSubrange(leading)
        }

        working = cleanMovementLabel(working)
        let canonical = canonicalName(for: working.isEmpty ? raw : working)
        let name = preferEquipmentVariant(
            name: canonical.isEmpty ? working : canonical,
            equipment: equipment
        )
        // El OCR también aporta estilo/técnica; no dejar que ALT o T&G
        // se pierdan al limpiar el nombre para enlazar con el catálogo.
        var technique: [String] = []
        if raw.range(of: #"\bALT(?:ERNATING)?\b"#,
                     options: [.regularExpression, .caseInsensitive]) != nil {
            technique.append("Alternando")
        }
        if raw.range(of: #"\bT\s*&\s*G\b|\bTOUCH\s*(?:&|AND|-)?\s*GO\b"#,
                     options: [.regularExpression, .caseInsensitive]) != nil {
            technique.append("Touch & go")
        }
        let noteParts = ([rangeNote, equipment].compactMap { $0 } + technique)
            .filter { !$0.isEmpty }

        return ParsedMovementLine(
            name: name.isEmpty ? working : name,
            reps: (meters == nil && calories == nil && scheme == nil) ? reps : nil,
            repScheme: scheme,
            distanceMeters: meters,
            calories: calories,
            weightMaleKg: male,
            weightFemaleKg: female,
            equipmentNote: noteParts.isEmpty ? nil : noteParts.joined(separator: " · ")
        )
    }

    /// Nombre de catálogo/arte teniendo en cuenta notas de equipo (p. ej. DB → Snatch mancuerna).
    public static func resolveCatalogName(_ rawName: String, notes: String? = nil) -> String {
        preferEquipmentVariant(name: canonicalName(for: rawName), equipment: notes)
    }

    /// Redirige al ejercicio de catálogo según equipo (1/2 mancuernas, KB, barra…).
    /// La nota de equipo (`Mancuerna` vs `Doble mancuerna`) se conserva aparte en `notes`.
    public static func preferEquipmentVariant(name: String, equipment: String?) -> String {
        guard let equipment, !equipment.isEmpty else { return name }
        let eq = normalize(equipment)
        let kind = equipmentKind(from: eq)
        guard kind != .unknown else { return name }
        let n = normalize(name)

        switch kind {
        case .dumbbell, .doubleDumbbell:
            if n.contains("cargada y envion") || n.contains("clean and jerk") || n.contains("c&j") {
                return "Cargada y envión con mancuerna"
            }
            if isSnatchFamily(n) { return "Snatch mancuerna" }
            if isCleanFamily(n) { return "Clean mancuerna" }
            if n.contains("thruster") { return "Thruster mancuernas" }
            if n.contains("devil") { return "Devil press" }
            if n.contains("man maker") || n.contains("manmaker") { return "Man maker" }
            if n.contains("farmer") { return "Farmer carry" }
            // Solo press de banca; push/strict press no tienen variante DB en catálogo.
            if n.contains("press banca") || n == "bench press"
                || (n.contains("bench") && n.contains("press"))
                || n == "press mancuernas" {
                return "Press mancuernas"
            }
            if n.contains("remo") && !n.contains("erg") { return "Remo mancuerna" }
            if n.contains("dumbbell row") || (n.hasSuffix(" row") && !n.contains("rower")) {
                return "Remo mancuerna"
            }
            if n.contains("curl") { return "Curl mancuernas" }
            return name
        case .kettlebell, .doubleKettlebell:
            if isSnatchFamily(n) { return "Snatch kettlebell" }
            if isCleanFamily(n) { return "Clean kettlebell" }
            if n.contains("thruster") { return "Thruster kettlebell" }
            if n.contains("swing") { return n.contains("american") ? "Swing americano" : "Swing kettlebell" }
            if n.contains("goblet") || (n.contains("sentadilla") && n.contains("goblet")) {
                return "Goblet squat"
            }
            if n.contains("turkish") || n.contains("get up") || n.contains("get-up") {
                return "Turkish get-up"
            }
            return name
        case .barbell:
            // Si el nombre ya es variante DB/KB, vuelve a la versión de barra cuando el OCR marca BB.
            if n.contains("snatch mancuerna") || n.contains("snatch kettlebell") { return "Arrancada" }
            if n.contains("clean mancuerna") || n.contains("clean kettlebell") { return "Cargada" }
            if n.contains("thruster mancuern") || n.contains("thruster kettlebell") { return "Thruster" }
            if n.contains("press mancuern") { return "Press banca" }
            return name
        case .unknown:
            return name
        }
    }

    private enum EquipmentKind {
        case dumbbell
        case doubleDumbbell
        case kettlebell
        case doubleKettlebell
        case barbell
        case unknown
    }

    private static func equipmentKind(from eq: String) -> EquipmentKind {
        if eq.contains("doble mancuerna") || eq.contains("double dumbbell") || eq == "ddb" {
            return .doubleDumbbell
        }
        if eq.contains("mancuerna") || eq.contains("dumbbell") || eq == "db" || eq.contains("sdb") {
            return .dumbbell
        }
        if eq.contains("doble kettlebell") || eq.contains("double kettlebell") || eq == "dkb" {
            return .doubleKettlebell
        }
        if eq.contains("kettlebell") || eq == "kb" || eq.contains("skb") {
            return .kettlebell
        }
        if eq.contains("barra") || eq.contains("barbell") || eq == "bb" {
            return .barbell
        }
        return .unknown
    }

    private static func isSnatchFamily(_ n: String) -> Bool {
        n.contains("arrancada") || n.contains("hang snatch") || n == "snatch"
            || n.hasSuffix(" snatch") || n.contains("snatch mancuerna") || n.contains("snatch kettlebell")
    }

    private static func isCleanFamily(_ n: String) -> Bool {
        // No tocar C&J / clean and jerk.
        if n.contains("envion") || n.contains("jerk") || n.contains("c&j") || n.contains("clean and") {
            return false
        }
        return n.contains("cargada") || n.contains("hang clean") || n == "clean"
            || n.hasSuffix(" clean") || n.contains("clean mancuerna") || n.contains("clean kettlebell")
    }

    private static func matchLeadingWave(_ line: String) -> (scheme: [Int], rest: String)? {
        guard let range = line.range(
            of: #"^\s*(\d+(?:\s*[-–]\s*\d+){1,})\s+"#,
            options: .regularExpression
        ) else { return nil }
        let raw = String(line[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = raw.split(whereSeparator: { $0 == "-" || $0 == "–" || $0 == " " })
            .compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        let rest = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rest.isEmpty else { return nil }
        return (parts, rest)
    }

    private static func firstIntToken(in text: String) -> Int? {
        guard let r = text.range(of: #"(\d+)"#, options: .regularExpression) else { return nil }
        return Int(text[r].filter(\.isNumber))
    }

    /// Extrae `20/12,5` o `12,5/20` → (male: 20, female: 12.5). El mayor es siempre hombre.
    public static func parseMaleFemaleWeights(in text: String) -> (male: Double, female: Double, remaining: String)? {
        guard let wr = text.range(
            of: #"#?\s*(\d+(?:[.,]\d+)?)\s*/\s*(\d+(?:[.,]\d+)?)\s*(?:kg|lb)?"#,
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }
        let token = String(text[wr])
        let nums = token.split(separator: "/").compactMap { part -> Double? in
            let cleaned = part
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "kg", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "lb", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespaces)
            return Double(cleaned)
        }
        guard nums.count == 2 else { return nil }
        let hi = max(nums[0], nums[1])
        let lo = min(nums[0], nums[1])
        var remaining = text
        remaining.removeSubrange(wr)
        remaining = remaining.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (hi, lo, remaining)
    }

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
        // Antes de quitar ruido (DB/ALT…): compuestos con equipo (`db hang snatch` → Snatch mancuerna).
        let rawNorm = normalize(raw)
        if let exact = aliases[rawNorm] { return exact }
        // Misma tabla EN↔catálogo que la búsqueda de ejercicios (chin up, walking lunge…).
        if let fromSearch = ExerciseSearch.scannerCatalogName(forNormalizedQuery: rawNorm) {
            return fromSearch
        }
        let ordered = aliases.keys.sorted { $0.count > $1.count }
        for key in ordered {
            guard key.count >= 4, let value = aliases[key], !value.isEmpty else { continue }
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: key) + #"\b"#
            if rawNorm.range(of: pattern, options: .regularExpression) != nil {
                return value
            }
        }

        let cleaned = cleanMovementLabel(raw)
        let n = normalize(cleaned)
        if let exact = aliases[n] { return exact }
        if let fromSearch = ExerciseSearch.scannerCatalogName(forNormalizedQuery: n) {
            return fromSearch
        }
        // Alias como palabra completa (no "mu" ⊂ "muerto"). Ej. "kipping hspu" → HSPU.
        for key in ordered {
            guard key.count >= 2, let value = aliases[key], !value.isEmpty else { continue }
            if n == key { return value }
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: key) + #"\b"#
            if n.range(of: pattern, options: .regularExpression) != nil {
                return value
            }
        }
        let expanded = expand(cleaned)
        let en = normalize(expanded)
        if let exact = aliases[en] { return exact }
        return expanded.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Quita ruido de pizarra: @RIR, @FQ, ondas 4-3-3-2, W.S., DB ALT, etc.
    public static func cleanMovementLabel(_ raw: String) -> String {
        var s = raw
        // Notas tras @: @RIR 2-1, @FQ, @80%, @RX…
        s = s.replacingOccurrences(
            of: #"@\S+(?:\s+[\d./\-–]+)*"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        // Ondas / rangos al inicio: 4-3-3-2 / 6-8 / 21-15-9
        s = s.replacingOccurrences(
            of: #"^\s*\d+(?:\s*[-–]\s*\d+)+\s+"#,
            with: "",
            options: .regularExpression
        )
        // Reps sueltas al inicio: "10 Dominadas" o pegadas "8BOB"
        s = s.replacingOccurrences(
            of: #"^\s*\d+(?:\s+|(?=[A-Za-zÁÉÍÓÚÑáéíóúñ]))"#,
            with: "",
            options: .regularExpression
        )
        let noise = [
            #"\bw\.?\s*s\.?\b"#,
            #"\bws\b"#,
            #"\bddb\b"#,
            #"\bsdb\b"#,
            #"\bdkb\b"#,
            #"\bskb\b"#,
            #"\bdb\b"#,
            #"\bdumbbells?\b"#,
            #"\bmancuernas?\b"#,
            #"\bkb\b"#,
            #"\bkettlebells?\b"#,
            #"\bbb\b"#,
            #"\bbarbell\b"#,
            #"\balt\b"#,
            #"\balternat(?:e|ing|as?|os?)?\b"#,
            #"\bweighted\b"#,
            #"\bestrict[oa]?s?\b"#,
            #"\bstrikt\b"#,
        ]
        for pattern in noise {
            s = s.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        // Estilo kipping/butterfly delante de HSPU / pull-up: deja el movimiento.
        s = s.replacingOccurrences(
            of: #"\b(kipping|butterfly|strict)\s+(?=(hspu|pull|dominad|chin|muscle))"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-•*|:/"))
    }

    public static func normalize(_ s: String) -> String {
        s.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: #"[:\-_/]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
