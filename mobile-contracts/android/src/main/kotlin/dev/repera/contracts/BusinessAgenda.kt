package dev.repera.contracts

/** Android-neutral contract; no Android/Google or network dependencies. */
enum class AgendaKind { TRAINING, CLASS, APPOINTMENT }

data class BusinessAgendaEvent(
    val id: String,
    val kind: AgendaKind,
    val date: String,
    val title: String,
    val assignmentId: String? = null,
    val bookingId: String? = null,
    val exerciseText: String? = null,
    val deepLink: String
) {
    fun hasSafeDeepLink(): Boolean = listOf("repera://diary/", "repera://today/", "repera://classes/", "repera://appointments/", "repera://passes/").any { deepLink.startsWith(it) }
        && !deepLink.contains('?') && !deepLink.contains('#')
}

/**
 * This client overlay never replaces locally recorded workouts. One calendar day may include
 * more than one professional event as well as any number of private, athlete-owned workouts.
 */
object BusinessAgendaMerger {
    fun merge(existing: List<BusinessAgendaEvent>, incoming: List<BusinessAgendaEvent>): List<BusinessAgendaEvent> =
        (existing.filter { it.hasSafeDeepLink() } + incoming.filter { it.hasSafeDeepLink() })
            .associateBy { it.id }
            .values.sortedWith(compareBy(BusinessAgendaEvent::date, BusinessAgendaEvent::kind, BusinessAgendaEvent::id))
}

/** Maps a JSON-decoded object to the same snake_case payload used by Swift. */
fun mapAgendaEvent(raw: Map<String, Any?>): BusinessAgendaEvent {
    fun required(key: String): String = (raw[key] as? String)?.takeIf { it.isNotBlank() }
        ?: throw IllegalArgumentException("Missing $key")
    val kind = when(required("kind")) { "training" -> AgendaKind.TRAINING; "class" -> AgendaKind.CLASS; "appointment" -> AgendaKind.APPOINTMENT; else -> throw IllegalArgumentException("Unknown agenda kind") }
    return BusinessAgendaEvent(
        id=required("id"), kind=kind, date=required("date"), title=required("title"),
        assignmentId=raw["assignment_id"] as? String, bookingId=raw["booking_id"] as? String,
        exerciseText=raw["exercise_text"] as? String, deepLink=required("deep_link")
    )
}
