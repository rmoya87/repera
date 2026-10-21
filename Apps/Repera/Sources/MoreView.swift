import SwiftUI

struct BodyWeightListView: View {
    @Environment(ReperaStore.self) private var store
    @State private var kgText = ""
    @State private var goalText = ""

    var body: some View {
        List {
            Section {
                HStack {
                    OGNumericTextField(
                        text: $kgText,
                        allowsDecimal: true,
                        autoFocus: false,
                        onCommit: {}
                    )
                    .frame(minHeight: 44)
                    .accessibilityLabel("Peso en kilogramos")
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
                Text("Un peso por día. Si ya hay uno hoy, se actualiza.")
            }

            Section {
                HStack {
                    OGNumericTextField(
                        text: $goalText,
                        allowsDecimal: true,
                        autoFocus: false,
                        onCommit: {}
                    )
                    .frame(minHeight: 44)
                    .accessibilityLabel("Objetivo de peso en kilogramos")
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(OG.label)
                            Text(entry.source.displayName)
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        }
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
            } footer: {
                Text("Propio = guardado en Repera. Salud = importado de Apple Salud.")
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
