package dev.repera.mobile

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID
import java.util.concurrent.TimeUnit

/**
 * Center: datos reales de centros/entrenadores desde Supabase.
 * Port 1:1 de BusinessDataStore.swift (iOS): mismas tablas, mismos RPC,
 * misma frontera de seguridad (RLS + sesión autenticada).
 * Nunca inventa plazas ni cupos: el aforo llega del RPC get_service_availability.
 */
private fun parseInstant(value: String?): Instant? {
    if (value.isNullOrBlank()) return null
    return runCatching { Instant.parse(value) }.getOrNull()
        ?: runCatching { Instant.parse(value.replace(" ", "T")) }.getOrNull()
}

class BusinessCenterStore(
    private val http: OkHttpClient = OkHttpClient.Builder()
        .callTimeout(20, TimeUnit.SECONDS).build()
) {
    data class Organization(val id: String, val name: String, val kind: String,
        val slug: String?, val avatarUrl: String?, val tagline: String?)
    data class Invitation(val id: String, val organizationId: String,
        val invitedRole: String, val expiresAt: String?, val acceptedAt: String?,
        val cancelledAt: String?)
    data class ClientLink(val id: String, val orgId: String, val userId: String)
    data class Occurrence(val id: String, val orgId: String, val kind: String,
        val title: String, val startsAt: String, val endsAt: String?,
        val capacity: Int?, val status: String)
    data class Pass(val id: String, val orgId: String, val clientId: String,
        val kind: String, val totalCredits: Int, val remainingCredits: Int,
        val validFrom: String?, val validUntil: String?, val status: String)
    data class Booking(val id: String, val orgId: String, val clientId: String,
        val occurrenceId: String, val status: String)
    data class Availability(val occurrenceId: String, val capacity: Int,
        val reserved: Int)

    data class Snapshot(
        val centers: List<Organization> = emptyList(),
        val invitations: List<Invitation> = emptyList(),
        val athleteCenterIds: Set<String> = emptySet(),
        val occurrences: List<Occurrence> = emptyList(),
        val passes: List<Pass> = emptyList(),
        val bookings: List<Booking> = emptyList(),
        val availability: Map<String, Availability> = emptyMap()
    ) {
        val isLinkedOrInvited: Boolean
            get() = athleteCenterIds.isNotEmpty() || invitations.isNotEmpty()

        fun centerName(id: String): String =
            centers.firstOrNull { it.id == id }?.name ?: "Centro"

        fun bookingFor(occurrenceId: String): Booking? =
            bookings.firstOrNull { it.occurrenceId == occurrenceId && it.status == "booked" }

        fun remainingPlaces(occurrence: Occurrence): Int? {
            val item = availability[occurrence.id] ?: return null
            return (item.capacity - item.reserved).coerceAtLeast(0)
        }

        fun availablePasses(occurrence: Occurrence): List<Pass> {
            val begins = parseInstant(occurrence.startsAt) ?: return emptyList()
            return passes.filter { pass ->
                pass.orgId == occurrence.orgId && pass.kind == occurrence.kind &&
                    pass.status == "active" && pass.remainingCredits > 0 &&
                    (parseInstant(pass.validFrom) ?: Instant.MAX) <= begins &&
                    (parseInstant(pass.validUntil) ?: Instant.EPOCH) >= begins
            }
        }
    }

    sealed class LoadResult {
        data class Loaded(val snapshot: Snapshot) : LoadResult()
        data class Failed(val message: String) : LoadResult()
    }

    private fun get(session: SupabaseIdentity.Session, table: String,
                    select: String): JSONArray {
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/rest/v1/" + table + "?select=" + select)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .get().build()
        http.newCall(request).execute().use { response ->
            val body = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                throw IllegalStateException("HTTP " + response.code + " en " + table)
            }
            return JSONArray(body)
        }
    }

    private fun rpc(session: SupabaseIdentity.Session, fn: String,
                    params: JSONObject): JSONArray {
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/" + fn)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer " + session.accessToken)
            .header("Content-Type", "application/json")
            .post(params.toString().toRequestBody("application/json".toMediaType()))
            .build()
        http.newCall(request).execute().use { response ->
            val body = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                throw IllegalStateException("HTTP " + response.code + " en " + fn +
                    ": " + body.take(200))
            }
            return if (body.startsWith("[")) JSONArray(body) else JSONArray()
        }
    }

    /** Port de BusinessDataStore.refresh(): mismas consultas y filtros. */
    fun refresh(session: SupabaseIdentity.Session): LoadResult {
        return try {
            val currentUser = session.userId
            val centers = parseOrganizations(get(session, "organizations",
                "id,name,kind,slug,avatar_url,tagline"))
            val invitations = parseInvitations(get(session, "organization_invitations",
                "id,organization_id,invited_role,expires_at,accepted_at,cancelled_at"))
            val links = parseLinks(get(session, "clients", "id,org_id,user_id"))
            val ownedClientIds = links.filter { it.userId == currentUser }
                .map { it.id }.toSet()
            val occurrences = parseOccurrences(get(session, "service_occurrences",
                "id,org_id,kind,title,starts_at,ends_at,capacity,status"))
            val passes = parsePasses(get(session, "service_passes",
                "id,org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,status"))
            val bookings = parseBookings(get(session, "service_bookings",
                "id,org_id,client_id,occurrence_id,status"))
            val counts = mutableMapOf<String, Availability>()
            for (center in centers) {
                val occupancy = rpc(session, "get_service_availability",
                    JSONObject().put("p_org", center.id))
                for (i in 0 until occupancy.length()) {
                    val row = occupancy.getJSONObject(i)
                    val item = Availability(
                        occurrenceId = row.getString("occurrence_id"),
                        capacity = row.getInt("capacity"),
                        reserved = row.getInt("reserved"))
                    counts[item.occurrenceId] = item
                }
            }
            val now = Instant.now()
            LoadResult.Loaded(Snapshot(
                centers = centers,
                invitations = invitations.filter {
                    it.acceptedAt == null && it.cancelledAt == null &&
                        (parseInstant(it.expiresAt) ?: Instant.MAX) > now
                },
                athleteCenterIds = links.filter { it.userId == currentUser }
                    .map { it.orgId }.toSet(),
                occurrences = occurrences.filter { it.status == "active" },
                passes = passes.filter { it.clientId in ownedClientIds },
                bookings = bookings.filter { it.clientId in ownedClientIds },
                availability = counts))
        } catch (error: Exception) {
            LoadResult.Failed("No se han podido cargar tus centros y reservas. " +
                (error.localizedMessage ?: ""))
        }
    }

    fun accept(session: SupabaseIdentity.Session, invitation: Invitation) {
        rpc(session, "accept_org_invitation",
            JSONObject().put("p_invitation_id", invitation.id))
    }

    fun book(session: SupabaseIdentity.Session, occurrence: Occurrence, pass: Pass) {
        rpc(session, "book_service_occurrence", JSONObject()
            .put("p_occurrence", occurrence.id)
            .put("p_pass", pass.id)
            .put("p_request", UUID.randomUUID().toString()))
    }

    fun cancel(session: SupabaseIdentity.Session, booking: Booking) {
        rpc(session, "cancel_service_booking", JSONObject()
            .put("p_booking", booking.id)
            .put("p_request", UUID.randomUUID().toString()))
    }

    private fun parseOrganizations(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Organization(row.getString("id"), row.optString("name"),
            row.optString("kind"), row.optString("slug").ifBlank { null },
            row.optString("avatar_url").ifBlank { null },
            row.optString("tagline").ifBlank { null })
    }

    private fun parseInvitations(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Invitation(row.getString("id"), row.getString("organization_id"),
            row.optString("invited_role"),
            row.optString("expires_at").ifBlank { null },
            row.optString("accepted_at").ifBlank { null },
            row.optString("cancelled_at").ifBlank { null })
    }

    private fun parseLinks(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        ClientLink(row.getString("id"), row.getString("org_id"), row.getString("user_id"))
    }

    private fun parseOccurrences(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Occurrence(row.getString("id"), row.getString("org_id"),
            row.optString("kind"), row.optString("title"),
            row.getString("starts_at"),
            row.optString("ends_at").ifBlank { null },
            row.optInt("capacity").takeIf { row.has("capacity") && !row.isNull("capacity") },
            row.optString("status"))
    }

    private fun parsePasses(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Pass(row.getString("id"), row.getString("org_id"), row.getString("client_id"),
            row.optString("kind"), row.optInt("total_credits"),
            row.optInt("remaining_credits"),
            row.optString("valid_from").ifBlank { null },
            row.optString("valid_until").ifBlank { null },
            row.optString("status"))
    }

    private fun parseBookings(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Booking(row.getString("id"), row.getString("org_id"), row.getString("client_id"),
            row.getString("occurrence_id"), row.optString("status"))
    }
}
