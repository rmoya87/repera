import Foundation

/// Valoración post-WOD: rendimiento (bandas / formato) + historial de ejercicios equivalentes.
public enum SessionReviewEngine {
    public static func review(
        session: WorkoutSession,
        history: [WorkoutSession],
        templates: [WODTemplate] = CatalogWODs.seed(),
        now: Date = Date(),
        cardio: SessionCardioSample? = nil
    ) -> SessionReview? {
        let prior = history.filter { $0.id != session.id }
        let scored = session.wodResults.filter {
            ($0.elapsedSeconds ?? 0) > 0
                || ($0.roundsCompleted ?? 0) > 0
                || ($0.totalReps ?? 0) > 0
        }

        let base: SessionReview?
        if let primary = pickPrimaryResult(scored),
           let built = reviewWOD(
               result: primary,
               session: session,
               prior: prior,
               templates: templates
           ) {
            let movements = reviewMovements(session: session, prior: prior)
            base = merge(built, movements: movements)
        } else {
            let movements = reviewMovements(session: session, prior: prior)
            guard !movements.isEmpty || !session.exercises.filter({ !$0.loggedSets.isEmpty }).isEmpty else {
                return nil
            }
            base = strengthFallback(session: session, movements: movements)
        }

        guard let base else { return nil }
        // Si hay FC/kcal de Salud, afina la nota según el esfuerzo real.
        return SessionCardioEffort.apply(to: base, sample: enrichedCardio(cardio, session: session))
    }

    /// Completa duración/kcal de sesión si el sample no las trae.
    private static func enrichedCardio(
        _ cardio: SessionCardioSample?,
        session: WorkoutSession
    ) -> SessionCardioSample? {
        guard var sample = cardio else {
            // Solo kcal de sesión (sin FC): aún puede aportar señal de densidad.
            guard let kcal = session.appleActiveEnergyKcal, kcal > 40 else { return nil }
            return SessionCardioSample(
                activeEnergyKcal: kcal,
                durationMinutes: max(1, session.displayDurationMinutes)
            )
        }
        if sample.activeEnergyKcal == nil {
            sample.activeEnergyKcal = session.appleActiveEnergyKcal
        }
        if sample.durationMinutes == nil || (sample.durationMinutes ?? 0) <= 0 {
            sample.durationMinutes = max(1, session.displayDurationMinutes)
        }
        return sample
    }

    // MARK: - WOD score

    private static func pickPrimaryResult(_ results: [WODBlockResult]) -> WODBlockResult? {
        if let withTemplate = results.first(where: { $0.wodTemplateId != nil }) {
            return withTemplate
        }
        return results.first
    }

    private static func reviewWOD(
        result: WODBlockResult,
        session: WorkoutSession,
        prior: [WorkoutSession],
        templates: [WODTemplate]
    ) -> SessionReview? {
        let resolvedId = result.wodTemplateId
        let template = resolvedId.flatMap { id in templates.first { $0.id == id } }
        let format = result.format ?? template?.format

        let level: AthleteLevel?
        let score: Int
        let vsStandard: String?
        let basis: ScoreBasis

        if let bands = template?.scoreBands {
            let mapped = mapLevel(result: result, bands: bands, format: format)
            level = mapped.level
            score = mapped.score
            vsStandard = mapped.summary
            basis = .catalogBands
        } else if let paced = scoreFromMovementPace(
            result: result,
            session: session,
            template: template,
            format: format
        ) {
            level = paced.level
            score = paced.score
            vsStandard = paced.summary
            basis = .movementPace
        } else if let typical = template?.typicalMinutes, let elapsed = result.elapsedSeconds, elapsed > 0 {
            let mapped = mapLevelFromTypical(elapsedSeconds: elapsed, typicalMinutes: typical)
            level = mapped.level
            score = mapped.score
            vsStandard = mapped.summary
            basis = .typicalTime
        } else if let mapped = scoreFromFormat(result: result, format: format, typicalMinutes: template?.typicalMinutes) {
            level = mapped.level
            score = mapped.score
            vsStandard = mapped.summary
            basis = .formatHeuristic
        } else {
            return nil
        }

        let historyNote = vsHistory(result: result, templateId: resolvedId, prior: prior)
        let name = template?.name ?? session.title
        let headline: String = {
            if let level {
                return "\(name): \(level.label) · \(score)/10"
            }
            return "\(name): \(score)/10"
        }()

        var keep: [String] = []
        var improve: [String] = []
        if let level {
            switch level {
            case .elite, .advanced:
                keep.append("Vas a ritmo \(level.label.lowercased()). Intenta mantener esa intensidad la próxima vez.")
            case .intermediate:
                keep.append("Buen equilibrio entre ritmo y técnica.")
                improve.append("Acorta las pausas entre movimientos para acercarte al nivel avanzado.")
            case .beginner:
                improve.append("Si se te hace largo, prueba una versión más ligera y prioriza buena técnica.")
                keep.append("Terminar el WOD ya cuenta: guarda la marca para compararla.")
            }
        }
        if let historyNote, historyNote.contains("PR") || historyNote.contains("mejor") {
            keep.append("Nueva mejor marca personal en este WOD.")
        } else if historyNote != nil {
            improve.append("Mira tu marca anterior e intenta mejorar un poco (un 5–10 %).")
        }

        return SessionReview(
            overallScore: score,
            level: level,
            headline: headline,
            vsHistorySummary: historyNote,
            vsStandardSummary: vsStandard,
            keepTips: Array(keep.prefix(2)),
            improveTips: Array(improve.prefix(2)),
            movements: [],
            wodTemplateId: resolvedId,
            scoreBasis: basis
        )
    }

    /// WOD a medida / sin bandas: tiempos esperados por movimiento y nivel (catálogo de ritmos).
    private static func scoreFromMovementPace(
        result: WODBlockResult,
        session: WorkoutSession,
        template: WODTemplate?,
        format: WODFormat?
    ) -> (level: AthleteLevel, score: Int, summary: String)? {
        let byBlock = session.exercises.filter { $0.blockId == result.id }
        let blockExercises = byBlock.isEmpty
            ? session.exercises.filter { $0.blockKind == .wod }
            : byBlock

        var lines = WODPaceEstimator.prescription(fromExercises: blockExercises)
        var volumeFromTemplate = false
        if lines.isEmpty, let template {
            lines = WODPaceEstimator.prescription(fromMovements: template.movements)
            volumeFromTemplate = true
        }
        if lines.isEmpty {
            lines = WODPaceEstimator.prescription(fromExercises: session.exercises)
        }
        guard !lines.isEmpty else { return nil }

        let fmt = format ?? template?.format ?? result.format ?? .forTime
        switch fmt.resultCapture {
        case .elapsedTime:
            guard let elapsed = result.elapsedSeconds, elapsed > 0 else { return nil }
            // Plantilla “3 rounds of…”: multiplicar; sesión ya trae volumen total → 1.
            let roundCount = volumeFromTemplate ? max(1, template?.rounds ?? 1) : 1
            let estimate = WODPaceEstimator.estimateForTime(lines: lines, rounds: roundCount)
            return WODPaceEstimator.scoreForTime(elapsedSeconds: elapsed, estimate: estimate)
        case .totalReps:
            guard let rounds = comparableRounds(result) else { return nil }
            let windowMin = template?.timeCapMinutes
                ?? max(5, Int(session.durationMinutes.rounded()))
            let window = Double(max(5, min(90, windowMin))) * 60
            let estimate = WODPaceEstimator.estimateAMRAP(roundLines: lines, windowSeconds: window)
            return WODPaceEstimator.scoreAMRAP(rounds: rounds, estimate: estimate)
        case .perMovementSets:
            return nil
        }
    }

    /// Heurística por formato cuando no hay bandas ni typicalMinutes.
    private static func scoreFromFormat(
        result: WODBlockResult,
        format: WODFormat?,
        typicalMinutes: Int?
    ) -> (level: AthleteLevel?, score: Int, summary: String)? {
        let fmt = format ?? .forTime
        switch fmt.resultCapture {
        case .elapsedTime:
            guard let elapsed = result.elapsedSeconds, elapsed > 0 else { return nil }
            if let typical = typicalMinutes, typical > 0 {
                return mapLevelFromTypical(elapsedSeconds: elapsed, typicalMinutes: typical)
            }
            // Sin ancla: ventana razonable 3–40′ → nota por densidad de trabajo.
            let minutes = Double(elapsed) / 60.0
            let score: Int
            let level: AthleteLevel
            if minutes <= 5 { score = 8; level = .advanced }
            else if minutes <= 12 { score = 7; level = .intermediate }
            else if minutes <= 25 { score = 6; level = .intermediate }
            else { score = 5; level = .beginner }
            return (
                level,
                score,
                "Terminaste en \(formatSeconds(elapsed))."
            )
        case .totalReps:
            guard let rounds = comparableRounds(result), rounds > 0 else { return nil }
            // AMRAP sin bandas: ~0.6–1.0 rondas/min es zona intermedia tipica en 10–20′.
            let windowMin = max(5.0, Double(typicalMinutes ?? 20))
            let rate = rounds / windowMin
            let level: AthleteLevel
            let score: Int
            if rate >= 1.2 { level = .elite; score = 9 }
            else if rate >= 0.85 { level = .advanced; score = 8 }
            else if rate >= 0.55 { level = .intermediate; score = 6 }
            else { level = .beginner; score = 4 }
            return (
                level,
                score,
                "Hiciste \(formatRounds(rounds)) (unas \(String(format: "%.1f", rate)) por minuto)."
            )
        case .perMovementSets:
            return (nil, 6, "Entreno por series: nota orientativa.")
        }
    }

    private static func mapLevel(
        result: WODBlockResult,
        bands: WODScoreBands,
        format: WODFormat?
    ) -> (level: AthleteLevel, score: Int, summary: String) {
        let capture = format?.resultCapture ?? .elapsedTime
        if capture == .elapsedTime || (result.elapsedSeconds ?? 0) > 0, bands.hasTimeBands,
           let elapsed = result.elapsedSeconds, elapsed > 0 {
            let level: AthleteLevel
            if let e = bands.eliteMaxSeconds, elapsed <= e {
                level = .elite
            } else if let a = bands.advancedMaxSeconds, elapsed <= a {
                level = .advanced
            } else if let i = bands.intermediateMaxSeconds, elapsed <= i {
                level = .intermediate
            } else {
                level = .beginner
            }
            let score = continuousTimeScore(elapsed: elapsed, bands: bands)
            let summary = "Tu tiempo fue \(formatSeconds(elapsed))."
            return (level, score, summary)
        }

        if bands.hasRoundsBands, let rounds = comparableRounds(result) {
            let level: AthleteLevel
            if let e = bands.eliteMinRounds, rounds >= e {
                level = .elite
            } else if let a = bands.advancedMinRounds, rounds >= a {
                level = .advanced
            } else if let i = bands.intermediateMinRounds, rounds >= i {
                level = .intermediate
            } else {
                level = .beginner
            }
            let score = continuousRoundsScore(rounds: rounds, bands: bands)
            let summary = "Completaste \(formatRounds(rounds))."
            return (level, score, summary)
        }

        return (.intermediate, 6, "Sin referencia clara; nota media orientativa.")
    }

    private static func mapLevelFromTypical(
        elapsedSeconds: Int,
        typicalMinutes: Int
    ) -> (level: AthleteLevel, score: Int, summary: String) {
        let typical = max(60, typicalMinutes * 60)
        let ratio = Double(elapsedSeconds) / Double(typical)
        let level: AthleteLevel
        if ratio <= 0.7 { level = .elite }
        else if ratio <= 0.95 { level = .advanced }
        else if ratio <= 1.25 { level = .intermediate }
        else { level = .beginner }
        // Interpolación continua 3…10 según ratio (más bajo = mejor).
        let score: Int = {
            if ratio <= 0.55 { return 10 }
            if ratio <= 0.7 { return 9 }
            if ratio <= 0.85 { return 8 }
            if ratio <= 0.95 { return 7 }
            if ratio <= 1.1 { return 6 }
            if ratio <= 1.25 { return 5 }
            if ratio <= 1.5 { return 4 }
            return 3
        }()
        return (
            level,
            score,
            "Tu tiempo fue \(formatSeconds(elapsedSeconds)). Lo habitual en este WOD ronda los \(typicalMinutes)′."
        )
    }

    /// Nota continua 3–10 interpolando umbrales de tiempo (más rápido = mejor).
    private static func continuousTimeScore(elapsed: Int, bands: WODScoreBands) -> Int {
        let elite = bands.eliteMaxSeconds
        let adv = bands.advancedMaxSeconds
        let mid = bands.intermediateMaxSeconds
        let beg = bands.beginnerMaxSeconds

        if let elite, elapsed <= elite {
            // Dentro de élite: 9–10 según margen bajo el umbral.
            let floor = max(1, elite / 2)
            if elapsed <= floor { return 10 }
            let t = Double(elapsed - floor) / Double(max(1, elite - floor))
            return max(9, min(10, 10 - Int((t * 1.2).rounded())))
        }
        if let elite, let adv, elapsed <= adv {
            let t = Double(elapsed - elite) / Double(max(1, adv - elite))
            return max(7, min(9, 9 - Int((t * 2).rounded())))
        }
        if let adv, let mid, elapsed <= mid {
            let t = Double(elapsed - adv) / Double(max(1, mid - adv))
            return max(5, min(7, 7 - Int((t * 2).rounded())))
        }
        if let mid, elapsed <= mid {
            return 5
        }
        if let beg, elapsed > beg { return 3 }
        if let mid, elapsed > mid { return 4 }
        return 4
    }

    /// Nota continua 3–10 interpolando umbrales de rondas (más = mejor).
    private static func continuousRoundsScore(rounds: Double, bands: WODScoreBands) -> Int {
        let elite = bands.eliteMinRounds
        let adv = bands.advancedMinRounds
        let mid = bands.intermediateMinRounds
        let beg = bands.beginnerMinRounds

        if let elite, rounds >= elite {
            let ceiling = elite * 1.25
            if rounds >= ceiling { return 10 }
            let t = (rounds - elite) / max(0.01, ceiling - elite)
            return max(9, min(10, 9 + Int((t * 1.5).rounded())))
        }
        if let elite, let adv, rounds >= adv {
            let t = (rounds - adv) / max(0.01, elite - adv)
            return max(7, min(9, 7 + Int((t * 2).rounded())))
        }
        if let adv, let mid, rounds >= mid {
            let t = (rounds - mid) / max(0.01, adv - mid)
            return max(5, min(7, 5 + Int((t * 2).rounded())))
        }
        if let mid, rounds >= mid { return 5 }
        if let beg, rounds < beg * 0.5 { return 3 }
        return 4
    }

    private static func comparableRounds(_ result: WODBlockResult) -> Double? {
        let rounds = Double(result.roundsCompleted ?? 0)
        let reps = Double(result.totalReps ?? 0)
        if rounds <= 0, reps <= 0 { return nil }
        let frac = min(0.99, reps / 100.0)
        return rounds + frac
    }

    private static func vsHistory(
        result: WODBlockResult,
        templateId: String?,
        prior: [WorkoutSession]
    ) -> String? {
        guard let templateId else { return nil }
        let previous: [WODBlockResult] = prior.flatMap(\.wodResults).filter { $0.wodTemplateId == templateId }
        guard !previous.isEmpty else { return "Primer intento registrado de este WOD." }

        if let elapsed = result.elapsedSeconds, elapsed > 0 {
            let times = previous.compactMap(\.elapsedSeconds).filter { $0 > 0 }
            guard let best = times.min() else { return nil }
            let delta = elapsed - best
            if delta < 0 {
                return "PR: \(formatSeconds(-delta)) más rápido que tu mejor (\(formatSeconds(best)))."
            }
            if delta == 0 { return "Empatas tu mejor marca (\(formatSeconds(best)))." }
            return "+\(formatSeconds(delta)) vs tu mejor (\(formatSeconds(best)))."
        }

        if let rounds = comparableRounds(result) {
            let priorRounds = previous.compactMap(comparableRounds)
            guard let best = priorRounds.max() else { return nil }
            let delta = rounds - best
            if delta > 0.05 {
                return "PR: +\(formatRounds(delta)) vs tu mejor (\(formatRounds(best)))."
            }
            if abs(delta) < 0.05 { return "Empatas tu mejor (\(formatRounds(best)))." }
            return "\(formatRounds(-delta)) por debajo de tu mejor (\(formatRounds(best)))."
        }
        return nil
    }

    // MARK: - Movements (equivalencias)

    private static func reviewMovements(
        session: WorkoutSession,
        prior: [WorkoutSession]
    ) -> [MovementReview] {
        var out: [MovementReview] = []
        for entry in session.exercises {
            let sets = entry.loggedSets.filter { !$0.isWarmup && ($0.reps > 0 || ($0.durationSeconds ?? 0) > 0) }
            guard !sets.isEmpty else { continue }
            let match = ExerciseEquivalence.comparablePriorSets(for: entry.exercise, in: prior)
            let priorSets = match?.sets ?? []
            let style = entry.exercise.loggingStyle
            let loadField = entry.exercise.loadField

            switch style {
            case .repsAndTime:
                out.append(reviewRepsAndTime(entry: entry, sets: sets, priorSets: priorSets, match: match))
            case .loadAndReps:
                out.append(reviewLoadAndReps(entry: entry, sets: sets, priorSets: priorSets, loadField: loadField, match: match))
            case .machineWork:
                out.append(reviewMachine(entry: entry, sets: sets, priorSets: priorSets, match: match))
            case .repsOnly:
                out.append(reviewRepsOnly(entry: entry, sets: sets, priorSets: priorSets, match: match))
            }
        }
        return Array(out.prefix(8))
    }

    private static func similarNote(_ match: EquivalentSetMatch?, exerciseName: String) -> String? {
        guard let match else { return nil }
        if namesEqual(match.referenceName, exerciseName) { return nil }
        return match.referenceName
    }

    private static func namesEqual(_ a: String, _ b: String) -> Bool {
        a.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            == b.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private static func reviewRepsAndTime(
        entry: SessionExercise,
        sets: [LoggedSet],
        priorSets: [LoggedSet],
        match: EquivalentSetMatch?
    ) -> MovementReview {
        let best = sets.max(by: { density($0) < density($1) }) ?? sets[0]
        let reps = best.reps
        let secs = max(1, best.durationSeconds ?? 60)
        let rate = Double(reps) / Double(secs) * 60
        let priorBest = priorSets.map(density).max().map { $0 * (match?.transferFactor ?? 1) }
        var verdict: MovementVerdict = .good
        var detail = "\(reps) veces en \(formatSeconds(secs)) (\(Int(rate.rounded()))/min)."
        var ratio: Double?
        if let priorBest, priorBest > 0 {
            ratio = density(best) / priorBest
            if let compared = similarNote(match, exerciseName: entry.exercise.name) {
                detail += " Vs \(compared)."
            }
            if density(best) > priorBest * 1.05 {
                detail += " Mejor ritmo que tu historial similar."
                verdict = .good
            } else if density(best) < priorBest * 0.85 {
                detail += " Por debajo de tu mejor ritmo similar."
                verdict = .improve
            }
        } else if rate < 40 {
            detail += " Ritmo bajo para dobles: trabaja unbroken cortos."
            verdict = .improve
        }
        return MovementReview(
            exerciseId: entry.exercise.id,
            name: entry.exercise.name,
            verdict: verdict,
            detail: detail,
            comparedToName: similarNote(match, exerciseName: entry.exercise.name),
            performanceRatio: ratio
        )
    }

    private static func density(_ set: LoggedSet) -> Double {
        Double(set.reps) / Double(max(1, set.durationSeconds ?? 60))
    }

    private static func reviewLoadAndReps(
        entry: SessionExercise,
        sets: [LoggedSet],
        priorSets: [LoggedSet],
        loadField: ExerciseLoadField,
        match: EquivalentSetMatch?
    ) -> MovementReview {
        if loadField == .deficitCm {
            let deficit = sets.compactMap(\.deficitCm).max() ?? 0
            let reps = sets.map(\.reps).max() ?? 0
            var verdict: MovementVerdict = .good
            var detail = deficit > 0
                ? "Déficit \(deficit) cm · \(reps) reps."
                : "Sin déficit · \(reps) reps."
            var ratio: Double?
            let priorDef = priorSets.compactMap(\.deficitCm).max() ?? 0
            let priorReps = priorSets.map(\.reps).max() ?? 0
            if priorDef > 0 || priorReps > 0 {
                let currentScore = Double(deficit) * 10 + Double(reps)
                let priorScore = max(1, Double(priorDef) * 10 + Double(priorReps)) * (match?.transferFactor ?? 1)
                ratio = currentScore / priorScore
                if let compared = similarNote(match, exerciseName: entry.exercise.name) {
                    detail += " Vs \(compared)."
                }
                if ratio! > 1.05 { detail += " Por encima de tu déficit/reps histórico." }
                else if ratio! < 0.85 {
                    detail += " Por debajo de tu mejor en movimientos similares."
                    verdict = .improve
                }
            } else if deficit == 0, reps >= 8 {
                detail += " Prueba +2–5 cm si la técnica está sólida."
                verdict = .improve
            } else if deficit >= 10 {
                detail += " Déficit avanzado: mantén control en el bloqueo."
            }
            return MovementReview(
                exerciseId: entry.exercise.id,
                name: entry.exercise.name,
                verdict: verdict,
                detail: detail,
                comparedToName: similarNote(match, exerciseName: entry.exercise.name),
                performanceRatio: ratio
            )
        }

        let working = sets.compactMap { set -> (Double, Int)? in
            guard let w = set.weightKg, w > 0, set.reps > 0 else { return nil }
            return (w, set.reps)
        }
        if working.isEmpty {
            let reps = sets.map(\.reps).reduce(0, +)
            var detail = "Sin lastre/carga · \(reps) reps."
            var verdict: MovementVerdict = .good
            if ExerciseEquivalence.family(for: entry.exercise) == .pull, reps >= 20 {
                detail += " Valora lastre ligero o clusters más densos."
                verdict = .improve
            }
            return MovementReview(
                exerciseId: entry.exercise.id,
                name: entry.exercise.name,
                verdict: verdict,
                detail: detail
            )
        }

        let best = working.max(by: {
            PlateMath.epleyOneRM(weightKg: $0.0, reps: $0.1) < PlateMath.epleyOneRM(weightKg: $1.0, reps: $1.1)
        })!
        let e1 = PlateMath.epleyOneRM(weightKg: best.0, reps: best.1)
        let priorE1Raw = priorSets.compactMap { set -> Double? in
            guard let w = set.weightKg, w > 0, set.reps > 0 else { return nil }
            return PlateMath.epleyOneRM(weightKg: w, reps: set.reps)
        }.max()
        let priorE1 = priorE1Raw.map { $0 * (match?.transferFactor ?? 1) }

        var verdict: MovementVerdict = .good
        var detail = String(format: "%.0f kg × %d (e1RM ~%.0f).", best.0, best.1, e1)
        var ratio: Double?
        if let priorE1, priorE1 > 0 {
            ratio = e1 / priorE1
            if let compared = similarNote(match, exerciseName: entry.exercise.name) {
                detail += " Vs \(compared)."
            }
            if e1 > priorE1 * 1.02 {
                detail += " Por encima de tu e1RM en similares."
                verdict = .good
            } else if e1 < priorE1 * 0.9 {
                detail += " Carga suave vs historial similar."
                verdict = .improve
            }
        }
        let topWeight = working.map(\.0).max() ?? 0
        if topWeight > 0, best.1 >= 8, let priorE1, topWeight < priorE1 * 0.55 {
            detail += " Hay margen para subir kg en series de calidad."
            verdict = .improve
        }
        return MovementReview(
            exerciseId: entry.exercise.id,
            name: entry.exercise.name,
            verdict: verdict,
            detail: detail,
            comparedToName: similarNote(match, exerciseName: entry.exercise.name),
            performanceRatio: ratio
        )
    }

    private static func reviewMachine(
        entry: SessionExercise,
        sets: [LoggedSet],
        priorSets: [LoggedSet],
        match: EquivalentSetMatch?
    ) -> MovementReview {
        let qty = sets.map(\.reps).reduce(0, +)
        let unit = sets.compactMap(\.quantityUnit).last ?? entry.exercise.defaultQuantityUnit
        let secs = sets.compactMap(\.durationSeconds).reduce(0, +)
        var detail = "\(qty) \(unit.shortLabel)"
        if secs > 0 { detail += " en \(formatSeconds(secs))" }
        detail += "."

        let currentRate: Double = {
            if secs > 0 { return Double(qty) / (Double(secs) / 60.0) }
            return Double(qty)
        }()
        let priorRates: [Double] = priorSets.compactMap { set in
            let q = set.reps
            guard q > 0 else { return nil }
            if let d = set.durationSeconds, d > 0 {
                return Double(q) / (Double(d) / 60.0)
            }
            return Double(q)
        }
        let priorBest = priorRates.max().map { $0 * (match?.transferFactor ?? 1) }
        var verdict: MovementVerdict = .good
        var ratio: Double?
        if let priorBest, priorBest > 0 {
            ratio = currentRate / priorBest
            if let compared = similarNote(match, exerciseName: entry.exercise.name) {
                detail += " Vs \(compared)."
            }
            if currentRate > priorBest * 1.05 {
                detail += " Mejor ritmo que sesiones similares."
            } else if currentRate < priorBest * 0.85 {
                detail += " Ritmo por debajo de tu historial similar."
                verdict = .improve
            }
        }
        return MovementReview(
            exerciseId: entry.exercise.id,
            name: entry.exercise.name,
            verdict: verdict,
            detail: detail,
            comparedToName: similarNote(match, exerciseName: entry.exercise.name),
            performanceRatio: ratio
        )
    }

    private static func reviewRepsOnly(
        entry: SessionExercise,
        sets: [LoggedSet],
        priorSets: [LoggedSet],
        match: EquivalentSetMatch?
    ) -> MovementReview {
        let total = sets.map(\.reps).reduce(0, +)
        let bestSet = sets.map(\.reps).max() ?? 0
        let priorBest = Int(Double(priorSets.map(\.reps).max() ?? 0) * (match?.transferFactor ?? 1))
        var verdict: MovementVerdict = .good
        var detail = "\(total) reps totales (mejor serie \(bestSet))."
        var ratio: Double?
        if priorBest > 0 {
            ratio = Double(bestSet) / Double(priorBest)
            if let compared = similarNote(match, exerciseName: entry.exercise.name) {
                detail += " Vs \(compared)."
            }
            if bestSet > priorBest {
                detail += " Mejor serie vs historial similar."
            } else if bestSet < Int(Double(priorBest) * 0.8) {
                detail += " Series más cortas que tu mejor similar."
                verdict = .improve
            }
        }
        return MovementReview(
            exerciseId: entry.exercise.id,
            name: entry.exercise.name,
            verdict: verdict,
            detail: detail,
            comparedToName: similarNote(match, exerciseName: entry.exercise.name),
            performanceRatio: ratio
        )
    }

    // MARK: - Blend & fallback

    /// Ajuste por tu rendimiento en movimientos similares (hasta ±2).
    private static func equivalenceAdjustment(from movements: [MovementReview]) -> Int {
        let ratios = movements.compactMap(\.performanceRatio).filter { $0 > 0 }
        guard !ratios.isEmpty else { return 0 }
        let avg = ratios.reduce(0, +) / Double(ratios.count)
        if avg >= 1.12 { return 2 }
        if avg >= 1.03 { return 1 }
        if avg <= 0.75 { return -2 }
        if avg <= 0.90 { return -1 }
        return 0
    }

    private static func clampScore(_ value: Int) -> Int {
        min(10, max(1, value))
    }

    private static func strengthFallback(
        session: WorkoutSession,
        movements: [MovementReview]
    ) -> SessionReview {
        let ratios = movements.compactMap(\.performanceRatio).filter { $0 > 0 }
        let basis: ScoreBasis
        let score: Int
        var historySummary: String?

        if !ratios.isEmpty {
            basis = .equivalentHistory
            let avg = ratios.reduce(0, +) / Double(ratios.count)
            // Map ratio → 3…10 (1.0 ≈ 7).
            let raw = 7 + Int(((avg - 1.0) * 10).rounded())
            score = clampScore(min(10, max(3, raw)))
            let refs = Array(Set(movements.compactMap(\.comparedToName))).prefix(2)
            if refs.isEmpty {
                historySummary = "Nota vs tu historial en movimientos similares."
            } else {
                historySummary = "Nota vs similares (\(refs.joined(separator: ", ")))."
            }
        } else {
            basis = .sessionEstimate
            let good = movements.filter { $0.verdict == .good }.count
            let improve = movements.filter { $0.verdict == .improve }.count
            let caution = movements.filter { $0.verdict == .caution }.count
            var s = 6
            s += min(2, good / 2)
            s -= min(2, improve)
            s -= min(2, caution)
            let workingSets = session.exercises.flatMap(\.loggedSets).filter { !$0.isWarmup }.count
            if workingSets >= 8 { s = min(10, s + 1) }
            score = clampScore(min(10, max(3, s)))
            historySummary = movements.isEmpty
                ? "Estimación de sesión (sin historial comparable)."
                : "Estimación de sesión; aún poco historial similar."
        }

        var keep: [String] = []
        var improveTips: [String] = []
        let good = movements.filter { $0.verdict == .good }.count
        let improve = movements.filter { $0.verdict == .improve }.count
        if good > 0 { keep.append("Varios movimientos en buena línea respecto a tu historial similar.") }
        if improve > 0 { improveTips.append("Sube carga o densidad solo donde la técnica lo permita.") }
        if keep.isEmpty { keep.append("Entreno apuntado: úsalo como base para la próxima sesión.") }

        return SessionReview(
            overallScore: score,
            level: nil,
            headline: "Sesión: \(score)/10",
            vsHistorySummary: historySummary,
            vsStandardSummary: nil,
            keepTips: Array(keep.prefix(2)),
            improveTips: Array(improveTips.prefix(2)),
            movements: movements,
            wodTemplateId: nil,
            scoreBasis: basis
        )
    }

    private static func merge(_ base: SessionReview, movements: [MovementReview]) -> SessionReview {
        var keep = base.keepTips
        var improve = base.improveTips
        if movements.contains(where: { $0.verdict == .good }) {
            if !keep.contains(where: { $0.contains("movimientos") }) {
                keep.append("Buenas marcas en movimientos clave del bloque.")
            }
        }
        if movements.contains(where: { $0.verdict == .improve }) {
            improve.append("Revisa los movimientos marcados como mejorables.")
        }

        let adj = equivalenceAdjustment(from: movements)
        let score = clampScore(base.overallScore + adj)
        var history = base.vsHistorySummary
        if adj != 0 {
            let refs = nonEmptySimilarRefs(movements)
            let tip: String = {
                if adj >= 2 {
                    return refs.map { "En \($0) vas claramente mejor que en tus sesiones parecidas." }
                        ?? "Vas claramente mejor que en tus sesiones parecidas."
                }
                if adj == 1 {
                    return refs.map { "En \($0) vas un poco mejor que de costumbre." }
                        ?? "Vas un poco mejor que de costumbre."
                }
                if adj <= -2 {
                    return refs.map { "En \($0) estás bastante por debajo de tus marcas habituales." }
                        ?? "Estás bastante por debajo de tus marcas habituales."
                }
                return refs.map { "En \($0) estás un poco por debajo de lo habitual." }
                    ?? "Estás un poco por debajo de lo habitual."
            }()
            if adj > 0 { keep.append(tip) } else { improve.append(tip) }
            // Prioriza explicar tu rendimiento personal junto al PR de WOD.
            if let existing = history, !existing.isEmpty {
                history = "\(existing) · \(tip)"
            } else {
                history = tip
            }
        } else if movements.contains(where: { $0.performanceRatio != nil }) {
            let tip = "En línea con lo que sueles hacer en movimientos parecidos."
            if history == nil || history?.contains("Primer intento") == true {
                history = tip
            }
        }

        let headline: String = {
            if let level = base.level {
                let name = base.headline.split(separator: ":").first.map(String.init) ?? "WOD"
                return "\(name): \(level.label) · \(score)/10"
            }
            return base.headline.replacingOccurrences(
                of: "\(base.overallScore)/10",
                with: "\(score)/10"
            )
        }()

        return SessionReview(
            overallScore: score,
            level: base.level,
            headline: headline,
            vsHistorySummary: history,
            vsStandardSummary: base.vsStandardSummary,
            keepTips: Array(keep.prefix(3)),
            improveTips: Array(improve.prefix(3)),
            movements: movements,
            wodTemplateId: base.wodTemplateId,
            scoreBasis: base.scoreBasis
        )
    }

    private static func nonEmptySimilarRefs(_ movements: [MovementReview]) -> String? {
        let refs = Array(Set(movements.compactMap(\.comparedToName))).prefix(2)
        guard !refs.isEmpty else { return nil }
        return refs.joined(separator: ", ")
    }

    // MARK: - Helpers

    private static func formatSeconds(_ total: Int) -> String {
        let m = total / 60
        let s = abs(total) % 60
        return String(format: "%d:%02d", m, s)
    }

    private static func formatRounds(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return "\(Int(value.rounded())) rondas"
        }
        return String(format: "%.1f rondas", value)
    }
}
