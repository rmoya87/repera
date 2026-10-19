import Foundation
import GymbroDomain

/// Series de Progreso ya filtradas/agregadas (listas para Chart). Se construyen fuera del `body`.
struct ProgressPreparedCharts: Equatable, Sendable {
    var range: ProgressTimeRange
    var weekStartsOnMonday: Bool
    var heartRate: [HeartRatePlotPoint]
    var calories: [ProgressDayPoint]
    var caloriesTotal: Double
    var averageHeartRate: Double?
    var granularity: ProgressSeriesGranularity

    struct HeartRatePlotPoint: Identifiable, Equatable, Sendable {
        var id: Date { date }
        var date: Date
        var minBpm: Double
        var avgBpm: Double
        var maxBpm: Double
    }

    static let empty = ProgressPreparedCharts(
        range: .week,
        weekStartsOnMonday: true,
        heartRate: [],
        calories: [],
        caloriesTotal: 0,
        averageHeartRate: nil,
        granularity: .day
    )
}

enum ProgressChartBuilder {
    /// Máximo de puntos en el Chart (más = más lento con catmullRom).
    static let maxPlotPoints = 48

    static func build(
        range: ProgressTimeRange,
        weekStartsOnMonday: Bool,
        heartRateDays: [HealthKitStore.DailyHeartRatePoint],
        energyDays: [HealthKitStore.DailyActiveEnergyPoint],
        workouts: [WorkoutSession],
        external: [ExternalDaySample],
        now: Date = Date()
    ) -> ProgressPreparedCharts {
        let t0 = CFAbsoluteTimeGetCurrent()
        let granularity = ProgressSeriesGranularity.forChart(range: range)
        let start = range.startDate(now: now, weekStartsOnMonday: weekStartsOnMonday)
            ?? Calendar.current.startOfDay(for: now)
        let endExclusive = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: now)
        ) ?? now

        // Filtro por timestamps (evita Calendar en cada punto vía `range.contains`).
        let hrRaw = heartRateDays.filter { $0.date >= start && $0.date < endExclusive }
            .sorted { $0.date < $1.date }
        let energyRaw = energyDays.filter { $0.date >= start && $0.date < endExclusive }

        let hrAgg = aggregateHeartRate(hrRaw, granularity: granularity, weekStartsOnMonday: weekStartsOnMonday)
        let hrPlot = downsample(hrAgg, maxCount: maxPlotPoints)

        let kcalDaily = mergedDailyCalories(
            energyDays: energyRaw,
            workouts: workouts,
            external: external,
            start: start,
            endExclusive: endExclusive
        )
        let kcalTotal = kcalDaily.reduce(0.0) { $0 + $1.value }
        let kcalAgg = StatsEngine.averagedSeries(
            kcalDaily,
            granularity: granularity,
            weekStartsOnMonday: weekStartsOnMonday
        )
        let kcalPlot = downsample(kcalAgg, maxCount: maxPlotPoints)

        let avgHr: Double? = hrRaw.isEmpty
            ? nil
            : hrRaw.map(\.avgBpm).reduce(0, +) / Double(hrRaw.count)

        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        ProgressLog.info(
            String(
                format: "prepare \(range.rawValue) hrIn=%d hrOut=%d kcalIn=%d kcalOut=%d %.1fms",
                hrRaw.count, hrPlot.count, kcalDaily.count, kcalPlot.count, ms
            )
        )

        return ProgressPreparedCharts(
            range: range,
            weekStartsOnMonday: weekStartsOnMonday,
            heartRate: hrPlot,
            calories: kcalPlot,
            caloriesTotal: kcalTotal,
            averageHeartRate: avgHr,
            granularity: granularity
        )
    }

    /// Misma regla que Inicio: por día `max(energía activa Salud, suma chips Gymbro + externos)`.
    static func mergedDailyCalories(
        energyDays: [HealthKitStore.DailyActiveEnergyPoint],
        workouts: [WorkoutSession],
        external: [ExternalDaySample],
        start: Date,
        endExclusive: Date
    ) -> [ProgressDayPoint] {
        let df = dayKeyFormatter
        let cal = Calendar.current

        var healthByDay: [String: (date: Date, kcal: Double)] = [:]
        for day in energyDays {
            let dayStart = cal.startOfDay(for: day.date)
            guard dayStart >= start, dayStart < endExclusive else { continue }
            let key = df.string(from: dayStart)
            let prev = healthByDay[key]?.kcal ?? 0
            healthByDay[key] = (dayStart, prev + max(0, day.kcal))
        }

        var cardsByDay: [String: (date: Date, kcal: Double)] = [:]
        for workout in workouts {
            guard let raw = workout.finishedAt ?? workout.startedAt else { continue }
            let dayStart = cal.startOfDay(for: raw)
            guard dayStart >= start, dayStart < endExclusive else { continue }
            let key = df.string(from: dayStart)
            let add = max(0, workout.appleActiveEnergyKcal ?? 0)
            guard add > 0 else { continue }
            let prev = cardsByDay[key]?.kcal ?? 0
            cardsByDay[key] = (dayStart, prev + add)
        }
        for sample in external {
            let dayStart = cal.startOfDay(for: sample.date)
            guard dayStart >= start, dayStart < endExclusive else { continue }
            let key = df.string(from: dayStart)
            let add = max(0, sample.activeEnergyKcal)
            guard add > 0 else { continue }
            let prev = cardsByDay[key]?.kcal ?? 0
            cardsByDay[key] = (dayStart, prev + add)
        }

        var buckets: [String: ProgressDayPoint] = [:]
        for key in Set(healthByDay.keys).union(cardsByDay.keys) {
            let health = healthByDay[key]?.kcal ?? 0
            let cards = cardsByDay[key]?.kcal ?? 0
            let value = max(health, cards)
            guard value > 0 else { continue }
            let date = healthByDay[key]?.date ?? cardsByDay[key]?.date ?? start
            buckets[key] = ProgressDayPoint(dayKey: key, date: date, value: value)
        }
        return buckets.values.sorted { $0.date < $1.date }
    }

    private static func aggregateHeartRate(
        _ raw: [HealthKitStore.DailyHeartRatePoint],
        granularity: ProgressSeriesGranularity,
        weekStartsOnMonday: Bool
    ) -> [ProgressPreparedCharts.HeartRatePlotPoint] {
        let mapped = raw.map {
            ProgressPreparedCharts.HeartRatePlotPoint(
                date: $0.date,
                minBpm: $0.minBpm,
                avgBpm: $0.avgBpm,
                maxBpm: $0.maxBpm
            )
        }
        guard granularity != .day, mapped.count > 1 else { return mapped }

        var cal = Calendar.current
        cal.firstWeekday = weekStartsOnMonday ? 2 : 1
        struct Acc {
            var date: Date
            var minSum: Double
            var avgSum: Double
            var maxSum: Double
            var count: Int
        }
        var groups: [String: Acc] = [:]
        for p in mapped {
            let day = cal.startOfDay(for: p.date)
            let key: String
            let bucketStart: Date
            switch granularity {
            case .day:
                key = "\(day.timeIntervalSince1970)"
                bucketStart = day
            case .week:
                let week = cal.component(.weekOfYear, from: day)
                let year = cal.component(.yearForWeekOfYear, from: day)
                key = "\(year)-W\(week)"
                bucketStart = StatsEngine.startOfWeek(containing: day, calendar: cal)
            case .month:
                let comps = cal.dateComponents([.year, .month], from: day)
                key = String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
                bucketStart = cal.date(from: comps) ?? day
            }
            var acc = groups[key] ?? Acc(date: bucketStart, minSum: 0, avgSum: 0, maxSum: 0, count: 0)
            acc.minSum += p.minBpm
            acc.avgSum += p.avgBpm
            acc.maxSum += p.maxBpm
            acc.count += 1
            if bucketStart < acc.date { acc.date = bucketStart }
            groups[key] = acc
        }
        return groups.values
            .map { acc in
                let n = Double(max(1, acc.count))
                return ProgressPreparedCharts.HeartRatePlotPoint(
                    date: acc.date,
                    minBpm: acc.minSum / n,
                    avgBpm: acc.avgSum / n,
                    maxBpm: acc.maxSum / n
                )
            }
            .sorted { $0.date < $1.date }
    }

    private static func downsample(
        _ points: [ProgressPreparedCharts.HeartRatePlotPoint],
        maxCount: Int
    ) -> [ProgressPreparedCharts.HeartRatePlotPoint] {
        guard points.count > maxCount, maxCount > 2 else { return points }
        let step = Double(points.count - 1) / Double(maxCount - 1)
        return (0..<maxCount).map { i in
            points[min(points.count - 1, Int((Double(i) * step).rounded()))]
        }
    }

    private static func downsample(
        _ points: [ProgressDayPoint],
        maxCount: Int
    ) -> [ProgressDayPoint] {
        guard points.count > maxCount, maxCount > 2 else { return points }
        let step = Double(points.count - 1) / Double(maxCount - 1)
        return (0..<maxCount).map { i in
            points[min(points.count - 1, Int((Double(i) * step).rounded()))]
        }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar.current
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = Calendar.current.timeZone
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
