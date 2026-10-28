package dev.repera.domain.monetization

/**
 * Estado comercial verificado (no un booleano local).
 * Port 1:1 de Packages/ReperaDomain/.../Monetization/SubscriptionStatus.swift.
 */
enum class SubscriptionStatus(val wire: String) {
    FREE("free"),
    TRIAL("trial"),
    PRO_MONTHLY("proMonthly"),
    PRO_ANNUAL("proAnnual"),
    GRACE_PERIOD("gracePeriod"),
    EXPIRED("expired"),
    REVOKED("revoked"),
    /** Temporal: aún no hay estado fiable (arranque / red). */
    UNKNOWN("unknown");

    /** Acceso efectivo a funcionalidades Pro (sin política offline). */
    val grantsProAccess: Boolean
        get() = when (this) {
            TRIAL, PRO_MONTHLY, PRO_ANNUAL, GRACE_PERIOD -> true
            FREE, EXPIRED, REVOKED, UNKNOWN -> false
        }

    val displayName: String
        get() = when (this) {
            FREE -> "Gratis"
            TRIAL -> "Prueba"
            PRO_MONTHLY -> "Pro mensual"
            PRO_ANNUAL -> "Pro anual"
            GRACE_PERIOD -> "Periodo de gracia"
            EXPIRED -> "Caducada"
            REVOKED -> "Revocada"
            UNKNOWN -> "Desconocido"
        }

    companion object {
        fun fromWire(wire: String): SubscriptionStatus =
            entries.firstOrNull { it.wire == wire } ?: UNKNOWN
    }
}

/** Snapshot comercial observable por la app (caché + verificación). */
data class CommercialSnapshot(
    val status: SubscriptionStatus = SubscriptionStatus.FREE,
    /** Último estado Pro concreto verificado (para offline / unknown). */
    val lastVerifiedProStatus: SubscriptionStatus? = null,
    val lastVerifiedProAt: Long? = null,
    val expirationDate: Long? = null,
    val activeProductID: String? = null,
    val isConfigured: Boolean = false,
    val lastRefreshFailedOffline: Boolean = false
) {
    /**
     * Política offline documentada:
     * - Pro verificado con `expirationDate` futura → sigue Pro.
     * - Pro verificado sin fecha + fallo de red reciente → sigue Pro hasta `offlineGraceInterval`.
     * - Caducado / revocado confirmados → no Pro.
     * - Unknown sin caché Pro → Gratis (no desbloquea).
     */
    fun effectiveStatus(
        now: Long = System.currentTimeMillis(),
        offlineGraceInterval: Long = 7L * 24 * 60 * 60 * 1000
    ): SubscriptionStatus {
        if (status.grantsProAccess) {
            expirationDate?.let { if (now > it) return SubscriptionStatus.EXPIRED }
            return status
        }
        return when (status) {
            SubscriptionStatus.EXPIRED, SubscriptionStatus.REVOKED, SubscriptionStatus.FREE -> status
            SubscriptionStatus.UNKNOWN ->
                cachedProIfStillValid(now, offlineGraceInterval) ?: SubscriptionStatus.FREE
            else -> status
        }
    }

    private fun cachedProIfStillValid(now: Long, offlineGraceInterval: Long): SubscriptionStatus? {
        val cached = lastVerifiedProStatus
        if (cached == null || !cached.grantsProAccess) return null
        expirationDate?.let { return if (now <= it) cached else null }
        val verifiedAt = lastVerifiedProAt ?: return null
        if (now - verifiedAt > offlineGraceInterval) return null
        return cached
    }

    val grantsProAccess: Boolean
        get() = effectiveStatus().grantsProAccess
}
