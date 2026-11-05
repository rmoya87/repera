import ReperaDomain
import SwiftUI

/// Read-only projection of the same block tree stored in Supabase and authored on web.
/// Athlete's private workout state is intentionally never mutated here.
struct BusinessProfessionalSessionCard: View {
    let session: BusinessProfessionalTrainingSession
    let centerName: String
    var compact: Bool = false

    private var blocks: [BusinessPrescriptionBlock] {
        session.prescription?.isCanonicalV1 == true ? session.prescription?.blocks ?? [] : []
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

/// Detalle de entreno profesional: mismos bloques que un entreno programado + Play.
struct BusinessProfessionalSessionDetailView: View {
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(ReperaStore.self) private var store
    let session: BusinessProfessionalTrainingSession
    var onStartRoutine: (Routine) -> Void = { _ in }
    @State private var startFailureMessage: String?
    @State private var openExerciseId: UUID?

    private var planRoutine: Routine? {
        guard let prescription = session.prescription, prescription.isCanonicalV1 else { return nil }
        let built = store.routineFromProfessionalPrescription(
            prescription,
            id: session.id,
            title: session.title,
            scheduledDate: BusinessDataStore.parseDayKey(session.scheduledDate),
            scheduledTimeMinutes: session.scheduledTimeMinutes
        )
        guard let built, !built.blocks.isEmpty else { return nil }
        return built
    }

    private var daySubtitle: String {
        let center = businessData.centerName(session.orgId)
        if let date = BusinessDataStore.parseDayKey(session.scheduledDate) {
            return "\(center) · \(SpanishDate.long(date))"
        }
        return center
    }

    var body: some View {
        List {
            OGScrollablePageTitle(session.title)
                .ogScrollingTitleListRow()
            Text(daySubtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(OG.label2)
                .fixedSize(horizontal: false, vertical: true)
                .ogSessionDateListRow()

            if !session.instructions.isEmpty {
                Section {
                    Text(session.instructions)
                        .font(.subheadline)
                        .foregroundStyle(OG.label2)
                }
            }

            if let plan = planRoutine {
                Section {
                    OGRoutineBlocksList(
                        blocks: plan.blocks,
                        opensExerciseDetail: true,
                        onOpenExercise: { openExerciseId = $0 }
                    )
                }
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .navigationDestination(item: $openExerciseId) { exerciseId in
            ExerciseDetailView(exerciseId: exerciseId)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    beginPlan()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(OG.accent)
                .accessibilityLabel("Comenzar")
            }
        }
        .alert("No se ha podido iniciar el entreno", isPresented: Binding(
            get: { startFailureMessage != nil },
            set: { if !$0 { startFailureMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { startFailureMessage = nil }
        } message: {
            Text(startFailureMessage ?? "")
        }
    }

    private func beginPlan() {
        if let plan = planRoutine {
            onStartRoutine(store.ensureProfessionalRoutineInLibrary(plan))
            return
        }
        if !store.startFallbackGymOrHIITActivity(title: session.title) {
            startFailureMessage = HealthKitStore.shared.lastError
                ?? "No se pudo iniciar el registro sin plan."
        }
    }
}

/// A confirmed class/appointment is shown once, even when it has a
/// trainer-published prescription attached to its source occurrence.
struct BusinessBookedOccurrenceDetailView: View {
    @Environment(BusinessDataStore.self) private var businessData
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let booking: BusinessBooking
    let occurrence: BusinessOccurrence
    var onStartRoutine: (Routine) -> Void = { _ in }
    @State private var confirmCancellation = false
    @State private var openExerciseId: UUID?

    private var associatedSession: BusinessProfessionalTrainingSession? {
        businessData.trainingSessions.first {
            $0.sourceOccurrenceId == occurrence.id && $0.clientId == booking.clientId
        }
    }

    private var planRoutine: Routine? {
        let day = BusinessDataStore.date(occurrence.startsAt)
        let minutes: Int? = {
            guard let start = day else { return nil }
            let cal = Calendar.current
            return cal.component(.hour, from: start) * 60 + cal.component(.minute, from: start)
        }()
        if let session = associatedSession, let rx = session.prescription, rx.isCanonicalV1 {
            let built = store.routineFromProfessionalPrescription(
                rx,
                id: session.id,
                title: session.title.isEmpty ? occurrence.title : session.title,
                scheduledDate: day ?? BusinessDataStore.parseDayKey(session.scheduledDate),
                scheduledTimeMinutes: minutes ?? session.scheduledTimeMinutes
            )
            guard let built, !built.blocks.isEmpty else { return nil }
            return built
        }
        if let rx = occurrence.prescription, rx.isCanonicalV1 {
            let built = store.routineFromProfessionalPrescription(
                rx,
                id: occurrence.id,
                title: occurrence.trainingTitle ?? occurrence.title,
                scheduledDate: day,
                scheduledTimeMinutes: minutes
            )
            guard let built, !built.blocks.isEmpty else { return nil }
            return built
        }
        return nil
    }

    var body: some View {
        List {
            OGScrollablePageTitle(occurrence.title)
                .ogScrollingTitleListRow()
            if let start = BusinessDataStore.date(occurrence.startsAt) {
                Text("\(businessData.centerName(occurrence.orgId)) · \(SpanishDate.long(start))")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(OG.label2)
                    .ogSessionDateListRow()
            }

            Section {
                Label("Reserva confirmada", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(OG.accent)
                if let start = BusinessDataStore.date(occurrence.startsAt) {
                    detailRow(icon: "calendar", title: "Inicio", value: SpanishDate.format(start, date: .abbreviated, time: .shortened))
                }
                if let finish = BusinessDataStore.date(occurrence.endsAt) {
                    detailRow(icon: "clock", title: "Fin", value: SpanishDate.format(finish, date: .omitted, time: .shortened))
                }
            }

            if let plan = planRoutine {
                Section {
                    OGRoutineBlocksList(
                        blocks: plan.blocks,
                        opensExerciseDetail: true,
                        onOpenExercise: { openExerciseId = $0 }
                    )
                }
            }

            Section {
                Button("Cancelar reserva", role: .destructive) {
                    confirmCancellation = true
                }
                .disabled(businessData.isSubmitting)
                if let error = businessData.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(OG.red)
                }
            }
        }
        .ogListChrome()
        .ogScrollingTitleNav()
        .navigationDestination(item: $openExerciseId) { exerciseId in
            ExerciseDetailView(exerciseId: exerciseId)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let plan = planRoutine {
                        onStartRoutine(store.ensureProfessionalRoutineInLibrary(plan))
                    } else {
                        let training = occurrence.trainingTitle?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let title = training.isEmpty ? occurrence.title : training
                        _ = store.startFallbackGymOrHIITActivity(title: title)
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(OG.accent)
                .accessibilityLabel("Comenzar")
            }
        }
        .confirmationDialog("¿Cancelar esta reserva?", isPresented: $confirmCancellation) {
            Button("Cancelar reserva", role: .destructive) {
                Task {
                    await businessData.cancel(booking)
                    if businessData.booking(for: occurrence.id) == nil {
                        dismiss()
                    }
                }
            }
            Button("Volver", role: .cancel) {}
        } message: {
            Text("La devolución del crédito depende de las condiciones de cancelación del centro.")
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OG.accent)
                .frame(width: 18)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(OG.label2)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OG.label)
                .multilineTextAlignment(.trailing)
        }
    }
}
