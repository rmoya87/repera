package dev.repera.contracts

/** Android-neutral contract; no Android/Google or network dependencies. */
enum class AgendaKind(val wire: String) {
    TRAINING("training"), CLASS("class"), APPOINTMENT("appointment");

    companion object {
        fun fromWire(value: String): AgendaKind = values().firstOrNull { it.wire == value }
            ?: throw IllegalArgumentException("Unknown agenda kind")
    }
}

data class BusinessAgendaEvent(
    val id: String,
    val kind: AgendaKind,
    val date: String,
    val title: String,
    val source: String = DEFAULT_SOURCE,
    val assignmentId: String? = null,
    val bookingId: String? = null,
    val exerciseText: String? = null,
    val deepLink: String
) {
    fun hasSafeDeepLink(): Boolean = listOf("repera://diary/", "repera://today/", "repera://classes/", "repera://appointments/", "repera://passes/").any { deepLink.startsWith(it) }
        && !deepLink.contains('?') && !deepLink.contains('#')

    companion object {
        const val DEFAULT_SOURCE = "professional"
    }
}

data class BusinessAgendaResponse(
    val schemaVersion: Int,
    val orgId: String,
    val clientId: String,
    val events: List<BusinessAgendaEvent>,
    val cursor: String?
)

/**
 * This client overlay never replaces locally recorded workouts. One calendar day may include
 * more than one professional event as well as any number of private, athlete-owned workouts.
 * Ordering matches Swift: date, kind wire value, id.
 */
object BusinessAgendaMerger {
    fun merge(existing: List<BusinessAgendaEvent>, incoming: List<BusinessAgendaEvent>): List<BusinessAgendaEvent> =
        (existing.filter { it.hasSafeDeepLink() } + incoming.filter { it.hasSafeDeepLink() })
            .associateBy { it.id }
            .values.sortedWith(compareBy({ it.date }, { it.kind.wire }, { it.id }))
}

/** Maps a JSON-decoded object to the same snake_case payload used by Swift. */
fun mapAgendaEvent(raw: Map<String, Any?>): BusinessAgendaEvent {
    fun required(key: String): String = (raw[key] as? String)?.takeIf { it.isNotBlank() }
        ?: throw IllegalArgumentException("Missing $key")
    return BusinessAgendaEvent(
        id=required("id"), kind=AgendaKind.fromWire(required("kind")), date=required("date"), title=required("title"),
        source=(raw["source"] as? String)?.takeIf { it.isNotBlank() } ?: BusinessAgendaEvent.DEFAULT_SOURCE,
        assignmentId=raw["assignment_id"] as? String, bookingId=raw["booking_id"] as? String,
        exerciseText=raw["exercise_text"] as? String, deepLink=required("deep_link")
    )
}

fun mapAgendaResponse(raw: Map<String, Any?>): BusinessAgendaResponse {
    fun required(key: String): String = (raw[key] as? String)?.takeIf { it.isNotBlank() }
        ?: throw IllegalArgumentException("Missing $key")
    val version = (raw["schema_version"] as? Number)?.toInt() ?: throw IllegalArgumentException("Missing schema_version")
    val events = (raw["events"] as? List<*>) ?: throw IllegalArgumentException("Missing events")
    return BusinessAgendaResponse(
        schemaVersion = version, orgId = required("org_id"), clientId = required("client_id"),
        events = events.map { item ->
            @Suppress("UNCHECKED_CAST")
            mapAgendaEvent(item as? Map<String, Any?> ?: throw IllegalArgumentException("Invalid event"))
        },
        cursor = raw["cursor"] as? String
    )
}
