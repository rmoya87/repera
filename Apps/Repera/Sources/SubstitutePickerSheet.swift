import ReperaDomain
import SwiftUI

/// Lista de sustitutos del mismo músculo / target.
struct SubstitutePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var exercise: Exercise
    var catalog: [Exercise]
    var onPick: (Exercise) -> Void

    private var substitutes: [Exercise] {
        ExerciseSubstitutes.substitutes(for: exercise, in: catalog)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Cambiar ejercicio") {
                CloseToolbarButton { dismiss() }
            }
            .padding(.top, 4)

            Text("Mismo músculo que \(exercise.name).")
                .font(.footnote)
                .foregroundStyle(OG.label2)
                .padding(.horizontal, 4)

            if substitutes.isEmpty {
                Text("No hay sustitutos claros en el catálogo.")
                    .foregroundStyle(OG.label2)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(substitutes.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().opacity(0.35).padding(.leading, 14)
                        }
                        Button {
                            onPick(item)
                        } label: {
                            HStack(spacing: 12) {
                                ExerciseThumb(exercise: item)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundStyle(OG.label)
                                    Text(item.muscleGroup)
                                        .font(.caption)
                                        .foregroundStyle(OG.label2)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
            }
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .tint(OG.accent)
        .preferredColorScheme(.dark)
    }
}
