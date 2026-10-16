import Foundation
import FoundationModels
import GymbroDomain

/// Interpretación de pizarra con Apple Intelligence (on-device).
/// Si el dispositivo no es compatible o falla → el caller usa el parser local (gratis).
enum BoardAIImporter {
    enum Availability: Sendable {
        case available
        case unavailable(reason: String)
    }

    static var availability: Availability {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable(reason: "deviceNotEligible")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(reason: "appleIntelligenceNotEnabled")
        case .unavailable(.modelNotReady):
            return .unavailable(reason: "modelNotReady")
        case .unavailable(let other):
            return .unavailable(reason: String(describing: other))
        }
    }

    static var isAvailable: Bool {
        if case .available = availability { return true }
        return false
    }

    /// Devuelve bloques tipados o `nil` si no hay modelo / falla (fallback al parser).
    static func interpret(ocrText: String) async -> [RoutineBlock]? {
        guard isAvailable else {
            BoardScanLog.info("BoardAI: no disponible (\(String(describing: availability)))")
            return nil
        }
        let trimmed = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return nil }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: """
                OCR de pizarra / TV de entreno:

                \(trimmed)
                """,
                generating: AIBoardPlan.self
            )
            let blocks = response.content.toRoutineBlocks()
            BoardScanLog.info("BoardAI: OK blocks=\(blocks.count)")
            return blocks.isEmpty ? nil : blocks
        } catch {
            BoardScanLog.error("BoardAI: \(error.localizedDescription)")
            return nil
        }
    }

    private static let instructions = """
        Eres un coach que convierte texto OCR de pizarras CrossFit / fuerza en JSON estructurado.
        Reglas:
        - Separa cada bloque (Weightlifting, Metcon, Strength, AMRAP, EMOM, For Time…).
        - format debe ser uno de: emom, amrap, forTime, strength, ladder, tabata, chipper, partner, circuit, afap, deathBy, maxEffort, buyInCashOut, roundsForQuality.
        - Every 90s For 12min → emom, intervalSeconds=90, timeCapMinutes=12, rounds si hay (8 Series).
        - For Time (20min Cap) → forTime, timeCapMinutes=20.
        - Conserva cargas M/F (40/25), %, series 1-2, metros, rondas distintas como movimientos en orden.
        - Notas tipo "NO Touch & Go" van en notes del bloque.
        - Corrige typos obvios (Push Jek → Push Jerk).
        - No inventes movimientos que no estén en el OCR.
        - Responde solo con la estructura pedida.
        """
}

// MARK: - Guided generation

@Generable
struct AIBoardPlan {
    @Guide(description: "Bloques del entreno en orden de la pizarra")
    var blocks: [AIBoardBlock]
}

@Generable
struct AIBoardBlock {
    @Guide(description: "Título corto del bloque")
    var title: String

    @Guide(description: "emom|amrap|forTime|strength|ladder|tabata|chipper|partner|circuit|afap|deathBy|maxEffort|buyInCashOut|roundsForQuality")
    var format: String

    var timeCapMinutes: Int?
    var rounds: Int?
    var intervalSeconds: Int?
    var notes: String?

    @Guide(description: "Movimientos en orden")
    var movements: [AIBoardMovement]
}

@Generable
struct AIBoardMovement {
    var name: String
    var reps: Int?
    var distanceMeters: Int?
    var calories: Int?
    var weightMaleKg: Double?
    var weightFemaleKg: Double?
    var isRest: Bool
    var restSeconds: Int?
    @Guide(description: "Notas: Ronda 1, 70%, Series 1-2…")
    var notes: String?
}

private extension AIBoardPlan {
    func toRoutineBlocks() -> [RoutineBlock] {
        blocks.map { $0.toRoutineBlock() }
    }
}

private extension AIBoardBlock {
    func toRoutineBlock() -> RoutineBlock {
        var block = RoutineBlock.wod(format: mapFormat(format), title: title.isEmpty ? format : title)
        block.timeCapMinutes = timeCapMinutes
        block.rounds = rounds
        block.emomIntervalSeconds = intervalSeconds
        block.wodNotes = notes
        block.movements = movements.map { $0.toMovement() }
        return block
    }

    func mapFormat(_ raw: String) -> WODFormat {
        switch raw.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "") {
        case "emom", "every", "e2mom", "e3mom": return .emom
        case "amrap": return .amrap
        case "fortime", "rft": return .forTime
        case "strength", "weightlifting", "skill", "tech": return .strength
        case "ladder", "21159": return .ladder
        case "tabata": return .tabata
        case "chipper": return .chipper
        case "partner", "ygig": return .partner
        case "circuit": return .circuit
        case "afap": return .afap
        case "deathby": return .deathBy
        case "maxeffort": return .maxEffort
        case "buyincashout", "buyin": return .buyInCashOut
        case "roundsforquality", "rfq": return .roundsForQuality
        default: return .chipper
        }
    }
}

private extension AIBoardMovement {
    func toMovement() -> WODMovement {
        WODMovement(
            name: CrossFitGlossary.canonicalName(for: name),
            reps: isRest ? nil : reps,
            distanceMeters: distanceMeters,
            calories: calories,
            weightMaleKg: weightMaleKg,
            weightFemaleKg: weightFemaleKg,
            isRest: isRest,
            restSeconds: restSeconds,
            notes: notes
        )
    }
}
