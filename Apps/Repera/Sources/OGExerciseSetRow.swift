import SwiftUI

/// Fila de serie como en el detalle de entreno: `S1 · 100×4 · RIR 4`.
struct OGExerciseSetRow: View {
    var index: Int
    var summaryLine: String
    var rir: Double? = nil
    var showsRIR: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            Text("S\(index + 1)")
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label3)
                .frame(width: 28, alignment: .leading)
            Text(summaryLine)
                .font(.system(size: 15, weight: .medium).monospacedDigit())
                .foregroundStyle(OG.label)
            Spacer(minLength: 0)
            if showsRIR, let rir {
                Text("RIR \(Int(rir.rounded()))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label3)
            }
        }
        .padding(.vertical, 4)
    }
}
