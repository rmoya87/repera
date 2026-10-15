import Foundation
import HealthKit
import Observation

/// Salud de Apple: lectura (Watch/Salud manda) + escritura del entreno.
@MainActor
@Observable
final class HealthKitStore {
    static let shared = HealthKitStore()

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var isAuthorized = false
    var latestWeightKg: Double?
    var latestWeightDate: Date?
    var activeEnergyTodayKcal: Double?
    var workoutMinutesToday: Double?
    /// Métricas en vivo del entreno actual (desde Salud / Watch).
    var liveActiveEnergyKcal: Double?
    var liveDurationSeconds: TimeInterval?
    var lastError: String?

    struct DayMetrics: Sendable {
        var activeEnergyKcal: Double?
        var workoutMinutes: Double?
    }

    private var liveBuilder: HKWorkoutBuilder?
    private var trackedSessionId: UUID?
    private var trackedStart: Date?

    private init() {}

    func requestAccess() async {
        guard isAvailable else {
            lastError = "HealthKit no disponible en este dispositivo"
            isAuthorized = false
            return
        }
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
        ]
        let share: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            refreshAuthorizationStatus()
            if isAuthorized {
                lastError = nil
                await refreshToday()
            } else {
                lastError = "Revisa permisos de Gymbro en Ajustes → Salud"
            }
        } catch {
            lastError = error.localizedDescription
            isAuthorized = false
        }
    }

    /// `requestAuthorization` no falla si el usuario niega: hay que mirar el estado de escritura.
    func refreshAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        let workoutStatus = store.authorizationStatus(for: .workoutType())
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energyStatus = store.authorizationStatus(for: energyType)
        // Conectado = podemos escribir entrenos o al menos energía activa.
        isAuthorized = workoutStatus == .sharingAuthorized || energyStatus == .sharingAuthorized
    }

    func refreshToday() async {
        guard isAvailable else { return }
        async let weight: Void = fetchLatestWeight()
        async let energy: Void = fetchActiveEnergyToday()
        async let minutes: Void = fetchWorkoutMinutesToday()
        _ = await (weight, energy, minutes)
    }

    /// kcal + minutos de entrenos de Salud para un día concreto (no solo “hoy”).
    func dayMetrics(for day: Date) async -> DayMetrics {
        guard isAvailable else { return DayMetrics() }
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
            return DayMetrics()
        }
        async let kcal = activeEnergy(from: start, to: end)
        async let minutes = workoutMinutes(from: start, to: end)
        let (k, m) = await (kcal, minutes)
        return DayMetrics(
            activeEnergyKcal: k > 0 ? k : nil,
            workoutMinutes: m > 0 ? m : nil
        )
    }

    /// Escribe peso en Salud (última modificación gana si luego se vuelve a leer).
    func saveBodyMass(kg: Double, date: Date = Date()) async {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
            latestWeightKg = kg
            latestWeightDate = date
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Sesión en vivo (Apple manda)

    /// Arranca un `HKWorkoutBuilder` de fuerza tradicional alineado con el reloj/Salud.
    func beginWorkout(sessionId: UUID, title: String, start: Date = Date()) async {
        guard isAvailable else { return }
        trackedSessionId = sessionId
        trackedStart = start
        liveActiveEnergyKcal = 0
        liveDurationSeconds = 0

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            liveBuilder = builder
            await refreshLiveMetrics()
        } catch {
            lastError = error.localizedDescription
            liveBuilder = nil
        }
    }

    /// Actualiza calorías/tiempo leyendo Salud (incluye lo que aporta el Apple Watch).
    func refreshLiveMetrics() async {
        guard let start = trackedStart else { return }
        let end = Date()
        liveDurationSeconds = max(0, end.timeIntervalSince(start))
        let apple = await resolveAppleMetrics(from: start, to: end)
        liveActiveEnergyKcal = apple.kcal
        if let secs = apple.durationSeconds, secs > 0 {
            liveDurationSeconds = secs
        }
    }

    /// Cierra el entreno: toma calorías/tiempo de Apple y lo guarda en Salud.
    func finishWorkout(
        sessionId: UUID,
        title: String,
        start: Date,
        end: Date
    ) async -> (kcal: Double, durationSeconds: TimeInterval, workoutUUID: UUID?) {
        let apple = await resolveAppleMetrics(from: start, to: end)
        let duration = apple.durationSeconds ?? max(1, end.timeIntervalSince(start))
        let kcal = apple.kcal

        var savedUUID = apple.existingWorkoutUUID

        if savedUUID == nil {
            savedUUID = await saveStrengthWorkout(
                title: title,
                start: start,
                end: start.addingTimeInterval(duration),
                activeEnergyKcal: kcal,
                preferBuilder: liveBuilder
            )
        } else {
            // Ya hay un entreno del Watch/Salud: no duplicar; solo cerrar builder local si existía.
            await discardLocalBuilder()
        }

        trackedSessionId = nil
        trackedStart = nil
        liveBuilder = nil
        liveActiveEnergyKcal = kcal
        liveDurationSeconds = duration
        await refreshToday()
        return (kcal, duration, savedUUID)
    }

    func discardLiveTracking() async {
        await discardLocalBuilder()
        trackedSessionId = nil
        trackedStart = nil
        liveActiveEnergyKcal = nil
        liveDurationSeconds = nil
    }

    // MARK: - Apple como fuente de verdad

    private struct AppleMetrics {
        var kcal: Double
        var durationSeconds: TimeInterval?
        var existingWorkoutUUID: UUID?
    }

    /// Prioriza un `HKWorkout` del Watch/Salud solapado; si no, suma energía activa del intervalo.
    private func resolveAppleMetrics(from start: Date, to end: Date) async -> AppleMetrics {
        if let workout = await overlappingWorkout(from: start, to: end) {
            let kcal: Double
            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
               let burned = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                kcal = burned
            } else {
                kcal = await activeEnergy(from: workout.startDate, to: workout.endDate)
            }
            return AppleMetrics(
                kcal: kcal,
                durationSeconds: workout.duration,
                existingWorkoutUUID: workout.uuid
            )
        }
        let kcal = await activeEnergy(from: start, to: end)
        return AppleMetrics(kcal: kcal, durationSeconds: end.timeIntervalSince(start), existingWorkoutUUID: nil)
    }

    private func overlappingWorkout(from start: Date, to end: Date) async -> HKWorkout? {
        let expandedStart = start.addingTimeInterval(-120)
        let expandedEnd = end.addingTimeInterval(120)
        let predicate = HKQuery.predicateForSamples(withStart: expandedStart, end: expandedEnd)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { (cont: CheckedContinuation<HKWorkout?, Never>) in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 20,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                // Preferir fuerza / tradicional y el de mayor solape.
                let ranked = workouts
                    .map { w -> (HKWorkout, TimeInterval) in
                        let overlapStart = max(w.startDate, start)
                        let overlapEnd = min(w.endDate, end)
                        let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
                        return (w, overlap)
                    }
                    .filter { $0.1 > 30 }
                    .sorted { a, b in
                        let aStrength = a.0.workoutActivityType == .traditionalStrengthTraining
                            || a.0.workoutActivityType == .functionalStrengthTraining
                            || a.0.workoutActivityType == .highIntensityIntervalTraining
                        let bStrength = b.0.workoutActivityType == .traditionalStrengthTraining
                            || b.0.workoutActivityType == .functionalStrengthTraining
                            || b.0.workoutActivityType == .highIntensityIntervalTraining
                        if aStrength != bStrength { return aStrength && !bStrength }
                        return a.1 > b.1
                    }
                cont.resume(returning: ranked.first?.0)
            }
            store.execute(q)
        }
    }

    private func activeEnergy(from start: Date, to end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double, Never>) in
            let q = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: value)
            }
            store.execute(q)
        }
    }

    private func saveStrengthWorkout(
        title: String,
        start: Date,
        end: Date,
        activeEnergyKcal: Double,
        preferBuilder: HKWorkoutBuilder?
    ) async -> UUID? {
        if let builder = preferBuilder {
            do {
                if activeEnergyKcal > 0,
                   let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal)
                    let sample = HKCumulativeQuantitySample(
                        type: energyType,
                        quantity: quantity,
                        start: start,
                        end: end
                    )
                    try await builder.addSamples([sample])
                }
                try await builder.endCollection(at: end)
                if let workout = try await builder.finishWorkout() {
                    liveBuilder = nil
                    return workout.uuid
                }
            } catch {
                lastError = error.localizedDescription
                liveBuilder = nil
            }
        }

        // Fallback: builder nuevo
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if activeEnergyKcal > 0,
               let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal)
                let sample = HKCumulativeQuantitySample(
                    type: energyType,
                    quantity: quantity,
                    start: start,
                    end: end
                )
                try await builder.addSamples([sample])
            }
            try await builder.addMetadata([
                HKMetadataKeyWorkoutBrandName: "Gymbro",
                "GymbroTitle": title,
            ])
            try await builder.endCollection(at: end)
            let workout = try await builder.finishWorkout()
            return workout?.uuid
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func discardLocalBuilder() async {
        guard let builder = liveBuilder else { return }
        liveBuilder = nil
        builder.discardWorkout()
    }

    // MARK: - Today aggregates

    private func fetchLatestWeight() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                Task { @MainActor in
                    if let sample = samples?.first as? HKQuantitySample {
                        self.latestWeightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                        self.latestWeightDate = sample.endDate
                    }
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }

    private func workoutMinutes(from start: Date, to end: Date) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { (cont: CheckedContinuation<Double, Never>) in
            let q = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let total = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration } ?? 0
                cont.resume(returning: total / 60.0)
            }
            store.execute(q)
        }
    }

    private func fetchActiveEnergyToday() async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                Task { @MainActor in
                    self.activeEnergyTodayKcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie())
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }

    private func fetchWorkoutMinutesToday() async {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                Task { @MainActor in
                    let total = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration } ?? 0
                    self.workoutMinutesToday = total / 60.0
                    cont.resume()
                }
            }
            store.execute(q)
        }
    }
}
