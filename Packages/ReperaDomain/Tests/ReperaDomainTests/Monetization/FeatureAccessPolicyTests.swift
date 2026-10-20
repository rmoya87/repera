import Foundation
import Testing
@testable import ReperaDomain

@Suite("FeatureAccessPolicy")
struct FeatureAccessPolicyTests {

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
