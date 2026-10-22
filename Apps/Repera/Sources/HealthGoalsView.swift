import ReperaDomain
import SwiftUI

/// Objetivos opcionales, sincronizados en AppSettings con el resto de la cuenta.
/// Mantiene el objetivo de peso histórico sin migraciones destructivas.
struct HealthGoalsView: View {
    @Environment(ReperaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var steps = ""
    @State private var energy = ""
    @State private var minutes = ""
    @State private var weekly = ""
    @State private var weight = ""
    @State private var hasLoaded = false

    private func parseInt(_ text: String, range: ClosedRange<Int>) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return true }
        guard let parsed = Int(value) else { return false }
        return range.contains(parsed)
    }

    private func parseWeight(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return true }
        guard let parsed = Double(value.replacingOccurrences(of: ",", with: ".")),
              parsed.isFinite else { return false }
        return (20...350).contains(parsed)
    }

    private var valid: Bool {
        parseInt(steps, range: 100...100_000)
            && parseInt(energy, range: 10...10_000)
            && parseInt(minutes, range: 1...1_440)
            && parseInt(weekly, range: 1...21)
            && parseWeight(weight)
    }

    var body: some View {
        Form {
            Section {
                goalRow("Pasos", icon: "figure.walk", text: $steps, unit: "pasos")
                goalRow("Calorías activas", icon: "flame.fill", text: $energy, unit: "kcal")
                goalRow("Tiempo de entreno", icon: "clock.fill", text: $minutes, unit: "min")
            } header: {
                Text("Objetivos diarios")
            } footer: {
                Text("Se comparan con las mediciones reales de Apple Salud. No se incluyen calorías estimadas.")
            }

            Section {
                goalRow("Entrenamientos", icon: "checkmark.circle.fill", text: $weekly, unit: "semana")
            } header: {
                Text("Objetivo semanal")
            } footer: {
                Text("Se aplica a los entrenamientos registrados, incluidos los importados de Salud.")
            }

            Section {
                goalRow("Peso objetivo", icon: "scalemass", text: $weight, unit: "kg", decimal: true)
                if let current = store.state.bodyWeights.first?.weightKg {
                    LabeledContent("Peso registrado", value: "\(current.formatted(.number.precision(.fractionLength(1)))) kg")
                        .foregroundStyle(OG.label2)
                }
            } header: {
                Text("Objetivo corporal")
            } footer: {
                Text("El peso objetivo se muestra como referencia en Progreso. No es una meta diaria que debas cumplir.")
            }

            if !valid {
                Section {
                    Label("Revisa los valores: deben ser positivos y estar dentro de rangos razonables.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(OG.orange)
                }
            }

            Section {
                Button("Guardar objetivos") {
                    save()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .disabled(!valid)
            } footer: {
                Text("Deja un campo vacío para no establecer ese objetivo. Puedes cambiarlos cuando quieras.")
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Objetivos")
        .onAppear(perform: loadOnce)
    }

    private func goalRow(
        _ name: String,
        icon: String,
        text: Binding<String>,
        unit: String,
        decimal: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Label(name, systemImage: icon)
                .foregroundStyle(OG.label)
            Spacer(minLength: 6)
            TextField("—", text: text)
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(OG.label)
                .frame(width: 78)
                .accessibilityLabel(name)
                .ogKeyboardDone()
            Text(unit)
                .font(.footnote)
                .foregroundStyle(OG.label2)
        }
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        let s = store.state.settings
        steps = s.dailyStepsGoal.map { String($0) } ?? ""
        energy = s.dailyActiveEnergyGoalKcal.map { String($0) } ?? ""
        minutes = s.dailyWorkoutMinutesGoal.map { String($0) } ?? ""
        weekly = s.weeklyWorkoutGoal.map { String($0) } ?? ""
        weight = s.bodyWeightGoalKg.map { String(format: "%g", $0) } ?? ""
    }

    private func save() {
        guard valid else { return }
        var s = store.state.settings
        s.dailyStepsGoal = Int(steps.trimmingCharacters(in: .whitespacesAndNewlines))
        s.dailyActiveEnergyGoalKcal = Int(energy.trimmingCharacters(in: .whitespacesAndNewlines))
        s.dailyWorkoutMinutesGoal = Int(minutes.trimmingCharacters(in: .whitespacesAndNewlines))
        s.weeklyWorkoutGoal = Int(weekly.trimmingCharacters(in: .whitespacesAndNewlines))
        let weightText = weight.trimmingCharacters(in: .whitespacesAndNewlines)
        s.bodyWeightGoalKg = weightText.isEmpty ? nil : Double(weightText.replacingOccurrences(of: ",", with: "."))
        store.updateSettings(s)
        dismiss()
    }
}
