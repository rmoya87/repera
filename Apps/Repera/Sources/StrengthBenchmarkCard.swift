import Foundation
import ReperaDomain
import SwiftUI

/// Compares a recorded gym 1RM with competition *results*. This is an
/// orientation, not a population ranking or verified competition result.
/// Reference fields are stored only on this device.
struct StrengthBenchmarkCard: View {
    @Environment(ReperaStore.self) private var store
    let exercise: Exercise
    let testedOneRMKg: Double?

    @AppStorage("strengthBenchmarks.sexCategory") private var sexCategory = ""
    @AppStorage("strengthBenchmarks.ageYears") private var ageYears = 0
    @AppStorage("strengthBenchmarks.manualWeightKg") private var manualWeightKg = 0.0
    @State private var reference: [StrengthBenchmarkDistribution] = []
    @State private var didLoad = false

    static func lift(for name: String) -> StrengthBenchmarkLift? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_ES"))
            .lowercased()
        switch normalized {
        case "sentadilla", "sentadilla trasera", "back squat", "barbell back squat":
            return .squat
        case "press banca", "press de banca", "bench press", "barbell bench press":
            return .benchPress
        case "peso muerto", "peso muerto convencional", "deadlift", "conventional deadlift":
            return .deadlift
        default:
            return nil
        }
    }

    private var latestWeightKg: Double? {
        store.state.bodyWeights.max(by: { $0.date < $1.date })?.weightKg
    }

    private var selectedWeightKg: Double {
        let latest = latestWeightKg ?? 0
        return latest > 0 ? latest : manualWeightKg
    }

    private var match: StrengthBenchmarkResult? {
        guard let lift = Self.lift(for: exercise.name),
              let sex = StrengthBenchmarkSex(rawValue: sexCategory),
              let testedOneRMKg, testedOneRMKg.isFinite, testedOneRMKg > 0,
              ageYears >= 14, selectedWeightKg > 0 else { return nil }
        return StrengthBenchmarkEngine.compareCompetitionOneRepMax(
            weightKg: testedOneRMKg, lift: lift, sex: sex, equipment: .raw,
            age: ageYears, bodyWeightKg: selectedWeightKg,
            distributions: reference
        )
    }

    var body: some View {
        if Self.lift(for: exercise.name) != nil {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Tu nivel · fuerza")
                OGCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Referencia de competición")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OG.label)
                        Text("Compara tu 1RM registrado con marcas de competición OpenPowerlifting. Es una orientación: no mide tu posición entre la población ni equivale a una marca oficial.")
                            .font(.footnote)
                            .foregroundStyle(OG.label2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 12) {
                            Picker("Categoría", selection: $sexCategory) {
                                Text("Categoría").tag("")
                                Text("Femenina").tag("female")
                                Text("Masculina").tag("male")
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Categoría competitiva")

                            Picker("Edad", selection: $ageYears) {
                                Text("Edad").tag(0)
                                ForEach(14...80, id: \.self) { year in
                                    Text("\(year) años").tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Edad para referencia")
                        }
                        if let latestWeightKg, latestWeightKg > 0 {
                            Text("Peso corporal: \(ReperaNumberFormat.decimal(latestWeightKg)) kg · último registro")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                        } else {
                            TextField("Peso corporal (kg)", value: $manualWeightKg, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Peso corporal en kilogramos")
                        }

                        if !didLoad {
                            ProgressView("Preparando referencia…")
                        } else if testedOneRMKg == nil {
                            Text("Registra un 1RM probado en Evolución para ver una referencia. No se compara el e1RM estimado.")
                                .font(.footnote)
                                .foregroundStyle(OG.label3)
                        } else if sexCategory.isEmpty || ageYears == 0 || selectedWeightKg <= 0 {
                            Text("Selecciona categoría, edad y peso corporal para consultar tu referencia.")
                                .font(.footnote)
                                .foregroundStyle(OG.label3)
                        } else if let match {
                            HStack(alignment: .firstTextBaseline) {
                                Text("P\(Int(match.percentile.rounded()))")
                                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                                    .foregroundStyle(OG.accent)
                                Text("orientativo")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(OG.label2)
                                Spacer()
                                if let testedOneRMKg {
                                    Text("\(ReperaNumberFormat.decimal(testedOneRMKg)) kg")
                                        .font(.title3.weight(.bold).monospacedDigit())
                                        .foregroundStyle(OG.label)
                                }
                            }
                            Text("Frente a \(match.sampleCount) resultados de competición \(match.ageSpecific ? "de tu edad" : "de todas las edades") en la categoría de peso correspondiente. Datos de mayo de 2026.")
                                .font(.caption)
                                .foregroundStyle(OG.label2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Sin muestra suficiente o tu marca queda fuera del rango publicado. No se calcula un percentil.")
                                .font(.footnote)
                                .foregroundStyle(OG.label3)
                        }
                        Text("Fuente: OpenPowerlifting · CC0 · participantes de competiciones, no población general.")
                            .font(.caption2)
                            .foregroundStyle(OG.label3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .task {
                guard !didLoad else { return }
                let url = Bundle.main.url(forResource: "strength_benchmarks", withExtension: "json")
                let loaded: [StrengthBenchmarkDistribution] = await Task.detached(priority: .utility) {
                    guard let url, let data = try? Data(contentsOf: url) else { return [] }
                    return (try? JSONDecoder().decode([StrengthBenchmarkDistribution].self, from: data)) ?? []
                }.value
                reference = loaded
                didLoad = true
            }
        }
    }
}
