package dev.repera.mobile

/**
 * Costura de monetización para el escáner de pizarra. iOS consulta
 * SubscriptionStore.canStartBoardScan() antes de leer y consume un uso
 * con consumeBoardScanIfNeeded() al llegar a revisión.
 *
 * PENDIENTE (RevenueCat/Play): mientras la monetización no esté cableada
 * en Android, el acceso es permisivo. NO cerrar la Fase 4 sin decidir la
 * integración real del paywall/límites.
 */
object BoardScanQuota {
    fun canStart(): Boolean = true
    fun consume() {}
}
