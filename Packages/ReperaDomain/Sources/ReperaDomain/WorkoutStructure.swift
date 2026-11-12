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

/// Advanced methods belong to the series/phase prescription, not a separate
/// workout format. Existing WODFormat, tempo timers and set logging remain intact.
public enum WorkoutSetMethod: String, Codable, Sendable, Hashable, CaseIterable {
    case standard, superset, triset, giantSet, cluster, dropSet, restPause, tempo, isometric
}

/// Optional metadata for an advanced strength group. It must never manufacture
/// completed sets or infer a load from a percent of one-rep max.
public struct WorkoutStrengthTechnique: Codable, Sendable, Hashable {
    public var method: WorkoutSetMethod
    public var tempo: String?
    public var pauseSeconds: Int?
    public var intraSetRestSeconds: Int?
    public var clusterReps: Int?
    public var dropPercentages: [Double]

    public init(method: WorkoutSetMethod, tempo: String? = nil,
                pauseSeconds: Int? = nil, intraSetRestSeconds: Int? = nil,
                clusterReps: Int? = nil, dropPercentages: [Double] = []) {
        self.method = method
        self.tempo = tempo
        self.pauseSeconds = pauseSeconds
        self.intraSetRestSeconds = intraSetRestSeconds
        self.clusterReps = clusterReps
        self.dropPercentages = dropPercentages
    }

    public var isValid: Bool {
        if let tempo, tempo.range(of: #"^[0-9Xx]{4}$"#, options: .regularExpression) == nil {
            return false
        }
        if let pauseSeconds, !(0...300).contains(pauseSeconds) { return false }
        if let intraSetRestSeconds, !(0...300).contains(intraSetRestSeconds) { return false }
        if let clusterReps, !(1...100).contains(clusterReps) { return false }
        return dropPercentages.count <= 8 && dropPercentages.allSatisfy { $0.isFinite && (0...100).contains($0) }
    }
}

/// One recorded outcome for one phase/interval and, optionally, one athlete.
/// Both athletes can have distinct results without inventing separate exercises.
public struct WorkoutPhaseResult: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID
    public var phaseID: UUID
    public var iteration: Int
    /// 1 = first participant, 2 = second participant, nil = shared result.
    public var participantIndex: Int?
    public var movementID: UUID?
    public var completedReps: Int?
    public var roundsCompleted: Int?
    public var elapsedSeconds: Int?
    public var measuredValue: Double?
    public var measuredMetric: WorkoutResultMetric?
    public var notes: String?

    public init(id: UUID = UUID(), phaseID: UUID, iteration: Int,
                participantIndex: Int? = nil, movementID: UUID? = nil,
                completedReps: Int? = nil, roundsCompleted: Int? = nil,
                elapsedSeconds: Int? = nil, measuredValue: Double? = nil,
                measuredMetric: WorkoutResultMetric? = nil, notes: String? = nil) {
        self.id = id
        self.phaseID = phaseID
        self.iteration = iteration
        self.participantIndex = participantIndex
        self.movementID = movementID
        self.completedReps = completedReps
        self.roundsCompleted = roundsCompleted
        self.elapsedSeconds = elapsedSeconds
        self.measuredValue = measuredValue
        self.measuredMetric = measuredMetric
        self.notes = notes
    }

    public var isValid: Bool {
        iteration > 0 && iteration <= 200 &&
        (participantIndex == nil || participantIndex == 1 || participantIndex == 2) &&
        (completedReps == nil || (0...100_000).contains(completedReps!)) &&
        (roundsCompleted == nil || (0...10_000).contains(roundsCompleted!)) &&
        (elapsedSeconds == nil || (0...86_400).contains(elapsedSeconds!)) &&
        (measuredValue == nil || (measuredValue!.isFinite && (0...1_000_000).contains(measuredValue!))) &&
        (measuredValue == nil || measuredMetric != nil)
    }
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
    public var technique: WorkoutStrengthTechnique?
    public var children: [WorkoutPhase]

    public init(id: UUID = UUID(), kind: WorkoutPhaseKind, title: String,
                movementIDs: [UUID] = [], repeatCount: Int? = nil,
                workSeconds: Int? = nil, restSeconds: Int? = nil,
                notes: String? = nil, technique: WorkoutStrengthTechnique? = nil,
                children: [WorkoutPhase] = []) {
        self.id = id
        self.kind = kind
        self.title = title
        self.movementIDs = movementIDs
        self.repeatCount = repeatCount
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.notes = notes
        self.technique = technique
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
        let available = Set(block.movements.map(\.id) + block.exercises.map(\.id))
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
