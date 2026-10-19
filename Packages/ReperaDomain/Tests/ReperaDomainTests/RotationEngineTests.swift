import Testing
@testable import ReperaDomain

struct RotationEngineTests {
    @Test func advancesRoundRobin() {
        let a = Routine(title: "A")
        let b = Routine(title: "B")
        let c = Routine(title: "C")
        var rotation = RotationPlan(routineIds: [a.id, b.id, c.id], nextIndex: 0)
        var state = AppState(routines: [a, b, c], rotation: rotation)
        state.settings.scheduleMode = .rotation

        #expect(RotationEngine.nextRoutine(state: state)?.title == "A")
        rotation.advance()
        state.rotation = rotation
        #expect(RotationEngine.nextRoutine(state: state)?.title == "B")
        rotation.advance()
        state.rotation = rotation
        #expect(RotationEngine.nextRoutine(state: state)?.title == "C")
        rotation.advance()
        state.rotation = rotation
        #expect(RotationEngine.nextRoutine(state: state)?.title == "A")
    }

    @Test func queueMarksNext() {
        let a = Routine(title: "A")
        let b = Routine(title: "B")
        var state = AppState(
            routines: [a, b],
            rotation: RotationPlan(routineIds: [a.id, b.id], nextIndex: 1)
        )
        state.settings.scheduleMode = .rotation
        let queue = RotationEngine.queueView(state: state)
        #expect(queue.count == 2)
        #expect(queue[0].isNext == false)
        #expect(queue[1].isNext == true)
        #expect(queue[1].routine.title == "B")
    }
}
