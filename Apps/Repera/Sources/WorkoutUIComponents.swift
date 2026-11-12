import ReperaDomain
import SwiftUI

// MARK: - Resúmenes de rutina / sesión

enum RoutinePresentationStats {
    static func counts(for routine: Routine) -> (exercises: Int, sets: Int) {
        var exercises = 0
        var sets = 0
        for block in routine.blocks {
            if block.kind == .wod, block.exercises.isEmpty {
                exercises += block.movements.filter { !$0.isRest }.count
                sets += block.movements.filter { !$0.isRest }.count
            } else {
                exercises += block.exercises.count
                sets += block.exercises.reduce(0) { $0 + max($1.plannedSets.count, 1) }
            }
        }
        return (exercises, sets)
    }
}

/// Chip de metadatos (fecha, hora, duración, resumen).
struct OGWorkoutMetaChip: View {
    var icon: String? = nil
    var text: String
    var onBg = false

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
        }
        .foregroundStyle(OG.label2)
        .padding(.horizontal, 11)
        .frame(height: 32)
        .background(onBg ? OG.surface : OG.surface2, in: Capsule())
    }
}

// MARK: - Toast Deshacer

struct OGUndoToast: View {
    var message: String
    var actionTitle: String = "Deshacer"
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(OG.label)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button(actionTitle, action: onUndo)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OG.accentText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(OG.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
    }
}

struct OGUndoToastModifier: ViewModifier {
    @Binding var toast: OGUndoToastState?

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let toast {
                OGUndoToast(message: toast.message, onUndo: toast.undo)
                    .padding(.horizontal, OG.pad)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.22), value: toast?.id)
    }
}

struct OGUndoToastState: Equatable {
    let id = UUID()
    let message: String
    let undo: () -> Void

    static func == (lhs: OGUndoToastState, rhs: OGUndoToastState) -> Bool {
        lhs.id == rhs.id && lhs.message == rhs.message
    }
}

extension View {
    func ogUndoToast(_ toast: Binding<OGUndoToastState?>) -> some View {
        modifier(OGUndoToastModifier(toast: toast))
    }
}

// MARK: - Descartar cambios

struct OGDiscardChangesConfirm: ViewModifier {
    @Binding var isPresented: Bool
    var onDiscard: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "¿Descartar cambios?",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("Descartar cambios", role: .destructive, action: onDiscard)
            Button("Seguir editando", role: .cancel) {}
        } message: {
            Text("Perderás los cambios que no hayas guardado.")
        }
    }
}

extension View {
    func ogDiscardChangesConfirm(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) -> some View {
        modifier(OGDiscardChangesConfirm(isPresented: isPresented, onDiscard: onDiscard))
    }
}

// MARK: - Hoja resumen al terminar Play

struct OGWorkoutFinishSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
  var title: String
    var elapsedSeconds: Int
    var completedSets: Int
    var totalSets: Int
    var volumeKg: Double
    var warning: String?
    var onSave: () -> Void
    var onKeepTraining: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(OG.accent)
                .padding(.top, 8)
            Text("¿Terminar entreno?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(OG.label)
            HStack(spacing: 10) {
                finishTile("Tiempo", DurationText.format(elapsedSeconds), icon: "clock", tint: OG.blue)
                finishTile("Series", "\(completedSets)/\(max(totalSets, 1))", icon: "square.stack.3d.up", tint: OG.accent)
                finishTile("Volumen", volumeLabel, icon: "scalemass", tint: OG.accentText)
            }
            if let warning {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(OG.orange)
                    Text(warning)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(OG.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OG.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button {
                onSave()
                dismiss()
            } label: {
                Text("Guardar entreno")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OG.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(OG.accent, in: Capsule())
            }
            Button("Seguir entrenando") {
                onKeepTraining()
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(OG.label)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(OG.surface2, in: Capsule())
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 12)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }

    private var volumeLabel: String {
        guard volumeKg > 0 else { return "—" }
        return "\(ReperaNumberFormat.decimal(volumeKg, maximumFractionDigits: 0)) kg"
    }

    private func finishTile(_ title: String, _ value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .foregroundStyle(OG.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OG.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Cabecera de progreso en Play (series y volumen).
struct OGPlaySessionProgressHeader: View {
    var completedSets: Int
    var totalSets: Int
    var volumeKg: Double
    var startedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedSets) de \(max(totalSets, 1)) series")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(OG.label2)
                Spacer()
                Text(volumeTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(OG.label2)
            }
            ProgressView(value: Double(completedSets), total: Double(max(totalSets, 1)))
                .tint(OG.accent)
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 6)
    }

    private var volumeTitle: String {
        let kg = volumeKg > 0 ? "\(ReperaNumberFormat.decimal(volumeKg, maximumFractionDigits: 0)) kg" : "—"
        return "Volumen \(kg)"
    }
}
