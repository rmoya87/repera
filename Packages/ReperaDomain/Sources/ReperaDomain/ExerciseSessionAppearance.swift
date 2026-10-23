import Foundation

/// Cómo apareció un ejercicio / WOD en un entreno concreto.
public struct ExerciseSessionAppearance: Sendable, Equatable {
    public var sessionId: UUID
    public var date: Date
    public var sessionTitle: String
    /// Series de trabajo apuntadas.
    public var setLines: [String]
    /// Prescripción del movimiento (RFT/AMRAP sin series por movimiento).
    public var prescriptionLine: String?
    /// Marca del bloque (tiempo / rondas).
    public var wodScoreLabel: String?
    public var wodFormatName: String?
    /// Benchmark de catálogo (`CatalogWODs`); si hay, la comparación es del WOD global.
    public var wodTemplateId: String?
    public var wodTemplateName: String?
    /// `true` = marca del WOD entero (Fran, Cindy…), no del movimiento suelto.
    public var isGlobalWodScore: Bool

    public init(
        sessionId: UUID,
        date: Date,
        sessionTitle: String,
        setLines: [String] = [],
        prescriptionLine: String? = nil,
        wodScoreLabel: String? = nil,
        wodFormatName: String? = nil,
        wodTemplateId: String? = nil,
        wodTemplateName: String? = nil,
        isGlobalWodScore: Bool = false
    ) {
        self.sessionId = sessionId
        self.date = date
        self.sessionTitle = sessionTitle
        self.setLines = setLines
        self.prescriptionLine = prescriptionLine
        self.wodScoreLabel = wodScoreLabel
        self.wodFormatName = wodFormatName
        self.wodTemplateId = wodTemplateId
        self.wodTemplateName = wodTemplateName
        self.isGlobalWodScore = isGlobalWodScore
    }

    public var hasContent: Bool {
        !setLines.isEmpty || prescriptionLine != nil || wodScoreLabel != nil
    }
}

extension StatsEngine {
    /// Aparición del ejercicio en una sesión (id / catalogId / nombre).
    /// Si el bloque es un WOD de catálogo (`wodTemplateId`), la marca es la del WOD global.
    public static func appearance(
        of exerciseId: UUID,
        in session: WorkoutSession,
        catalog: [Exercise] = [],
        templates: [WODTemplate] = CatalogWODs.seed()
    ) -> ExerciseSessionAppearance? {
        let anchor = exerciseAnchor(id: exerciseId, catalog: catalog, workouts: [session])
            ?? catalog.first(where: { $0.id == exerciseId })
        guard let entry = matchingSessionExercise(in: session, exerciseId: exerciseId, anchor: anchor)
            ?? session.exercises.first(where: {
                guard let anchor else { return $0.exercise.id == exerciseId }
                return ExerciseEquivalence.matchesCatalogIdentity($0.exercise, anchor)
            })
        else { return nil }

        let date = session.finishedAt ?? session.startedAt ?? Date()
        let blockResult: WODBlockResult? = {
            if let blockId = entry.blockId {
                return session.wodResults.first(where: { $0.id == blockId })
            }
            return nil
        }()
        let templateId = blockResult?.wodTemplateId
            ?? session.wodResults.first(where: { $0.wodTemplateId != nil })?.wodTemplateId
        let template = templateId.flatMap { id in templates.first { $0.id == id } }

        // WOD predeterminado → comparar el score global del benchmark.
        if let templateId, let result = blockResult ?? session.wodResults.first(where: { $0.wodTemplateId == templateId }) {
            let score = result.summaryLabel
            guard score != "—" else { return nil }
            return ExerciseSessionAppearance(
                sessionId: session.id,
                date: date,
                sessionTitle: template?.name ?? session.title,
                setLines: [],
                prescriptionLine: nil,
                wodScoreLabel: score,
                wodFormatName: result.format?.displayName ?? template?.format.displayName ?? entry.wodFormat?.displayName,
                wodTemplateId: templateId,
                wodTemplateName: template?.name ?? session.title,
                isGlobalWodScore: true
            )
        }

        let work = effectiveWorkSets(entry, in: session)
        let setLines = work.map(\.displaySummaryLine)

        var scoreLabel: String?
        var formatName: String?
        if let result = blockResult {
            scoreLabel = result.summaryLabel
            formatName = result.format?.displayName ?? entry.wodFormat?.displayName
        } else if entry.usesBlockScoreResult {
            formatName = entry.wodFormat?.displayName
        }

        let prescription: String? = {
            if !setLines.isEmpty { return nil }
            let line = entry.prescriptionSummaryLine
            return line == entry.exercise.name ? nil : line
        }()

        let appearance = ExerciseSessionAppearance(
            sessionId: session.id,
            date: date,
            sessionTitle: session.title,
            setLines: setLines,
            prescriptionLine: prescription,
            wodScoreLabel: scoreLabel,
            wodFormatName: formatName,
            isGlobalWodScore: false
        )
        return appearance.hasContent ? appearance : nil
    }

    /// Apariciones previas: mismo WOD de catálogo, o mismo movimiento si es WOD libre / series.
    public static func priorAppearances(
        of exerciseId: UUID,
        workouts: [WorkoutSession],
        catalog: [Exercise] = [],
        excludingSessionId: UUID? = nil,
        limit: Int = 5,
        templates: [WODTemplate] = CatalogWODs.seed()
    ) -> [ExerciseSessionAppearance] {
        let sorted = workouts.sorted {
            ($0.finishedAt ?? $0.startedAt ?? .distantPast) > ($1.finishedAt ?? $1.startedAt ?? .distantPast)
        }

        // Si la sesión destacada es un benchmark, comparar solo ese template.
        let highlightTemplateId: String? = {
            guard let excludingSessionId,
                  let session = workouts.first(where: { $0.id == excludingSessionId }),
                  let row = appearance(
                    of: exerciseId,
                    in: session,
                    catalog: catalog,
                    templates: templates
                  ),
                  row.isGlobalWodScore
            else { return nil }
            return row.wodTemplateId
        }()

        var rows: [ExerciseSessionAppearance] = []
        for session in sorted {
            if let excludingSessionId, session.id == excludingSessionId { continue }
            guard session.finishedAt != nil || session.phase == .finished else { continue }

            if let highlightTemplateId {
                guard let row = wodTemplateAppearance(
                    templateId: highlightTemplateId,
                    in: session,
                    templates: templates
                ) else { continue }
                rows.append(row)
            } else {
                guard let row = appearance(
                    of: exerciseId,
                    in: session,
                    catalog: catalog,
                    templates: templates
                ), !row.isGlobalWodScore else { continue }
                rows.append(row)
            }
            if rows.count >= limit { break }
        }
        return rows
    }

    /// Marca global de un WOD de catálogo en una sesión.
    public static func wodTemplateAppearance(
        templateId: String,
        in session: WorkoutSession,
        templates: [WODTemplate] = CatalogWODs.seed()
    ) -> ExerciseSessionAppearance? {
        guard let result = session.wodResults.first(where: { $0.wodTemplateId == templateId }) else {
            return nil
        }
        let score = result.summaryLabel
        guard score != "—" else { return nil }
        let template = templates.first { $0.id == templateId }
        let date = session.finishedAt ?? session.startedAt ?? Date()
        return ExerciseSessionAppearance(
            sessionId: session.id,
            date: date,
            sessionTitle: template?.name ?? session.title,
            wodScoreLabel: score,
            wodFormatName: result.format?.displayName ?? template?.format.displayName,
            wodTemplateId: templateId,
            wodTemplateName: template?.name ?? session.title,
            isGlobalWodScore: true
        )
    }
}
