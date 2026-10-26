import ReperaDomain
import SwiftUI

/// Read-only projection of the same block tree stored in Supabase and authored on web.
/// Athlete's private workout state is intentionally never mutated here.
struct BusinessProfessionalSessionCard: View {
    let session: BusinessProfessionalTrainingSession
    let centerName: String
    var compact: Bool = false

    private var blocks: [BusinessPrescriptionBlock] {
        session.prescription?.schemaVersion == 1 ? session.prescription?.blocks ?? [] : []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OG.label)
                    .frame(width: 46, height: 46)
                    .background(OG.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(OG.label)
                    Text(centerName)
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
                Spacer(minLength: 4)
                Text(session.scheduledDate)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(OG.label2)
            }
            if !session.instructions.isEmpty {
                Text(session.instructions)
                    .font(.subheadline)
                    .foregroundStyle(OG.label2)
            }
            ForEach(blocks) { block in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: block.kind == "wod" ? "timer" : "dumbbell.fill")
                            .foregroundStyle(OG.accent)
                        Text(block.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(OG.label)
                        Spacer(minLength: 4)
                        Text(blockLabel(block))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(OG.label2)
                    }
                    ForEach(compact ? Array(block.entries.prefix(3)) : block.entries) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: entry.source == "free" ? "square.and.pencil" : "checkmark.seal")
                                .font(.caption)
                                .foregroundStyle(OG.accent)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(OG.label)
                                if let text = entrySummary(entry), !text.isEmpty {
                                    Text(text)
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                            }
                        }
                    }
                    if compact && block.entries.count > 3 {
                        Text("+ \(block.entries.count - 3) movimientos · Ver todos en Diario")
                            .font(.caption)
                            .foregroundStyle(OG.label2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(OG.surface3.opacity(0.85)))
            }
            if blocks.isEmpty && session.instructions.isEmpty {
                Text("Sin bloques estructurados: el entrenador todavía no ha añadido movimientos.")
                    .font(.footnote)
                    .foregroundStyle(OG.label2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(OG.surface3.opacity(0.9), lineWidth: 1))
    }

    private func blockLabel(_ block: BusinessPrescriptionBlock) -> String {
        if block.kind == "strength" { return "FUERZA" }
        let format = block.wodFormat ?? "WOD"
        let rounds = block.rounds.map { " · \($0) rondas" } ?? ""
        return format.uppercased() + rounds
    }

    private func entrySummary(_ entry: BusinessPrescriptionEntry) -> String? {
        if let sets = entry.plannedSets, !sets.isEmpty {
            return sets.map { set in
                var value = "\(set.targetReps) rep"
                if let weight = set.targetWeightKg { value += " · \(ReperaNumberFormat.decimal(weight)) kg" }
                if let rir = set.targetRir { value += " · RIR \(ReperaNumberFormat.decimal(rir))" }
                return value
            }.joined(separator: " / ")
        }
        var parts: [String] = []
        if let reps = entry.reps { parts.append("\(reps) rep") }
        if let notes = entry.notes, !notes.isEmpty { parts.append(notes) }
        if entry.source == "free" { parts.append("Ejercicio libre") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
