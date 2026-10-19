import Foundation

/// Estado comercial verificado (no un booleano local).
public enum SubscriptionStatus: String, Sendable, Codable, Equatable, Hashable {
    case free
    case trial
    case proMonthly
    case proAnnual
    case gracePeriod
    case expired
    case revoked
    /// Temporal: aún no hay CustomerInfo fiable (arranque / red).
    case unknown

    /// Acceso efectivo a funcionalidades Pro (sin política offline).
    public var grantsProAccess: Bool {
        switch self {
        case .trial, .proMonthly, .proAnnual, .gracePeriod:
            return true
        case .free, .expired, .revoked, .unknown:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .free: return "Gratis"
        case .trial: return "Prueba"
        case .proMonthly: return "Pro mensual"
        case .proAnnual: return "Pro anual"
        case .gracePeriod: return "Periodo de gracia"
        case .expired: return "Caducada"
        case .revoked: return "Revocada"
        case .unknown: return "Desconocido"
        }
    }
}

/// Snapshot comercial observable por la app (caché + verificación).
public struct CommercialSnapshot: Sendable, Equatable, Hashable {
    public var status: SubscriptionStatus
    /// Último estado Pro concreto verificado (para offline / unknown).
    public var lastVerifiedProStatus: SubscriptionStatus?
    public var lastVerifiedProAt: Date?
    public var expirationDate: Date?
    public var activeProductID: String?
    public var isConfigured: Bool
    public var lastRefreshFailedOffline: Bool

    public init(
        status: SubscriptionStatus = .free,
        lastVerifiedProStatus: SubscriptionStatus? = nil,
        lastVerifiedProAt: Date? = nil,
        expirationDate: Date? = nil,
        activeProductID: String? = nil,
        isConfigured: Bool = false,
        lastRefreshFailedOffline: Bool = false
    ) {
        self.status = status
        self.lastVerifiedProStatus = lastVerifiedProStatus
        self.lastVerifiedProAt = lastVerifiedProAt
        self.expirationDate = expirationDate
        self.activeProductID = activeProductID
        self.isConfigured = isConfigured
        self.lastRefreshFailedOffline = lastRefreshFailedOffline
    }

    /// Política offline documentada:
    /// - Pro verificado con `expirationDate` futura → sigue Pro.
    /// - Pro verificado sin fecha + fallo de red reciente → sigue Pro hasta `offlineGraceInterval`.
    /// - Caducado / revocado confirmados → no Pro.
    /// - Unknown sin caché Pro → Gratis (no desbloquea).
    public func effectiveStatus(
        now: Date = Date(),
        offlineGraceInterval: TimeInterval = 7 * 24 * 60 * 60
    ) -> SubscriptionStatus {
        if status.grantsProAccess {
            if let expirationDate, now > expirationDate {
                return .expired
            }
            return status
        }

        switch status {
        case .expired, .revoked, .free:
            return status
        case .unknown:
            return cachedProIfStillValid(now: now, offlineGraceInterval: offlineGraceInterval) ?? .free
        case .trial, .proMonthly, .proAnnual, .gracePeriod:
            return status
        }
    }

    private func cachedProIfStillValid(
        now: Date,
        offlineGraceInterval: TimeInterval
    ) -> SubscriptionStatus? {
        guard let cached = lastVerifiedProStatus, cached.grantsProAccess else { return nil }
        if let expirationDate {
            return now <= expirationDate ? cached : nil
        }
        guard let lastVerifiedProAt else { return nil }
        guard now.timeIntervalSince(lastVerifiedProAt) <= offlineGraceInterval else { return nil }
        return cached
    }

    public var grantsProAccess: Bool {
        effectiveStatus().grantsProAccess
    }
}
