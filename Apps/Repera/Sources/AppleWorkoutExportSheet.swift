import HealthKit
import SwiftUI
import WorkoutKit

/// Apple Workout is an alternative owner of the sensor session, not a mirror of
/// Repera's active workout. Only deliberately selected endurance activities
/// with goals supported by WorkoutKit can be handed off.
///
/// On iPhone the watch-only open API is unavailable. The supported paths are
/// SwiftUI `workoutPreview` (system sheet to send/start) and
/// `WorkoutScheduler` (sync into the Watch Workout app schedule).
struct AppleWorkoutExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sport: LiveSport
    @State private var goalMode: GoalMode = .time
    @State private var minutes = 30
    @State private var distanceKm = 5
    @State private var isOpening = false
    @State private var errorMessage: String?
    @State private var previewPlan: WorkoutPlan?
    @State private var showWorkoutPreview = false

    private enum GoalMode: String, CaseIterable, Identifiable {
        case time, distance, intervals
        var id: String { rawValue }
        var label: String {
            switch self {
            case .time: "Tiempo"
            case .distance: "Distancia"
            case .intervals: "Intervalos"
            }
        }
    }

    static func supports(_ sport: LiveSport) -> Bool {
        switch sport {
        case .running, .walking, .hiking, .trail, .cycling, .mountainBike, .gravel:
            return SingleGoalWorkout.supportsActivity(sport.healthType)
        default:
            // No fake WOD/strength sets as standard Apple Workout intervals.
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    Label(sport.title, systemImage: sport.symbol)
                }

                Section("Objetivo") {
                    Picker("Tipo", selection: $goalMode) {
                        ForEach(GoalMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch goalMode {
                    case .time:
                        Stepper("Duración: \(minutes) min", value: $minutes, in: 5...240, step: 5)
                    case .distance:
                        Stepper("Distancia: \(distanceKm) km", value: $distanceKm, in: 1...100)
                    case .intervals:
                        Stepper("Bloques de trabajo: \(minutes) × 1 min", value: $minutes, in: 4...40, step: 2)
                        Text("Cada bloque: 1 min trabajo + 1 min recuperación. Sin inventar distancias GPS.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Prepara el objetivo en Entreno del Apple Watch. Para no registrar dos sesiones en Salud, utiliza Entreno de Apple o Repera, pero no ambas grabaciones a la vez.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Enviar a Apple Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Abrir Entreno") { openWorkout() }
                        .disabled(isOpening)
                }
            }
            .alert("No se pudo abrir Entreno", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .tint(OG.accent)
        .presentationDetents([.medium, .large])
        .workoutPreview(previewPlan ?? placeholderPlan, isPresented: $showWorkoutPreview)
        .onChange(of: showWorkoutPreview) { _, presented in
            if !presented {
                previewPlan = nil
                dismiss()
            }
        }
    }

    /// Fallback only while the binding is false; never presented as a real export.
    private var placeholderPlan: WorkoutPlan {
        let workout = SingleGoalWorkout(
            activity: .running,
            location: .outdoor,
            goal: .time(30, .minutes)
        )
        return WorkoutPlan(.goal(workout), id: UUID())
    }

    private func makePlan() -> WorkoutPlan? {
        let activity = sport.healthType
        let location: HKWorkoutSessionLocationType = sport.usesGPS ? .outdoor : .indoor
        switch goalMode {
        case .time, .distance:
            let goal: WorkoutKit.WorkoutGoal = goalMode == .time
                ? .time(Double(minutes), .minutes)
                : .distance(Double(distanceKm), .kilometers)
            guard SingleGoalWorkout.supportsActivity(activity),
                  SingleGoalWorkout.supportsGoal(goal, activity: activity, location: location) else {
                return nil
            }
            let workout = SingleGoalWorkout(activity: activity, location: location, goal: goal)
            return WorkoutPlan(.goal(workout), id: UUID())
        case .intervals:
            guard CustomWorkout.supportsActivity(activity) else { return nil }
            let workGoal: WorkoutKit.WorkoutGoal = .time(1, .minutes)
            let recoveryGoal: WorkoutKit.WorkoutGoal = .time(1, .minutes)
            guard CustomWorkout.supportsGoal(workGoal, activity: activity, location: location),
                  CustomWorkout.supportsGoal(recoveryGoal, activity: activity, location: location) else {
                return nil
            }
            var heartAlert: (any WorkoutAlert)?
            let zoneAlert = HeartRateZoneAlert(zone: 2)
            if CustomWorkout.supportsAlert(zoneAlert, activity: activity, location: location) {
                heartAlert = zoneAlert
            }
            let work = IntervalStep(
                .work,
                step: WorkoutStep(goal: workGoal, alert: heartAlert)
            )
            let recovery = IntervalStep(
                .recovery,
                step: WorkoutStep(goal: recoveryGoal, alert: nil)
            )
            let iterations = max(2, minutes / 2)
            let block = IntervalBlock(steps: [work, recovery], iterations: iterations)
            let custom = CustomWorkout(
                activity: activity,
                location: location,
                displayName: "\(sport.title) · intervalos",
                warmup: nil,
                blocks: [block],
                cooldown: nil
            )
            return WorkoutPlan(.custom(custom), id: UUID())
        }
    }

    private func openWorkout() {
        guard !isOpening else { return }
        isOpening = true
        Task { @MainActor in
            defer { isOpening = false }
            guard let plan = makePlan() else {
                errorMessage = "La app Entreno no admite este objetivo para el deporte seleccionado."
                return
            }

            // Sync into Watch Workout schedule when the platform supports it.
            // AuthorizationState is not Sendable; bridge via raw Int off the main actor.
            switch await Self.schedulePlanIfAuthorized(plan) {
            case .denied:
                errorMessage = "Activa el permiso de programación de entrenamientos para enviar el objetivo al Apple Watch."
                return
            case .scheduled, .unavailable, .notDetermined:
                break
            }

            previewPlan = plan
            showWorkoutPreview = true
        }
    }

    private enum ScheduleOutcome: Sendable {
        case scheduled
        case denied
        case unavailable
        case notDetermined
    }

    /// WorkoutScheduler auth enums are not Sendable under Swift 6; keep the bridge
    /// nonisolated and only return a Sendable outcome to the view.
    private nonisolated static func schedulePlanIfAuthorized(_ plan: WorkoutPlan) async -> ScheduleOutcome {
        guard WorkoutScheduler.isSupported else { return .unavailable }
        let scheduler = WorkoutScheduler.shared
        var authRaw = await scheduler.authorizationState.rawValue
        if authRaw != WorkoutScheduler.AuthorizationState.authorized.rawValue {
            authRaw = await scheduler.requestAuthorization().rawValue
        }
        if authRaw == WorkoutScheduler.AuthorizationState.authorized.rawValue {
            let when = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Date()
            )
            await scheduler.schedule(plan, at: when)
            return .scheduled
        }
        if authRaw == WorkoutScheduler.AuthorizationState.denied.rawValue
            || authRaw == WorkoutScheduler.AuthorizationState.restricted.rawValue {
            return .denied
        }
        return .notDetermined
    }
}
