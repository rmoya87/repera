import Foundation

public enum ScheduleMode: String, Codable, Sendable, CaseIterable {
    case fixedWeek
    case rotation

    public var displayName: String {
        switch self {
        case .fixedWeek: "Semana fija"
        case .rotation: "Rotación A→B→C"
        }
    }
}

/// Cola de rutinas en orden. El siguiente entreno es `routineIds[nextIndex]`.
public struct RotationPlan: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var label: String
    public var routineIds: [UUID]
    public var nextIndex: Int

    public init(
        id: UUID = UUID(),
        label: String = "Mi rotación",
        routineIds: [UUID] = [],
        nextIndex: Int = 0
    ) {
        self.id = id
        self.label = label
        self.routineIds = routineIds
        self.nextIndex = nextIndex
    }

    public var nextRoutineId: UUID? {
        guard !routineIds.isEmpty else { return nil }
        let idx = ((nextIndex % routineIds.count) + routineIds.count) % routineIds.count
        return routineIds[idx]
    }

    public mutating func advance() {
        guard !routineIds.isEmpty else { return }
        nextIndex = (nextIndex + 1) % routineIds.count
    }

    public mutating func move(from: Int, to: Int) {
        guard routineIds.indices.contains(from), routineIds.indices.contains(to) else { return }
        let item = routineIds.remove(at: from)
        routineIds.insert(item, at: to)
        nextIndex = min(nextIndex, max(0, routineIds.count - 1))
    }
}

public enum RotationEngine {
    public static func nextRoutine(state: AppState) -> Routine? {
        guard state.settings.scheduleMode == .rotation,
              let rotation = state.rotation,
              let id = rotation.nextRoutineId
        else { return nil }
        return state.routines.first { $0.id == id }
    }

    public static func queueView(state: AppState) -> [(routine: Routine, isNext: Bool)] {
        guard let rotation = state.rotation, !rotation.routineIds.isEmpty else { return [] }
        let nextIdx = ((rotation.nextIndex % rotation.routineIds.count) + rotation.routineIds.count)
            % rotation.routineIds.count
        return rotation.routineIds.enumerated().compactMap { index, id in
            guard let routine = state.routines.first(where: { $0.id == id }) else { return nil }
            return (routine, index == nextIdx)
        }
    }
}
