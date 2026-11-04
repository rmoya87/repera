package dev.repera.wear

import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId

/**
 * One freshness rule for the hub, tile and complication: a dated plan is valid
 * only on its local day; senders without a date keep the legacy TTL.
 */
internal object WearTodayPlanCache {
    const val PREFS = "repera.wear.session"

    fun isFresh(day: String?, savedAtMillis: Long, today: LocalDate, nowMillis: Long): Boolean =
        when {
            day != null -> day == today.toString()
            else -> savedAtMillis > 0L &&
                nowMillis - savedAtMillis in 0L..WearMainActivity.TODAY_PLAN_TTL_MS
        }

    fun freshPlan(
        raw: String?,
        day: String?,
        savedAtMillis: Long,
        today: LocalDate = LocalDate.now(),
        nowMillis: Long = System.currentTimeMillis()
    ): JSONObject? {
        if (raw.isNullOrBlank() || !isFresh(day, savedAtMillis, today, nowMillis)) return null
        return runCatching { JSONObject(raw) }.getOrNull()
    }

    /** Epoch millis at which the cached plan stops being "today". */
    fun validUntilMillis(
        day: String?,
        savedAtMillis: Long,
        zone: ZoneId = ZoneId.systemDefault()
    ): Long? = when {
        day != null -> runCatching {
            LocalDate.parse(day).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        }.getOrNull()
        savedAtMillis > 0L -> savedAtMillis + WearMainActivity.TODAY_PLAN_TTL_MS
        else -> null
    }

    fun nextMidnightMillis(
        nowMillis: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault()
    ): Long = java.time.Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        .plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
}
