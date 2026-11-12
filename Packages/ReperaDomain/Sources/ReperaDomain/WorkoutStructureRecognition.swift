import Foundation

/// Detect structural information from the actual OCR text after the established
/// Lite parser has decided block boundaries and catalog identities. Never
/// replaces the original movements, rounds or WOD format.
public enum WorkoutStructureRecognition {
    public static func attach(to block: inout RoutineBlock) {
        guard block.structure == nil else { return }
        let source = ([block.title] + (block.wodNotes ?? "").components(separatedBy: .newlines))
            .joined(separator: "\n")
        let upper = source.uppercased()
        let section: WorkoutSection? = {
            if upper.contains("WARM UP") || upper.contains("WARM-UP") || upper.contains("CALENTAMIENTO") { return .warmUp }
            if upper.contains("COOL DOWN") || upper.contains("COOLDOWN") { return .coolDown }
            if upper.contains("ACCESSORY") || upper.contains("ACCESORIO") { return .accessory }
            if upper.contains("WEIGHTLIFTING") || upper.contains("STRENGTH") || upper.contains("FUERZA") { return .strength }
            if upper.contains("SKILL") || upper.contains("GYMNASTICS") { return .skill }
            if upper.contains("METCON") { return .metcon }
            return nil
        }()
        let collaboration: WorkoutCollaboration? = {
            if upper.contains("I GO YOU GO") || upper.contains("YOU GO I GO") ||
               upper.contains("ALTERNANDO") || upper.contains("YGIG") { return .youGoIGo }
            if upper.contains("SYNCHRO") || upper.contains("SYNCRO") ||
               upper.contains("SYNCHRONIZED") { return .synchronized }
            if upper.contains("A REPARTIR") || upper.contains("TO DIV") ||
               upper.contains("SHARED REPS") { return .sharedReps }
            if upper.contains("JUNTOS") || upper.contains("TOGETHER") { return .together }
            return nil
        }()
        let resultMetric: WorkoutResultMetric? = {
            guard block.wodFormat == .maxEffort || upper.contains("FIND ") && upper.contains("RM") else { return nil }
            if upper.contains("MAX CAL") { return .calories }
            if upper.contains("MAX DISTANCE") || upper.contains("MAX METERS") { return .distanceMeters }
            if upper.contains("1RM") || upper.contains("5 RM") || upper.contains("MAX LOAD") ||
               upper.contains("MAX WEIGHT") || upper.contains("FIND A HEAVY") { return .loadKg }
            return .totalReps
        }()
        let ids = block.movements.filter { !$0.isRest }.map(\.id)
        var phases: [WorkoutPhase] = []
        let repeatedAMRAP = captures(
            #"(?i)(?:\b(\d+)\s*(?:MIN|MN)\s*AMRAP|\bAMRAP\s*(\d+)\s*(?:MIN|MN|['′]))\s*\(\s*[X×]\s*(\d+)\s*\)"#,
            source
        )
        if let value = repeatedAMRAP,
           value.count == 3, let duration = Int(value[0].isEmpty ? value[1] : value[0]),
           let count = Int(value[2]), (1...240).contains(duration), (2...100).contains(count) {
            let rest = captures(
                #"(?i)(\d+)\s*(MIN|MN|M\b|['′])\s*REST\s*(?:BETWEEN|ENTRE)"#, source
            ).flatMap { v -> Int? in
                guard v.count == 2, let amount = Int(v[0]) else { return nil }
                return amount * 60
            }
            let hasBuyIn = upper.contains("BUY IN") || upper.contains("BUY-IN")
            let hasCashOut = upper.contains("BUY OUT") || upper.contains("BUY-OUT") ||
                upper.contains("CASH OUT") || upper.contains("CASH-OUT")
            var children: [WorkoutPhase] = []
            if hasBuyIn, let first = ids.first {
                children.append(WorkoutPhase(kind: .buyIn, title: "Buy-in", movementIDs: [first]))
            }
            let middle = ids.dropFirst(hasBuyIn ? 1 : 0)
                .dropLast(hasCashOut && ids.count > 1 ? 1 : 0)
            if !middle.isEmpty {
                children.append(WorkoutPhase(kind: .main, title: "Trabajo principal",
                                             movementIDs: Array(middle)))
            }
            if hasCashOut, let last = ids.last {
                children.append(WorkoutPhase(kind: .cashOut, title: "Cash-out", movementIDs: [last]))
            }
            phases.append(WorkoutPhase(kind: .work, title: "AMRAP por intervalos",
                                       movementIDs: ids, repeatCount: count,
                                       workSeconds: duration * 60, restSeconds: rest,
                                       notes: block.wodNotes,
                                       children: hasBuyIn || hasCashOut ? children : []))
        } else {
            let hasBuyIn = upper.contains("BUY IN") || upper.contains("BUY-IN")
            let hasCashOut = upper.contains("BUY OUT") || upper.contains("BUY-OUT") ||
                upper.contains("CASH OUT") || upper.contains("CASH-OUT")
            if hasBuyIn, let first = ids.first {
                phases.append(WorkoutPhase(kind: .buyIn, title: "Buy-in", movementIDs: [first]))
            }
            if hasBuyIn || hasCashOut {
                let middle = ids.dropFirst(hasBuyIn ? 1 : 0)
                    .dropLast(hasCashOut && ids.count > 1 ? 1 : 0)
                if !middle.isEmpty {
                    phases.append(WorkoutPhase(kind: .main, title: "Trabajo principal",
                                               movementIDs: Array(middle)))
                }
                if hasCashOut, let last = ids.last {
                    phases.append(WorkoutPhase(kind: .cashOut, title: "Cash-out",
                                               movementIDs: [last]))
                }
            } else if block.wodFormat == .tabata {
                phases.append(WorkoutPhase(kind: .work, title: "Tabata",
                                           movementIDs: ids, repeatCount: block.rounds ?? 8,
                                           workSeconds: block.workSeconds ?? 20,
                                           restSeconds: block.restSeconds ?? 10))
            } else if upper.contains("SUPERSET") || upper.contains("TRISET") ||
                      upper.contains("GIANT SET") {
                phases.append(WorkoutPhase(kind: .main, title: "Serie combinada",
                                           movementIDs: ids, repeatCount: block.rounds,
                                           notes: block.wodNotes))
            } else if collaboration != nil {
                phases.append(WorkoutPhase(kind: .main, title: "Trabajo en equipo",
                                           movementIDs: ids, notes: block.wodNotes))
            }
        }
        if section != nil || collaboration != nil || resultMetric != nil || !phases.isEmpty {
            block.structure = WorkoutStructure(section: section, collaboration: collaboration,
                                               resultMetric: resultMetric, phases: phases)
        }

        // Preserve sub-minute caps when the board explicitly specifies them.
        // Plain "TC 14'" continues using the existing minute-level field.
        if block.timeCapSeconds == nil,
           let cap = captures(#"(?i)\b(?:TC|TIME CAP|CAP)\s*[:=]?\s*(\d{1,3}):([0-5]\d)\b"#, source),
           cap.count == 2, let minutes = Int(cap[0]), let seconds = Int(cap[1]),
           minutes > 0 || seconds > 0 {
            block.timeCapSeconds = minutes * 60 + seconds
        }
    }

    private static func captures(_ pattern: String, _ text: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let match = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        return (1..<match.numberOfRanges).map {
            guard let r = Range(match.range(at: $0), in: text) else { return "" }
            return String(text[r])
        }
    }
}
