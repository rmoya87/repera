import Foundation

/// Additional semantics of an existing workout block. This is NOT another
/// WODFormat: AMRAP, For Time, EMOM, etc. remain stable for old plans/players.
public enum WorkoutSection: String, Codable, Sendable, Hashable {
    case warmUp, strength, skill, metcon, accessory, coolDown
}

public enum WorkoutCollaboration: String, Codable, Sendable, Hashable {
    case solo, youGoIGo, synchronized, sharedReps, together
}

public enum WorkoutResultMetric: String, Codable, Sendable, Hashable {
    case elapsedSeconds, totalReps, loadKg, calories, distanceMeters, rounds, perMovementSets
}

public enum WorkoutPhaseKind: String, Codable, Sendable, Hashable {
    case work, rest, buyIn, main, cashOut
}

/// A phase can describe repeated work/rest cycles without cloning movements.
/// movementIDs refer to UUIDs in the owning RoutineBlock, not another catalog.
public struct WorkoutPhase: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var kind: WorkoutPhaseKind
    public var title: String
    public var movementIDs: [UUID]
    public var repeatCount: Int?
    public var workSeconds: Int?
    public var restSeconds: Int?
    public var notes: String?
    public var children: [WorkoutPhase]

    public init(id: UUID = UUID(), kind: WorkoutPhaseKind, title: String,
                movementIDs: [UUID] = [], repeatCount: Int? = nil,
                workSeconds: Int? = nil, restSeconds: Int? = nil,
                notes: String? = nil, children: [WorkoutPhase] = []) {
        self.id = id
        self.kind = kind
        self.title = title
        self.movementIDs = movementIDs
        self.repeatCount = repeatCount
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.notes = notes
        self.children = children
    }
}

public struct WorkoutStructure: Codable, Sendable, Hashable {
    public var version: Int
    public var section: WorkoutSection?
    public var collaboration: WorkoutCollaboration?
    public var resultMetric: WorkoutResultMetric?
    public var phases: [WorkoutPhase]

    public init(version: Int = 1, section: WorkoutSection? = nil,
                collaboration: WorkoutCollaboration? = nil,
                resultMetric: WorkoutResultMetric? = nil,
                phases: [WorkoutPhase] = []) {
        self.version = version
        self.section = section
        self.collaboration = collaboration
        self.resultMetric = resultMetric
        self.phases = phases
    }

    /// Never mutate source exercises just because a referenced movement was
    /// deleted in Create/Edit. Consumers ignore stale IDs instead.
    public func activeMovementIDs(in block: RoutineBlock) -> Set<UUID> {
        let available = Set(block.movements.map(\.id))
        func collect(_ nodes: [WorkoutPhase]) -> Set<UUID> {
            nodes.reduce(into: Set<UUID>()) { result, phase in
                result.formUnion(phase.movementIDs.filter { available.contains($0) })
                result.formUnion(collect(phase.children))
            }
        }
        return collect(phases)
    }

    /// Duplicating a routine creates new movement UUIDs. Keep phase references
    /// aligned with the duplicated movements rather than pointing at old IDs.
    public func remappingMovementIDs(_ mapping: [UUID: UUID]) -> WorkoutStructure {
        func remap(_ source: WorkoutPhase) -> WorkoutPhase {
            var phase = source
            phase.id = UUID()
            phase.movementIDs = source.movementIDs.compactMap { mapping[$0] }
            phase.children = source.children.map(remap)
            return phase
        }
        var result = self
        result.phases = phases.map(remap)
        return result
    }

    public var summary: String {
        let names = phases.map(\.title).filter { !$0.isEmpty }
        return ([section?.rawValue, collaboration?.rawValue].compactMap { $0 } + names)
            .joined(separator: " · ")
    }
}
