import Foundation
import Testing
@testable import ReperaDomain

@Suite("Temporizador guardado")
struct TimerCompletionDetailsTests {
    @Test("Sesión de temporizador conserva la fecha, duración, identidad y configuración")
    func timerWorkoutRoundTrip() throws {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let finish = start.addingTimeInterval(92)
        let details = TimerCompletionDetails(
            modeRaw: "intervals", configuredSeconds: 90, rounds: 3,
            workSeconds: 30, restSeconds: 0, countdownSeconds: 3
        )
        let session = WorkoutSession(
            title: "Temporizador · Intervalos",
            exercises: [],
            phase: .finished,
            startedAt: start,
            finishedAt: finish,
            timerDetails: details
        )
        let restored = try JSONDecoder().decode(
            WorkoutSession.self, from: JSONEncoder().encode(session)
        )
        #expect(restored.id == session.id)
        #expect(restored.startedAt == start)
        #expect(restored.finishedAt == finish)
        #expect(restored.phase == .finished)
        #expect(restored.timerDetails == details)
        #expect(restored.timerDetails?.modeTitle == "Intervalos")
        #expect(abs(restored.displayDurationMinutes - 1.5) < 0.001)
        #expect(restored.healthKitWorkoutUUID == nil)
        #expect(restored.appleActiveEnergyKcal == nil)
    }

    @Test("Sesiones anteriores siguen decodificando sin detalles de temporizador")
    func legacyWorkoutCompatibility() throws {
        let old = WorkoutSession(
            title: "Fuerza", exercises: [], phase: .finished,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            finishedAt: Date(timeIntervalSince1970: 1_700_000_060)
        )
        let data = try JSONEncoder().encode(old)
        let restored = try JSONDecoder().decode(WorkoutSession.self, from: data)
        #expect(restored.timerDetails == nil)
        #expect(restored.id == old.id)
    }
}
