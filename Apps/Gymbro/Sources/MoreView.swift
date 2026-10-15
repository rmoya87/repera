import SwiftUI

struct BodyWeightListView: View {
    @Environment(GymbroStore.self) private var store
    @State private var kgText = ""

    var body: some View {
        List {
            Section {
                OGPageHeader(title: "Peso corporal")
                    .ogListPageHeaderRow()
            }
            Section {
                HStack {
                    TextField("kg", text: $kgText)
                        .keyboardType(.decimalPad)
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
            }
        }
        .ogListChrome()
        .ogContentTitleNav()
    }
}
