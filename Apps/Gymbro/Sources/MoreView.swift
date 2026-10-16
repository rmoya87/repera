import SwiftUI

struct BodyWeightListView: View {
    @Environment(GymbroStore.self) private var store
    @State private var kgText = ""
    @State private var goalText = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("kg", text: $kgText)
                        .ogKeyboardDone()
                        .foregroundStyle(OG.label)
                    Button("Añadir") {
                        if let value = Double(kgText.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            store.addBodyWeight(value)
                            kgText = ""
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
                }
            } header: {
                Text("Registrar")
            } footer: {
                Text("Un pesaje por día. Si ya hay uno hoy, se actualiza.")
            }

            Section {
                HStack {
                    TextField("Objetivo kg", text: $goalText)
                        .ogKeyboardDone()
                        .foregroundStyle(OG.label)
                    Button("Guardar") {
                        var s = store.state.settings
                        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.bodyWeightGoalKg = trimmed.isEmpty
                            ? nil
                            : Double(trimmed.replacingOccurrences(of: ",", with: "."))
                        store.updateSettings(s)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(OG.accent)
                }
                if let goal = store.state.settings.bodyWeightGoalKg,
                   let latest = store.state.bodyWeights.first {
                    let delta = latest.weightKg - goal
                    if abs(delta) < 0.3 {
                        Text("En objetivo (\(goal.formatted(.number.precision(.fractionLength(1)))) kg)")
                            .font(.footnote)
                            .foregroundStyle(OG.accent)
                    } else {
                        let sign = delta > 0 ? "+" : ""
                        Text("\(sign)\(delta.formatted(.number.precision(.fractionLength(1)))) kg vs objetivo")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                    }
                }
            } header: {
                Text("Objetivo")
            }

            Section {
                ForEach(store.state.bodyWeights) { entry in
                    HStack {
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(OG.label)
                        Spacer()
                        Text("\(entry.weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
                            .monospacedDigit()
                            .foregroundStyle(OG.label)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        store.deleteBodyWeight(store.state.bodyWeights[i].id)
                    }
                }
            } header: {
                Text("Historial")
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Peso corporal")
        .onAppear {
            if let g = store.state.settings.bodyWeightGoalKg {
                goalText = String(format: "%g", g)
            }
        }
    }
}
