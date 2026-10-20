import Charts
import Foundation
import HealthKit
import Observation
import SwiftUI
import ReperaDomain

/// Solo en el iPhone: nunca forma parte de AppSettings/iCloud ni de los DTO de Supabase.
struct RecoverySleepNight: Identifiable, Sendable, Equatable {
    var date: Date
    var hours: Double
    var deepHours: Double
    var remHours: Double
    var id: Date { date }
}

enum CycleEstimate: String, Sendable {
    case menstrual = "Menstruación registrada"
    case follicular = "Fase folicular estimada"
    case ovulatory = "Ovulación aproximada"
    case luteal = "Fase lútea estimada"
    case unknown = "Fase no disponible"
}

@MainActor
@Observable
final class HealthRecoveryStore {
    static let shared = HealthRecoveryStore()
    private let healthStore = HKHealthStore()
    private let sleepKey = "repera.privateHealth.sleepEnabled"
    private let cycleKey = "repera.privateHealth.cycleEnabled"

    var sleepEnabled: Bool {
        didSet {
            UserDefaults.standard.set(sleepEnabled, forKey: sleepKey)
            if !sleepEnabled { nights = [] }
        }
    }
    var cycleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(cycleEnabled, forKey: cycleKey)
            if !cycleEnabled { menstrualDays = []; positiveOvulationTests = [] }
        }
    }
    private(set) var nights: [RecoverySleepNight] = []
    private(set) var menstrualDays: [Date] = []
    private(set) var positiveOvulationTests: [Date] = []
    private(set) var loading = false
    private(set) var errorMessage: String?
    private(set) var lastRefreshed: Date?

    private init() {
        sleepEnabled = UserDefaults.standard.bool(forKey: sleepKey)
        cycleEnabled = UserDefaults.standard.bool(forKey: cycleKey)
    }

    var lastNight: RecoverySleepNight? { nights.last }
    var averageHours: Double? {
        let recent = Array(nights.suffix(14))
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0) { $0 + $1.hours } / Double(recent.count)
    }

    /// Índice informativo de descanso, NO una predicción clínica de recuperación.
    var sleepIndex: Int? {
        guard let hours = lastNight?.hours else { return nil }
        let target = max(7, min(9, averageHours ?? 8))
        return Int((100 * min(hours / target, 1)).rounded())
    }

    var cycleEstimate: CycleEstimate {
        guard cycleEnabled, let latest = periodStarts.last else { return .unknown }
        let today = Calendar.current.startOfDay(for: Date())
        let elapsed = Calendar.current.dateComponents([.day], from: latest, to: today).day ?? -1
        guard elapsed >= 0 else { return .unknown }
        if elapsed <= 5 && menstrualDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            return .menstrual
        }
        let starts = periodStarts
        guard starts.count >= 3 else { return .unknown }
        let gaps = zip(starts.dropFirst(), starts).map {
            Calendar.current.dateComponents([.day], from: $1, to: $0).day ?? 0
        }.filter { (21...40).contains($0) }
        guard gaps.count >= 2 else { return .unknown }
        let avg = Double(gaps.reduce(0, +)) / Double(gaps.count)
        let ovulationApprox = Int(avg.rounded()) - 14
        guard elapsed < Int(avg.rounded()) else { return .unknown }
        if abs(elapsed - ovulationApprox) <= 1 { return .ovulatory }
        return elapsed < ovulationApprox ? .follicular : .luteal
    }

    private var periodStarts: [Date] {
        let days = menstrualDays.sorted()
        var starts: [Date] = []
        for day in days {
            if let last = starts.last {
                let distance = Calendar.current.dateComponents([.day], from: last, to: day).day ?? 0
                if distance <= 10 { continue }
            }
            starts.append(day)
        }
        return starts
    }

    var trainingTip: String? {
        guard let lastNight,
              abs(Calendar.current.dateComponents([.day], from: lastNight.date, to: Date()).day ?? 99) <= 1
              || cycleEstimate == .menstrual else { return nil }
        if lastNight.hours < 6 {
            return "Has dormido menos de 6 horas. Ajusta el esfuerzo a tus sensaciones y cuida la técnica."
        }
        if cycleEstimate == .menstrual {
            return "Has registrado menstruación. Si tienes molestias, adapta el volumen; no necesitas reducirlo si te encuentras bien."
        }
        if lastNight.hours >= 7 {
            return "Has descansado al menos 7 horas. Mantén tu plan y guía las cargas por tu RIR."
        }
        return nil
    }

    func setSleep(_ enabled: Bool) async {
        sleepEnabled = enabled
        if enabled { await authorizeAndRefresh(types: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]) }
    }

    func setCycle(_ enabled: Bool) async {
        cycleEnabled = enabled
        if enabled {
            await authorizeAndRefresh(types: [
                HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
                HKObjectType.categoryType(forIdentifier: .ovulationTestResult)!
            ])
        }
    }

    private func authorizeAndRefresh(types: Set<HKObjectType>) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Apple Salud no está disponible en este dispositivo."
            return
        }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable(), (sleepEnabled || cycleEnabled), !loading else { return }
        loading = true
        defer { loading = false }
        errorMessage = nil
        if sleepEnabled {
            let sleep = await categorySamples(.sleepAnalysis, days: 45)
            nights = Self.combineSleep(sleep)
        }
        if cycleEnabled {
            let menstrual = await categorySamples(.menstrualFlow, days: 230)
            menstrualDays = Array(Set(menstrual.map { Calendar.current.startOfDay(for: $0.startDate) })).sorted()
            let tests = await categorySamples(.ovulationTestResult, days: 230)
            positiveOvulationTests = tests.filter {
                $0.value == HKCategoryValueOvulationTestResult.positive.rawValue
            }.map(\.startDate).sorted()
        }
        lastRefreshed = Date()
    }

    private func categorySamples(_ identifier: HKCategoryTypeIdentifier, days: Int) async -> [HKCategorySample] {
        guard let type = HKObjectType.categoryType(forIdentifier: identifier) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                _, samples, _ in
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }
    }

    /// Elige una fuente de etapas por noche y fusiona intervalos para no duplicar
    /// sueño de iPhone + Watch o muestras solapadas.
    private static func combineSleep(_ samples: [HKCategorySample]) -> [RecoverySleepNight] {
        struct Segment {
            let start: Date
            let end: Date
            let value: Int
            let source: String
        }
        var grouped: [Date: [Segment]] = [:]
        let stages: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]
        for sample in samples where stages.contains(sample.value) && sample.endDate > sample.startDate {
            let midpoint = sample.startDate.addingTimeInterval(sample.endDate.timeIntervalSince(sample.startDate) / 2)
            let night = Calendar.current.startOfDay(for: midpoint.addingTimeInterval(12 * 3600))
            grouped[night, default: []].append(
                Segment(start: sample.startDate, end: sample.endDate, value: sample.value,
                        source: sample.sourceRevision.source.bundleIdentifier)
            )
        }
        func unionSeconds(_ values: [Segment]) -> Double {
            let ordered = values.sorted { $0.start < $1.start }
            var end: Date?
            var total = 0.0
            for part in ordered {
                if let previous = end, previous > part.start {
                    if part.end > previous {
                        total += part.end.timeIntervalSince(previous)
                        end = part.end
                    }
                } else {
                    total += part.end.timeIntervalSince(part.start)
                    end = part.end
                }
            }
            return total
        }
        return grouped.compactMap { night, all in
            let sources = Dictionary(grouping: all, by: \.source)
            guard let segments = sources.values.max(by: {
                let a = $0.filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }.count
                let b = $1.filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }.count
                return a == b ? unionSeconds($0) < unionSeconds($1) : a < b
            }) else { return nil }
            let hours = min(24, unionSeconds(segments) / 3600)
            guard hours >= 0.25 else { return nil }
            return RecoverySleepNight(
                date: night, hours: hours,
                deepHours: unionSeconds(segments.filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }) / 3600,
                remHours: unionSeconds(segments.filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }) / 3600
            )
        }.sorted { $0.date < $1.date }
    }
}

struct HealthRecoverySettingsView: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        Form {
            Section {
                Toggle("Analizar descanso", isOn: Binding(
                    get: { recovery.sleepEnabled },
                    set: { enabled in Task { await recovery.setSleep(enabled) } }
                ))
                Toggle("Seguimiento del ciclo", isOn: Binding(
                    get: { recovery.cycleEnabled },
                    set: { enabled in Task { await recovery.setCycle(enabled) } }
                ))
            } footer: {
                Text("Los datos de sueño, menstruación y ovulación permanecen en Apple Salud y en la memoria de este dispositivo. No se envían a Supabase ni se comparten con entrenadores.")
            }
            Section("Privacidad") {
                Label("Sin sincronización de salud con Supabase", systemImage: "iphone.gen3")
                Label("Sin compartir el ciclo ni el sueño", systemImage: "lock.shield")
                if recovery.loading { ProgressView("Leyendo Apple Salud…") }
                if let message = recovery.errorMessage { Text(message).foregroundStyle(OG.orange) }
                Button("Actualizar desde Apple Salud") { Task { await recovery.refresh() } }
            }
            Section {
                Text("El sueño es orientativo. Las fases menstruales son estimaciones, no confirman la ovulación ni predicen la fertilidad. Las recomendaciones no sustituyen la valoración profesional.")
                    .font(.footnote).foregroundStyle(OG.label2)
            }
        }
        .ogListChrome()
        .ogPinnedTransparentNav("Salud y recuperación")
        .task { await recovery.refresh() }
    }
}

struct HealthRecoveryProgressView: View {
    @State private var recovery = HealthRecoveryStore.shared
    @State private var section: SectionKind = .sleep

    private enum SectionKind: String, CaseIterable {
        case sleep = "Sueño"
        case cycle = "Ciclo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Recuperación", selection: $section) {
                Text("Sueño").tag(SectionKind.sleep)
                if recovery.cycleEnabled { Text("Ciclo").tag(SectionKind.cycle) }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)

            switch section {
            case .sleep: sleepContent
            case .cycle: cycleContent
            }
        }
        .task { await recovery.refresh() }
        .onChange(of: recovery.cycleEnabled) { _, enabled in
            if !enabled { section = .sleep }
        }
    }

    @ViewBuilder
    private var sleepContent: some View {
        OGCardSectionTitle(title: "Descanso")
        if !recovery.sleepEnabled {
            emptyCard(title: "Activa el análisis del sueño", detail: "Permite la lectura de sueño desde Ajustes → Salud y recuperación.")
        } else if recovery.nights.isEmpty {
            emptyCard(title: "Sin datos de sueño", detail: "Apple Salud no ha devuelto registros recientes. Revisa los permisos o utiliza un dispositivo compatible.")
        } else {
            OGCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(recovery.lastNight.map { String(format: "%.1f h", $0.hours) } ?? "—")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(OG.label)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Última noche").font(.subheadline).foregroundStyle(OG.label2)
                            if let index = recovery.sleepIndex {
                                Text("Descanso \\(index)/100")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(OG.accent)
                            }
                        }
                    }
                    Chart {
                        ForEach(Array(recovery.nights.suffix(14))) { night in
                        BarMark(
                            x: .value("Día", night.date, unit: .day),
                            y: .value("Horas", night.hours),
                            width: .ratio(0.65)
                        )
                        .foregroundStyle(night.hours >= 7 ? OG.accent : OG.orange)
                        .cornerRadius(5)
                        }
                        RuleMark(y: .value("Referencia", 7))
                            .foregroundStyle(OG.label3.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartYScale(domain: 0...12)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartXAxis { AxisMarks(values: .stride(by: .day, count: 2)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                    .frame(height: 218)
                    if let average = recovery.averageHours {
                        Label("Media reciente: " + String(format: "%.1f h", average), systemImage: "moon.stars.fill")
                            .font(.subheadline).foregroundStyle(OG.label2)
                    }
                    Text("Las fases de sueño se estiman por el dispositivo. Las barras utilizan una sola fuente por noche para evitar duplicados.")
                        .font(.caption).foregroundStyle(OG.label3)
                }
            }
        }
    }

    @ViewBuilder
    private var cycleContent: some View {
        OGCardSectionTitle(title: "Ciclo menstrual")
        if !recovery.cycleEnabled || recovery.menstrualDays.isEmpty {
            emptyCard(title: "Sin registros del ciclo", detail: "Activa el seguimiento y registra la menstruación en Apple Salud.")
        } else {
            OGCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label(recovery.cycleEstimate.rawValue, systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(OG.label)
                    Chart(recovery.menstrualDays.suffix(90), id: \.self) { day in
                        PointMark(x: .value("Fecha", day), y: .value("Menstruación", 1))
                            .symbolSize(75)
                            .foregroundStyle(OG.orange)
                    }
                    .chartYScale(domain: 0...2)
                    .chartYAxis(.hidden)
                    .frame(height: 105)
                    Text("Registros de menstruación de los últimos 90 días")
                        .font(.caption).foregroundStyle(OG.label2)
                    Divider().opacity(0.3)
                    Text("Calendario de las últimas seis semanas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OG.label)
                    cycleCalendar
                    if !recovery.positiveOvulationTests.isEmpty {
                        Label("Pruebas de ovulación positivas registradas: \(recovery.positiveOvulationTests.count)", systemImage: "checkmark.circle")
                            .font(.footnote).foregroundStyle(OG.label2)
                    }
                    Text("Fase aproximada solo si hay suficientes ciclos compatibles. Nunca equivale a una ovulación confirmada ni debe utilizarse para anticoncepción.")
                        .font(.caption).foregroundStyle(OG.label3)
                }
            }
        }
    }

    private var cycleCalendar: some View {
        let calendar = Calendar.current
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .weekOfYear, value: -5, to: currentWeek) ?? currentWeek
        let days = (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let weekdays = (0..<7).map { offset in
            let first = calendar.firstWeekday
            return calendar.veryShortStandaloneWeekdaySymbols[(first - 1 + offset) % 7]
        }
        return VStack(spacing: 9) {
            HStack(spacing: 4) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index].uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(OG.label3)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 5) {
                ForEach(days, id: \.self) { day in
                    let period = recovery.menstrualDays.contains { calendar.isDate($0, inSameDayAs: day) }
                    let today = calendar.isDateInToday(day)
                    Text(day.formatted(.dateTime.day()))
                        .font(.system(size: 12, weight: today ? .bold : .medium, design: .rounded))
                        .foregroundStyle(period ? OG.orange : OG.label)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(
                            period ? OG.orange.opacity(0.17) : (today ? OG.accent.opacity(0.10) : OG.surface2),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted)
                            + (period ? ", menstruación registrada" : ""))
                }
            }
            Label("Días registrados de menstruación", systemImage: "circle.fill")
                .font(.caption).foregroundStyle(OG.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func emptyCard(title: String, detail: String) -> some View {
        OGCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: "heart.text.square").font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(OG.label2)
                NavigationLink("Configurar Apple Salud") { HealthRecoverySettingsView() }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(OG.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RecoveryTrainingTip: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        Group {
            if let tip = recovery.trainingTip {
                HStack(alignment: .top, spacing: 10) {
                Image(systemName: "moon.stars.fill").foregroundStyle(OG.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tu contexto de hoy").font(.subheadline.weight(.semibold)).foregroundStyle(OG.label)
                    Text(tip).font(.footnote).foregroundStyle(OG.label2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
                .background(OG.surface, in: RoundedRectangle(cornerRadius: OG.radiusCard))
            }
        }
        .task { await recovery.refresh() }
    }
}

struct RecoveryHomeCard: View {
    @State private var recovery = HealthRecoveryStore.shared

    var body: some View {
        if recovery.sleepEnabled || recovery.cycleEnabled {
            VStack(alignment: .leading, spacing: 8) {
                OGCardSectionTitle(title: "Tu estado de hoy")
                NavigationLink {
                    HealthRecoverySettingsView()
                } label: {
                    OGCard {
                        HStack(spacing: 14) {
                            Image(systemName: "moon.stars.fill")
                                .font(.title2)
                                .foregroundStyle(OG.accent)
                                .frame(width: 42, height: 42)
                                .background(OG.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                if recovery.sleepEnabled {
                                    Text(recovery.lastNight.map { String(format: "%.1f h de sueño", $0.hours) }
                                        ?? "Sueño: esperando datos de Apple Salud")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(OG.label)
                                }
                                if recovery.cycleEnabled {
                                    Text(recovery.cycleEstimate.rawValue)
                                        .font(.footnote)
                                        .foregroundStyle(OG.label2)
                                }
                                if let index = recovery.sleepIndex {
                                    Text("Índice orientativo de sueño · \\(index)/100")
                                        .font(.caption)
                                        .foregroundStyle(OG.label3)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(OG.label3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .task { await recovery.refresh() }
        }
    }
}
