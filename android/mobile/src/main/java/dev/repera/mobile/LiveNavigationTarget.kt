package dev.repera.mobile

/** Exact Apple5890215d contract: live opens recorder, workout opens current
 * session or home. No UUID lookup and no fabricated finished-workout target.
 * `repera://invitation/{uuid}` opens that invitation in Center (iOS
 * RootTabView.handleOpenURL); any other invitation path is ignored. */
internal object LiveNavigationTarget {
    const val CENTER_INVITATION_PREFIX = "center/invitacion/"
    private val canonicalUuid =
        Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

    fun route(host:String?, pathSegments:List<String> = emptyList()):String? = when(host) {
        "live" -> "en-vivo"
        "workout" -> "entreno-activo"
        "invitation" -> when {
            pathSegments.isEmpty() -> "center"
            else -> invitationId(pathSegments)?.let { CENTER_INVITATION_PREFIX + it }
        }
        "today" -> "inicio"
        "timer" -> "temporizador"
        "exercises" -> "ejercicios"
        "board", "boardscan" -> "escaner"
        "import" -> "importar"
        else -> null
    }

    /** UUID canónico (8-4-4-4-12) como único segmento; `UUID.fromString` acepta formas laxas. */
    fun invitationId(pathSegments:List<String>):String? {
        val raw = pathSegments.singleOrNull() ?: return null
        return raw.takeIf { canonicalUuid.matches(it) }?.lowercase()
    }

    fun invitationIdFromRoute(route:String?):String? =
        route?.takeIf { it.startsWith(CENTER_INVITATION_PREFIX) }
            ?.removePrefix(CENTER_INVITATION_PREFIX)
            ?.let { invitationId(listOf(it)) }

    fun resolvedRoute(route:String,hasActiveWorkout:Boolean):String =
        if(route=="entreno-activo" && !hasActiveWorkout) "inicio" else route
}
