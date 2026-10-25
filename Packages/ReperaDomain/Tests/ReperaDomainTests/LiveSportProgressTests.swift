import Foundation
import Testing
@testable import ReperaDomain

@Suite("Comenzar - métricas reales de Progreso")
struct LiveSportProgressTests {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func activity(
        _ sportID: String,
        duration: TimeInterval = 1800,
        meters: Double? = 5000
    ) -> WorkoutSession {
        WorkoutSession(
            title: sportID,
            exercises: [],
            phase: .finished,
            startedAt: now.addingTimeInterval(-duration),
            finishedAt: now,
            liveSportID: sportID,
            recordedDistanceMeters: meters,
            activeDurationSeconds: duration
        )
    }

    @Test func runningWithoutIndividualExercisesCountsAsCardioAndTraining() {
        let run = activity("running")
        #expect(run.exercises.isEmpty)
        #expect(StatsEngine.isCardioWorkout(run))
        let summary = StatsEngine.progressHealthSummary(
            workouts: [run], range: .today, now: now
        )
        #expect(summary.sessionCount == 1)
        #expect(summary.averageMinutes == 30)
        #expect(summary.averageCardioMinutes == 30)
        #expect(summary.totalKcal == 0) // No inventar sensores.
        let series = StatsEngine.dailyMetricSeries(
            workouts: [run], metric: .cardioMinutes, range: .today, now: now
        )
        #expect(series.reduce(0) { $0 + $1.value } == 30)
    }

    @Test func indoorStrengthDoesNotBecomeCardioArtificially() {
        let strength = activity("strength", meters: nil)
        #expect(!StatsEngine.isCardioWorkout(strength))
        let summary = StatsEngine.progressHealthSummary(
            workouts: [strength], range: .today, now: now
        )
        #expect(summary.sessionCount == 1)
        #expect(summary.averageMinutes == 30)
        #expect(summary.averageCardioMinutes == nil)
    }

    @Test func outdoorSportsCountInCardioMinutes() {
        for sport in ["running", "cycling", "walking", "hiking", "trail",
                      "mountainBike", "gravel", "tennis", "padel", "surfing",
                      "swimming", "skiing", "hiit", "hyrox"] {
            #expect(StatsEngine.isCardioWorkout(activity(sport)))
        }
    }

    @Test func newWaterWinterTeamAndOtherSportsContributeCardioMinutes() {
        let sports = [
            "windsurfing", "kitesurfing", "kayaking", "rowing", "canoeing",
            "sailing", "iceSkating", "snowboarding", "crossCountrySkiing",
            "soccer", "basketball", "volleyball", "climbing", "dance",
            "skateboarding"
        ]
        for sport in sports {
            let item = activity(sport, duration: 1200, meters: nil)
            #expect(StatsEngine.isCardioWorkout(item), "Falta cardio para \(sport)")
            let summary = StatsEngine.progressHealthSummary(
                workouts: [item], range: .today, now: now
            )
            #expect(summary.averageCardioMinutes == 20)
            #expect(summary.totalKcal == 0) // Salud no aportó sensores.
        }
    }

    @Test func pilatesDoesNotInventDistanceOrCardioLoad() {
        let item = activity("pilates", duration: 2400, meters: nil)
        #expect(!StatsEngine.isCardioWorkout(item))
        #expect(item.recordedDistanceMeters == nil)
        #expect(item.appleAverageHeartRateBpm == nil)
        #expect(item.appleActiveEnergyKcal == nil)
    }

    @Test func liveAndPlannedSessionsShareExistingProgressMetrics() {
        let timestamp = Calendar.current.startOfDay(for: now).addingTimeInterval(15 * 3600)
        let planned = WorkoutSession(
            title: "Entrenamiento programado",
            exercises: [],
            phase: .finished,
            startedAt: timestamp.addingTimeInterval(-3600),
            finishedAt: timestamp,
            activeDurationSeconds: 3600
        )
        let live = WorkoutSession(
            title: "Ciclismo de carretera",
            exercises: [],
            phase: .finished,
            startedAt: timestamp.addingTimeInterval(-1200),
            finishedAt: timestamp,
            liveSportID: "cycling",
            recordedDistanceMeters: 6500,
            activeDurationSeconds: 1200
        )
        let combined = [planned, live]
        let summary = StatsEngine.progressHealthSummary(
            workouts: combined, range: .today, now: timestamp
        )
        #expect(summary.sessionCount == 2)
        #expect(summary.averageMinutes == 40)
        #expect(summary.averageCardioMinutes == 20)
        #expect(summary.totalKcal == 0)

        let activity = StatsEngine.dailyActivity(workouts: combined)
        #expect(activity.count == 1)
        #expect(activity.values.first?.sessionCount == 2)
        #expect(activity.values.first?.minutes == 80)

        let cardio = StatsEngine.dailyMetricSeries(
            workouts: combined, metric: .cardioMinutes,
            range: .today, now: timestamp
        )
        #expect(cardio.reduce(0) { $0 + $1.value } == 20)
    }

    @Test func liveMidnightSessionUsesSameDayInHeatmapAndRangeFilter() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = calendar.startOfDay(for: now)
        let session = WorkoutSession(
            title: "Carrera nocturna",
            exercises: [],
            phase: .finished,
            startedAt: midnight.addingTimeInterval(-120),
            finishedAt: midnight.addingTimeInterval(120),
            liveSportID: "running",
            activeDurationSeconds: 240
        )
        let heatmap = StatsEngine.dailyActivity(workouts: [session], calendar: calendar)
        #expect(heatmap.count == 1)
        #expect(heatmap.values.first?.date == midnight.addingTimeInterval(-86400))
        #expect(heatmap.values.first?.sessionCount == 1)
        #expect(StatsEngine.filterWorkouts(
            [session], range: .today,
            now: midnight.addingTimeInterval(-30), calendar: calendar
        ).count == 1)
    }

    @Test func liveActivityUsesStartDayForProgressRange() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = cal.startOfDay(for: now)
        let session = WorkoutSession(
            title: "Carrera antes de medianoche",
            exercises: [],
            phase: .finished,
            startedAt: midnight.addingTimeInterval(-120),
            finishedAt: midnight.addingTimeInterval(120),
            liveSportID: "running",
            activeDurationSeconds: 240
        )
        let previous = midnight.addingTimeInterval(-30)
        let filtered = StatsEngine.filterWorkouts(
            [session], range: .today, now: previous, calendar: cal
        )
        #expect(filtered.count == 1)
    }
}
