import Foundation
import Testing
@testable import ReperaDomain

@Suite("SessionCardioEffort")
struct SessionCardioEffortTests {
    @Test func hardEffortRaisesLowScore() {
        let sample = SessionCardioSample(
            averageHeartRateBpm: 165,
            maxHeartRateBpm: 185,
            durationMinutes: 20
        )
        let analyzed = SessionCardioEffort.analyze(sample)
        #expect(analyzed != nil)
        #expect(analyzed?.band == .hard)
        let delta = SessionCardioEffort.scoreDelta(baseScore: 5, adjustment: analyzed!)
        #expect(delta == 1)
    }

    @Test func easyEffortLowersHighScore() {
        let sample = SessionCardioSample(
            averageHeartRateBpm: 105,
            maxHeartRateBpm: 120,
            durationMinutes: 40
        )
        let analyzed = SessionCardioEffort.analyze(sample)!
        #expect(analyzed.band == .easy)
        let delta = SessionCardioEffort.scoreDelta(baseScore: 9, adjustment: analyzed)
        #expect(delta == -2)
    }

    @Test func applyUpdatesReviewText() {
        let base = SessionReview(
            overallScore: 5,
            level: .intermediate,
            headline: "Fran: Intermedio · 5/10",
            vsStandardSummary: "Tu tiempo fue 8:30."
        )
        let sample = SessionCardioSample(
            averageHeartRateBpm: 170,
            maxHeartRateBpm: 188,
            heartRateBpmSamples: Array(repeating: 172, count: 20),
            durationMinutes: 9
        )
        let updated = SessionCardioEffort.apply(to: base, sample: sample)
        #expect(updated.overallScore > base.overallScore)
        #expect(updated.vsStandardSummary?.contains("FC media") == true)
    }

    @Test func reviewEngineUsesCardioWhenProvided() {
        let session = makeFranSession(elapsedSeconds: 8 * 60)
        let without = SessionReviewEngine.review(session: session, history: [])
        let with = SessionReviewEngine.review(
            session: session,
            history: [],
            cardio: SessionCardioSample(
                averageHeartRateBpm: 175,
                maxHeartRateBpm: 190,
                heartRateBpmSamples: Array(repeating: 178, count: 30),
                durationMinutes: 8
            )
        )
        #expect(without != nil)
        #expect(with != nil)
        #expect((with?.overallScore ?? 0) >= (without?.overallScore ?? 0) - 1)
        #expect(with?.vsStandardSummary?.contains("FC media") == true)
    }

    private func makeFranSession(elapsedSeconds: Int) -> WorkoutSession {
        var session = WorkoutSession(title: "Fran", exercises: [])
        session.phase = .finished
        session.startedAt = Date().addingTimeInterval(-TimeInterval(elapsedSeconds))
        session.finishedAt = Date()
        session.wodResults = [
            WODBlockResult(
                id: UUID(),
                format: .forTime,
                elapsedSeconds: elapsedSeconds,
                wodTemplateId: "fran"
            )
        ]
        return session
    }
}
