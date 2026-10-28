package dev.repera.domain.monetization

import dev.repera.domain.ProgressTimeRange

/**
 * Única fuente de verdad de permisos. Las vistas no reproducen reglas.
 * Port 1:1 de FeatureAccessPolicy.swift.
 */
data class FeatureAccessPolicy(
    val snapshot: CommercialSnapshot = CommercialSnapshot(),
    val freeUsage: FreeUsageState = FreeUsageState(),
    val libraryRoutineCount: Int = 0,
    val customExerciseCount: Int = 0,
    /** Favoritos de rutina/actividad (límite Gratis independiente). */
    val favoriteCount: Int = 0,
    /** Acceso completo mientras el deportista paga / está vinculado a un centro o entrenador. */
    val businessSponsoredAccess: Boolean = false
) {
    val isPro: Boolean get() = snapshot.grantsProAccess || businessSponsoredAccess

    val effectiveStatus: SubscriptionStatus get() = snapshot.effectiveStatus()

    fun decision(feature: ReperaFeature, now: Long = System.currentTimeMillis()): FeatureAccessDecision {
        if (isPro) return FeatureAccessDecision.allow()
        return when (feature) {
            // Paridad iOS: bajo el techo de rutinas, la entrada «unlimitedRoutines»
            // también refleja el cupo de favoritos (paywall unificado).
            ReperaFeature.UNLIMITED_ROUTINES ->
                if (libraryRoutineCount >= FreePlanLimits.MAX_LIBRARY_ROUTINES) createLibraryRoutineDecision()
                else createFavoriteDecision()
            ReperaFeature.UNLIMITED_CUSTOM_EXERCISES -> createCustomExerciseDecision()
            ReperaFeature.UNLIMITED_BOARD_SCANS -> boardScanDecision(now)
            ReperaFeature.EXERCISE_FULL_HISTORY, ReperaFeature.EXERCISE_EVOLUTION ->
                FeatureAccessDecision.deny(
                    reason = FeatureDenialReason.REQUIRES_PRO,
                    context = PaywallContext.EXERCISE_EVOLUTION,
                    title = "Tu evolución",
                    body = "Consulta todas tus marcas, compara tus entrenamientos y descubre cómo has progresado con este ejercicio."
                )
            ReperaFeature.HISTORICAL_WOD_RESULTS, ReperaFeature.WOD_RESULT_COMPARISONS ->
                FeatureAccessDecision.deny(
                    reason = FeatureDenialReason.REQUIRES_PRO,
                    context = PaywallContext.WOD_HISTORY,
                    title = "Supera tus marcas",
                    body = "Descubre cómo han evolucionado tus resultados cada vez que completas este WOD."
                )
            ReperaFeature.ADVANCED_PROGRESS, ReperaFeature.ADVANCED_REPORTS,
            ReperaFeature.PROGRESS_PERIOD_BEYOND_WEEK ->
                FeatureAccessDecision.deny(
                    reason = FeatureDenialReason.REQUIRES_PRO,
                    context = PaywallContext.PROGRESS,
                    title = "Analiza toda tu evolución",
                    body = "Analiza tu evolución, tus marcas personales, el equilibrio muscular y cómo cambia tu rendimiento con el tiempo."
                )
            ReperaFeature.ADVANCED_MUSCLE_ANALYSIS ->
                FeatureAccessDecision.deny(
                    reason = FeatureDenialReason.REQUIRES_PRO,
                    context = PaywallContext.MUSCLE_ANALYSIS,
                    title = "Conoce tu equilibrio muscular",
                    body = "Visualiza los grupos musculares trabajados y analiza cómo se distribuye tu entrenamiento."
                )
            ReperaFeature.ADVANCED_STRENGTH_PROGRESSION ->
                FeatureAccessDecision.deny(
                    reason = FeatureDenialReason.REQUIRES_PRO,
                    context = PaywallContext.ADVANCED_PROGRESSION,
                    title = "Progresión avanzada",
                    body = "Desbloquea recomendaciones de carga basadas en tu historial, RIR/RPE y políticas de progresión."
                )
        }
    }

    fun canAccess(feature: ReperaFeature): Boolean = decision(feature).allowed

    fun canCreateLibraryRoutine(isNew: Boolean): FeatureAccessDecision {
        if (!isNew || isPro) return FeatureAccessDecision.allow()
        return createLibraryRoutineDecision()
    }

    fun canCreateCustomExercise(isNew: Boolean): FeatureAccessDecision {
        if (!isNew || isPro) return FeatureAccessDecision.allow()
        return createCustomExerciseDecision()
    }

    /** Gratis: tres favoritos; el cuarto requiere Pro (paridad iOS). */
    fun canCreateFavorite(isNew: Boolean): FeatureAccessDecision {
        if (!isNew || isPro) return FeatureAccessDecision.allow()
        return createFavoriteDecision()
    }

    fun canStartBoardScan(now: Long = System.currentTimeMillis()): FeatureAccessDecision =
        if (isPro) FeatureAccessDecision.allow() else boardScanDecision(now)

    fun canSelectProgressRange(range: ProgressTimeRange): FeatureAccessDecision {
        if (isPro || !ReperaFeature.requiresPro(range)) return FeatureAccessDecision.allow()
        return decision(ReperaFeature.PROGRESS_PERIOD_BEYOND_WEEK)
    }

    val boardScanRemaining: Int
        get() = FreeUsageLedger.boardScansRemaining(freeUsage)

    val boardScanUsageCaption: String?
        get() {
            if (isPro) return null
            val used = FreeUsageLedger.normalized(freeUsage).boardScansConsumed
            val limit = FreePlanLimits.MAX_BOARD_SCANS_PER_MONTH
            val remaining = maxOf(0, limit - used)
            if (remaining == 1) return "Te queda 1 escaneo gratuito este mes"
            return "$used de $limit escaneos este mes"
        }

    private fun createLibraryRoutineDecision(): FeatureAccessDecision {
        val limit = FreePlanLimits.MAX_LIBRARY_ROUTINES
        val remaining = maxOf(0, limit - libraryRoutineCount)
        if (libraryRoutineCount < limit) {
            return FeatureAccessDecision.allow(
                remainingFreeUses = remaining, usedFreeUses = libraryRoutineCount, freeLimit = limit
            )
        }
        return FeatureAccessDecision.deny(
            reason = FeatureDenialReason.FREE_LIMIT_REACHED,
            context = PaywallContext.ROUTINES_LIMIT,
            title = "Todas tus rutinas, sin límites",
            body = "Con Repera Gratis puedes guardar hasta $limit rutinas reutilizables. Desbloquea Repera Pro para crear todas las que necesites.",
            remainingFreeUses = 0,
            usedFreeUses = libraryRoutineCount,
            freeLimit = limit
        )
    }

    private fun createFavoriteDecision(): FeatureAccessDecision {
        val limit = FreePlanLimits.MAX_FAVORITE_ITEMS
        val remaining = maxOf(0, limit - favoriteCount)
        if (favoriteCount < limit) {
            return FeatureAccessDecision.allow(
                remainingFreeUses = remaining, usedFreeUses = favoriteCount, freeLimit = limit
            )
        }
        return FeatureAccessDecision.deny(
            reason = FeatureDenialReason.FREE_LIMIT_REACHED,
            context = PaywallContext.ROUTINES_LIMIT,
            title = "Todos tus favoritos, sin límites",
            body = "Con Repera Gratis puedes guardar hasta $limit favoritos de entrenamiento o actividad. Desbloquea Repera Pro para guardar el cuarto y todos los que quieras.",
            remainingFreeUses = 0,
            usedFreeUses = favoriteCount,
            freeLimit = limit
        )
    }

    private fun createCustomExerciseDecision(): FeatureAccessDecision {
        val limit = FreePlanLimits.MAX_CUSTOM_EXERCISES
        val remaining = maxOf(0, limit - customExerciseCount)
        if (customExerciseCount < limit) {
            return FeatureAccessDecision.allow(
                remainingFreeUses = remaining, usedFreeUses = customExerciseCount, freeLimit = limit
            )
        }
        return FeatureAccessDecision.deny(
            reason = FeatureDenialReason.FREE_LIMIT_REACHED,
            context = PaywallContext.CUSTOM_EXERCISES_LIMIT,
            title = "Tus ejercicios, sin límites",
            body = "Con Repera Gratis puedes crear hasta $limit ejercicios propios. Desbloquea Repera Pro para añadir todos los que necesites.",
            remainingFreeUses = 0,
            usedFreeUses = customExerciseCount,
            freeLimit = limit
        )
    }

    private fun boardScanDecision(now: Long): FeatureAccessDecision {
        val limit = FreePlanLimits.MAX_BOARD_SCANS_PER_MONTH
        val remaining = FreeUsageLedger.boardScansRemaining(freeUsage, limit, now)
        val used = limit - remaining
        if (FreeUsageLedger.canStartBoardScan(freeUsage, isPro = false, limit = limit, now = now)) {
            return FeatureAccessDecision.allow(
                remainingFreeUses = remaining, usedFreeUses = used, freeLimit = limit
            )
        }
        return FeatureAccessDecision.deny(
            reason = FeatureDenialReason.FREE_LIMIT_REACHED,
            context = PaywallContext.BOARD_SCANS_LIMIT,
            title = "Cada pizarra, lista para entrenar",
            body = "Has usado tus $limit escaneos gratuitos de este mes. Con Repera Pro los escaneos son ilimitados.",
            remainingFreeUses = 0,
            usedFreeUses = used,
            freeLimit = limit
        )
    }
}
