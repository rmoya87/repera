import Foundation

/// Única fuente de verdad de permisos. Las vistas no reproducen reglas.
public struct FeatureAccessPolicy: Sendable, Equatable {
    public var snapshot: CommercialSnapshot
    public var freeUsage: FreeUsageState
    public var libraryRoutineCount: Int
    public var customExerciseCount: Int

    public init(
        snapshot: CommercialSnapshot = CommercialSnapshot(),
        freeUsage: FreeUsageState = FreeUsageState(),
        libraryRoutineCount: Int = 0,
        customExerciseCount: Int = 0
    ) {
        self.snapshot = snapshot
        self.freeUsage = freeUsage
        self.libraryRoutineCount = libraryRoutineCount
        self.customExerciseCount = customExerciseCount
    }

    public var isPro: Bool { snapshot.grantsProAccess }

    public var effectiveStatus: SubscriptionStatus {
        snapshot.effectiveStatus()
    }

    // MARK: - Queries

    public func decision(for feature: ReperaFeature, now: Date = Date()) -> FeatureAccessDecision {
        if isPro {
            return .allow()
        }

        switch feature {
        case .unlimitedRoutines:
            return createLibraryRoutineDecision(now: now)
        case .unlimitedCustomExercises:
            return createCustomExerciseDecision()
        case .unlimitedBoardScans:
            return boardScanDecision(now: now)
        case .exerciseFullHistory, .exerciseEvolution:
            return .deny(
                reason: .requiresPro,
                context: .exerciseEvolution,
                title: "Tu evolución",
                body: "Consulta todas tus marcas, compara tus entrenamientos y descubre cómo has progresado con este ejercicio."
            )
        case .historicalWODResults, .wodResultComparisons:
            return .deny(
                reason: .requiresPro,
                context: .wodHistory,
                title: "Supera tus marcas",
                body: "Descubre cómo han evolucionado tus resultados cada vez que completas este WOD."
            )
        case .advancedProgress, .advancedReports, .progressPeriodBeyondWeek:
            return .deny(
                reason: .requiresPro,
                context: .progress,
                title: "Analiza toda tu evolución",
                body: "Analiza tu evolución, tus marcas personales, el equilibrio muscular y cómo cambia tu rendimiento con el tiempo."
            )
        case .advancedMuscleAnalysis:
            return .deny(
                reason: .requiresPro,
                context: .muscleAnalysis,
                title: "Conoce tu equilibrio muscular",
                body: "Visualiza los grupos musculares trabajados y analiza cómo se distribuye tu entrenamiento."
            )
        case .advancedStrengthProgression:
            return .deny(
                reason: .requiresPro,
                context: .advancedProgression,
                title: "Progresión avanzada",
                body: "Desbloquea recomendaciones de carga basadas en tu historial, RIR/RPE y políticas de progresión."
            )
        }
    }

    public func canAccess(_ feature: ReperaFeature) -> Bool {
        decision(for: feature).allowed
    }

    public func canCreateLibraryRoutine(isNew: Bool) -> FeatureAccessDecision {
        guard isNew else { return .allow() }
        return createLibraryRoutineDecision()
    }

    public func canCreateCustomExercise(isNew: Bool) -> FeatureAccessDecision {
        guard isNew else { return .allow() }
        return createCustomExerciseDecision()
    }

    public func canStartBoardScan(now: Date = Date()) -> FeatureAccessDecision {
        boardScanDecision(now: now)
    }

    public func canSelectProgressRange(_ range: ProgressTimeRange) -> FeatureAccessDecision {
        if isPro || !ReperaFeature.requiresPro(for: range) {
            return .allow()
        }
        return decision(for: .progressPeriodBeyondWeek)
    }

    public var boardScanRemaining: Int {
        FreeUsageLedger.boardScansRemaining(in: freeUsage)
    }

    public var boardScanUsageCaption: String? {
        guard !isPro else { return nil }
        let used = FreeUsageLedger.normalized(freeUsage).boardScansConsumed
        let limit = FreePlanLimits.maxBoardScansPerMonth
        let remaining = max(0, limit - used)
        if remaining == 1 {
            return "Te queda 1 escaneo gratuito este mes"
        }
        return "\(used) de \(limit) escaneos este mes"
    }

    // MARK: - Private

    private func createLibraryRoutineDecision(now: Date = Date()) -> FeatureAccessDecision {
        _ = now
        let limit = FreePlanLimits.maxLibraryRoutines
        let remaining = max(0, limit - libraryRoutineCount)
        if libraryRoutineCount < limit {
            return .allow(remainingFreeUses: remaining, usedFreeUses: libraryRoutineCount, freeLimit: limit)
        }
        return .deny(
            reason: .freeLimitReached,
            context: .routinesLimit,
            title: "Todas tus rutinas, sin límites",
            body: "Con Repera Gratis puedes guardar hasta \(limit) rutinas reutilizables. Desbloquea Repera Pro para crear todas las que necesites.",
            remainingFreeUses: 0,
            usedFreeUses: libraryRoutineCount,
            freeLimit: limit
        )
    }

    private func createCustomExerciseDecision() -> FeatureAccessDecision {
        let limit = FreePlanLimits.maxCustomExercises
        let remaining = max(0, limit - customExerciseCount)
        if customExerciseCount < limit {
            return .allow(remainingFreeUses: remaining, usedFreeUses: customExerciseCount, freeLimit: limit)
        }
        return .deny(
            reason: .freeLimitReached,
            context: .customExercisesLimit,
            title: "Tus ejercicios, sin límites",
            body: "Con Repera Gratis puedes crear hasta \(limit) ejercicios propios. Desbloquea Repera Pro para añadir todos los que necesites.",
            remainingFreeUses: 0,
            usedFreeUses: customExerciseCount,
            freeLimit: limit
        )
    }

    private func boardScanDecision(now: Date) -> FeatureAccessDecision {
        let limit = FreePlanLimits.maxBoardScansPerMonth
        let remaining = FreeUsageLedger.boardScansRemaining(in: freeUsage, limit: limit, now: now)
        let used = limit - remaining
        if FreeUsageLedger.canStartBoardScan(state: freeUsage, isPro: false, limit: limit, now: now) {
            return .allow(remainingFreeUses: remaining, usedFreeUses: used, freeLimit: limit)
        }
        return .deny(
            reason: .freeLimitReached,
            context: .boardScansLimit,
            title: "Cada pizarra, lista para entrenar",
            body: "Has usado tus \(limit) escaneos gratuitos de este mes. Con Repera Pro los escaneos son ilimitados.",
            remainingFreeUses: 0,
            usedFreeUses: used,
            freeLimit: limit
        )
    }
}
