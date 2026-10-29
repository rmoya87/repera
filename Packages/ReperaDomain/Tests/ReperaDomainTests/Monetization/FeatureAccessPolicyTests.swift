import Foundation
import Testing
@testable import ReperaDomain

@Suite("FeatureAccessPolicy")
struct FeatureAccessPolicyTests {

    @Test("La navegación 3D solo se desbloquea con acceso Pro efectivo")
    func mapNavigation3DAccess() {
        #expect(!FeatureAccessPolicy().canUse3DNavigation)
        #expect(!FeatureAccessPolicy(snapshot: CommercialSnapshot(status: .expired)).canUse3DNavigation)
        #expect(!FeatureAccessPolicy(snapshot: CommercialSnapshot(status: .revoked)).canUse3DNavigation)
        #expect(!FeatureAccessPolicy(snapshot: CommercialSnapshot(status: .unknown)).canUse3DNavigation)
        for status in [SubscriptionStatus.trial, .proMonthly, .proAnnual, .gracePeriod] {
            #expect(FeatureAccessPolicy(snapshot: CommercialSnapshot(status: status)).canUse3DNavigation)
        }
        #expect(FeatureAccessPolicy(businessSponsoredAccess: true).canUse3DNavigation)
    }

    @Test("Gratis puede registrar sin límites de sesión")
    func freeAlwaysAllowsCoreTraining() {
        let policy = FeatureAccessPolicy(libraryRoutineCount: 10, customExerciseCount: 50)
        // No hay feature que bloquee entrenamientos; evolución sí.
        #expect(policy.canAccess(.exerciseEvolution) == false)
        #expect(policy.isPro == false)
    }

    @Test("Pro accede a premium")
    func proAllowsPremium() {
        var snap = CommercialSnapshot(status: .proAnnual, isConfigured: true)
        snap.lastVerifiedProStatus = .proAnnual
        let policy = FeatureAccessPolicy(snapshot: snap, libraryRoutineCount: 100, customExerciseCount: 100)
        for feature in ReperaFeature.allCases {
            #expect(policy.canAccess(feature), "Pro debería acceder a \(feature)")
        }
    }

    @Test("Pro y prueba activa pueden guardar favoritos sin límite, incluso con cien plantillas")
    func paidAccessNeverBlocksSavingFavorites() {
        let statuses: [SubscriptionStatus] = [.trial, .proMonthly, .proAnnual, .gracePeriod]
        for status in statuses {
            let policy = FeatureAccessPolicy(
                snapshot: CommercialSnapshot(status: status, isConfigured: true),
                libraryRoutineCount: 100
            )
            #expect(policy.isPro)
            #expect(policy.canCreateLibraryRoutine(isNew: true).allowed)
            #expect(policy.decision(for: .unlimitedRoutines).allowed)
        }
    }

    @Test("Vínculo con centro/entrenador otorga acceso completo")
    func businessSponsoredGrantsFullAccess() {
        let policy = FeatureAccessPolicy(
            libraryRoutineCount: 100,
            customExerciseCount: 100,
            businessSponsoredAccess: true
        )
        #expect(policy.isPro)
        for feature in ReperaFeature.allCases {
            #expect(policy.canAccess(feature), "Patrocinio Business debería acceder a \(feature)")
        }
    }

    @Test("Pro de TestFlight también salta todos los límites de acciones")
    func paidActionGatesHonorEntitlement() {
        let activeStatuses: [SubscriptionStatus] = [.trial, .proMonthly, .proAnnual, .gracePeriod]
        for status in activeStatuses {
            let policy = FeatureAccessPolicy(
                snapshot: CommercialSnapshot(status: status, isConfigured: true),
                libraryRoutineCount: 100,
                favoriteCount: 100,
                customExerciseCount: 100
            )
            #expect(policy.canCreateLibraryRoutine(isNew: true).allowed)
            #expect(policy.canCreateFavorite(isNew: true).allowed)
            #expect(policy.canCreateCustomExercise(isNew: true).allowed)
            #expect(policy.canStartBoardScan().allowed)
        }
        let business = FeatureAccessPolicy(
            libraryRoutineCount: 100,
            favoriteCount: 100,
            customExerciseCount: 100,
            businessSponsoredAccess: true
        )
        #expect(business.canCreateFavorite(isNew: true).allowed)
        #expect(business.canStartBoardScan().allowed)
    }

    @Test("Gratis: tres favoritos reales, cuarto bloqueado; las rutinas normales no consumen el cupo")
    func favoriteLimitsAreIndependent() {
        var policy = FeatureAccessPolicy(libraryRoutineCount: 3, favoriteCount: 2)
        #expect(policy.canCreateFavorite(isNew: true).allowed)
        policy.favoriteCount = 3
        let fourth = policy.canCreateFavorite(isNew: true)
        #expect(!fourth.allowed)
        #expect(fourth.reason == .freeLimitReached)
        #expect(fourth.freeLimit == 3)
        #expect(fourth.paywallContext == .routinesLimit)
        #expect(policy.canCreateFavorite(isNew: false).allowed)
        policy.libraryRoutineCount = 0
        #expect(!policy.canCreateFavorite(isNew: true).allowed)
    }

    @Test("Gratis: 3 rutinas OK, 4ª bloqueada; edición permitida")
    func routineLimits() {
        var policy = FeatureAccessPolicy(libraryRoutineCount: 2)
        #expect(policy.canCreateLibraryRoutine(isNew: true).allowed)
        policy.libraryRoutineCount = 3
        #expect(policy.canCreateLibraryRoutine(isNew: true).allowed == false)
        #expect(policy.canCreateLibraryRoutine(isNew: false).allowed)
        #expect(policy.canCreateLibraryRoutine(isNew: true).paywallContext == .routinesLimit)
    }

    @Test("Gratis: 5 custom OK, 6º bloqueado")
    func customExerciseLimits() {
        var policy = FeatureAccessPolicy(customExerciseCount: 4)
        #expect(policy.canCreateCustomExercise(isNew: true).allowed)
        policy.customExerciseCount = 5
        #expect(policy.canCreateCustomExercise(isNew: true).allowed == false)
        #expect(policy.canCreateCustomExercise(isNew: false).allowed)
    }

    @Test("Periodo Progreso: solo semana en Gratis")
    func progressRanges() {
        let free = FeatureAccessPolicy()
        #expect(free.canSelectProgressRange(.week).allowed)
        #expect(free.canSelectProgressRange(.today).allowed == false)
        #expect(free.canSelectProgressRange(.month).allowed == false)
        #expect(free.canSelectProgressRange(.days90).allowed == false)

        let pro = FeatureAccessPolicy(snapshot: CommercialSnapshot(status: .trial))
        #expect(pro.canSelectProgressRange(.days360).allowed)
    }

    @Test("Cambio de estado actualiza permisos")
    func statusChangeUpdatesAccess() {
        var policy = FeatureAccessPolicy()
        #expect(policy.canAccess(.advancedMuscleAnalysis) == false)
        policy.snapshot.status = .proMonthly
        #expect(policy.canAccess(.advancedMuscleAnalysis))
        policy.snapshot.status = .expired
        #expect(policy.canAccess(.advancedMuscleAnalysis) == false)
    }

    @Test("Offline: Pro cacheado con caducidad futura sigue Pro")
    func offlineKeepsVerifiedPro() {
        let future = Date().addingTimeInterval(86_400)
        let snap = CommercialSnapshot(
            status: .unknown,
            lastVerifiedProStatus: .proAnnual,
            lastVerifiedProAt: Date(),
            expirationDate: future,
            lastRefreshFailedOffline: true
        )
        #expect(snap.grantsProAccess)
        #expect(FeatureAccessPolicy(snapshot: snap).canAccess(.exerciseEvolution))
    }

    @Test("Offline: sin caché Pro no desbloquea")
    func offlineWithoutCacheIsFree() {
        let snap = CommercialSnapshot(status: .unknown, lastRefreshFailedOffline: true)
        #expect(snap.grantsProAccess == false)
    }

    @Test("Caducado confirmado no da Pro")
    func expiredConfirmed() {
        let snap = CommercialSnapshot(
            status: .expired,
            lastVerifiedProStatus: .proMonthly,
            expirationDate: Date().addingTimeInterval(-100)
        )
        #expect(snap.grantsProAccess == false)
    }

    @Test("Revocado no da Pro")
    func revoked() {
        let snap = CommercialSnapshot(status: .revoked)
        #expect(snap.grantsProAccess == false)
    }
}
