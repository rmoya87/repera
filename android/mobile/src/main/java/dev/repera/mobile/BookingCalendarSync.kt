package dev.repera.mobile

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.provider.CalendarContract
import org.json.JSONArray
import org.json.JSONObject

/**
 * Optional CalendarContract mirror of booked Center occurrences.
 * Complements WorkManager −60 min reminders; write-only; no invented times.
 */
internal object BookingCalendarSync {
    private const val PREFS = "repera.booking.calendar"
    private const val KEY_EVENT_MAP = "eventMap"

    fun reconcile(context: Context, bookingsJson: JSONArray, occurrencesJson: JSONArray) {
        val cr = context.contentResolver
        val calId = defaultCalendarId(context) ?: return
        val occurrences = (0 until occurrencesJson.length()).mapNotNull { i ->
            occurrencesJson.optJSONObject(i)
        }.associateBy { it.optString("id") }
        val desired = linkedMapOf<String, Triple<String, Long, Long>>()
        for (i in 0 until bookingsJson.length()) {
            val booking = bookingsJson.optJSONObject(i) ?: continue
            if (booking.optString("status") != "booked") continue
            val occId = booking.optString("occurrence_id")
            val occ = occurrences[occId] ?: continue
            if (occ.optString("status") != "active") continue
            val start = parseMillis(occ.optString("starts_at")) ?: continue
            val end = parseMillis(occ.optString("ends_at")) ?: (start + 3_600_000L)
            val title = occ.optString("title").ifBlank { "Reserva Repera Center" }
            val key = booking.optString("id")
            if (key.isNotBlank()) desired[key] = Triple(title, start, end)
        }
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val map = JSONObject(prefs.getString(KEY_EVENT_MAP, "{}") ?: "{}")
        val staleKeys = map.keys().asSequence().toList().filter { it !in desired.keys }
        for (key in staleKeys) {
            val eventId = map.optLong(key, -1L)
            if (eventId > 0) {
                runCatching {
                    cr.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId), null, null)
                }
            }
            map.remove(key)
        }
        for ((bookingId, triple) in desired) {
            val values = ContentValues().apply {
                put(CalendarContract.Events.DTSTART, triple.second)
                put(CalendarContract.Events.DTEND, triple.third)
                put(CalendarContract.Events.TITLE, triple.first)
                put(CalendarContract.Events.DESCRIPTION, "Creado por Repera ($bookingId)")
                put(CalendarContract.Events.CALENDAR_ID, calId)
                put(CalendarContract.Events.EVENT_TIMEZONE, java.util.TimeZone.getDefault().id)
            }
            val existingId = map.optLong(bookingId, -1L)
            if (existingId > 0) {
                runCatching {
                    cr.update(
                        ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, existingId),
                        values, null, null
                    )
                }.onFailure {
                    val uri = runCatching { cr.insert(CalendarContract.Events.CONTENT_URI, values) }.getOrNull()
                    uri?.lastPathSegment?.toLongOrNull()?.let { map.put(bookingId, it) }
                }
            } else {
                val uri = runCatching { cr.insert(CalendarContract.Events.CONTENT_URI, values) }.getOrNull()
                uri?.lastPathSegment?.toLongOrNull()?.let { map.put(bookingId, it) }
            }
        }
        prefs.edit().putString(KEY_EVENT_MAP, map.toString()).apply()
    }

    private fun defaultCalendarId(context: Context): Long? {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.VISIBLE}=1 AND ${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL}>=?",
            arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()),
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getLong(0)
        }
        return null
    }

    private fun parseMillis(iso: String): Long? =
        runCatching { java.time.Instant.parse(iso).toEpochMilli() }.getOrNull()
}
