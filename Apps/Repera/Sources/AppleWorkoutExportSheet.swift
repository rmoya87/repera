import HealthKit
import SwiftUI
import WorkoutKit

/// Apple Workout is an alternative owner of the sensor session, not a mirror of
/// Repera's active workout. Only deliberately selected endurance activities
/// with goals supported by WorkoutKit can be handed off.
struct AppleWorkoutExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sport: LiveSport
    @State private var goalMode: GoalMode = .time
    @State private var minutes = 30
    @State private var distanceKm = 5
    @State private var isOpening = false
    @State private var errorMessage: String?

    private enum GoalMode: String, CaseIterable, Identifiable {
        case time, distance
        var id: String { rawValue }
        var label: String { self == .time ? "Tiempo" : "Distancia" }
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

                    if goalMode == .time {
                        Stepper("Duración: \(minutes) min", value: $minutes, in: 5...240, step: 5)
                    } else {
                        Stepper("Distancia: \(distanceKm) km", value: $distanceKm, in: 1...100)
                    }
                }

                Section {
                    Text("Abre esta actividad en Entreno del Apple Watch. Para no registrar dos sesiones en Salud, utiliza Entreno de Apple o Repera, pero no ambas grabaciones a la vez.")
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
    }

    private func openWorkout() {
        guard !isOpening else { return }
        isOpening = true
        Task { @MainActor in
            defer { isOpening = false }
            let activity = sport.healthType
            let location: HKWorkoutSessionLocationType = sport.usesGPS ? .outdoor : .indoor
            let goal: WorkoutKit.WorkoutGoal = goalMode == .time
                ? .time(Double(minutes), .minutes)
                : .distance(Double(distanceKm), .kilometers)

            guard SingleGoalWorkout.supportsActivity(activity),
                  SingleGoalWorkout.supportsGoal(goal, activity: activity, location: location) else {
                errorMessage = "La app Entreno no admite este objetivo para el deporte seleccionado."
                return
            }
            let workout = SingleGoalWorkout(activity: activity, location: location, goal: goal)
            let plan = WorkoutPlan(.goal(workout), id: UUID())
            do {
                try await plan.openInWorkoutApp()
                dismiss()
            } catch {
                errorMessage = "Comprueba que tienes un Apple Watch compatible y enlazado. \(error.localizedDescription)"
            }
        }
    }
}
