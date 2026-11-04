package dev.repera.mobile

import dev.repera.mobile.analytics.ReperaAnalytics
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
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
        val slug: String?, val avatarUrl: String?, val tagline: String?,
        val publicEmail: String? = null, val phone: String? = null,
        val classBookingOpenHours: Int = 168)
    data class Invitation(val id: String, val organizationId: String,
        val invitedRole: String, val expiresAt: String?, val acceptedAt: String?,
        val cancelledAt: String?)
    data class InvitationPreview(val invitationId: String, val organizationId: String,
        val organizationName: String, val organizationKind: String,
        val organizationTagline: String?, val expiresAt: String?)
    sealed interface InvitationPreviewResult {
        data class Found(val preview: InvitationPreview) : InvitationPreviewResult
        /** Inexistente, de otro correo, aceptada, cancelada o caducada: el servidor no distingue. */
        data object Unavailable : InvitationPreviewResult
        data object Offline : InvitationPreviewResult
        data object Failed : InvitationPreviewResult
    }
    data class ClientLink(val id: String, val orgId: String, val userId: String)
    data class OperationSettings(
        val orgId: String?,
        val profile: String? = null,
        val useRooms: Boolean = false,
        val dayProgramEnabled: Boolean = true,
        val openAccessEnabled: Boolean = false,
        val openAccessRequiresBooking: Boolean = true,
        val cancelCreditHours: Int = 12
    )
    data class FacilityRoom(val id: String, val orgId: String, val name: String, val capacity: Int)
    data class Occurrence(val id: String, val orgId: String, val kind: String,
        val title: String, val startsAt: String, val endsAt: String?,
        val capacity: Int?, val status: String,
        val color: String? = null, val location: String? = null,
        val roomId: String? = null,
        val trainingTitle: String? = null, val trainingInstructions: String? = null,
        val prescription: JSONObject? = null)
    data class Pass(val id: String, val orgId: String, val clientId: String,
        val kind: String, val totalCredits: Int, val remainingCredits: Int,
        val validFrom: String?, val validUntil: String?, val status: String,
        val offerId: String? = null, val paidAt: String? = null,
        val paidAmountCents: Int? = null, val paymentMethod: String? = null,
        val issuanceType: String? = null)
    data class PassOffer(val id: String, val orgId: String, val name: String,
        val kind: String, val isActive: Boolean)
    data class Booking(val id: String, val orgId: String, val clientId: String,
        val occurrenceId: String, val status: String)
    data class ClassRosterPerson(val displayName: String, val avatarUrl: String?,
        val status: String? = null)
    data class ClassRoster(val occurrenceId: String?, val coach: ClassRosterPerson?,
        val attendees: List<ClassRosterPerson>, val capacity: Int?, val reserved: Int?)
    data class Notice(val id:String,val orgId:String,val clientId:String,val title:String,val body:String,val createdAt:String)
    data class ChatMessage(val id:String,val orgId:String,val clientId:String,val senderUserId:String,
        val senderRole:String,val body:String,val createdAt:String,val batchId:String?)
    data class ProfessionalSession(val id:String,val orgId:String,val clientId:String,val coachUserId:String,
        val scheduledDate:String,val title:String,val instructions:String,val status:String,
        val prescription:JSONObject?,val sourceOccurrenceId:String? = null,
        val scheduledTimeMinutes:Int? = null)
    data class Availability(val occurrenceId: String, val capacity: Int,
        val reserved: Int)

    /** Port de BusinessEntitlements (iOS): Pro patrocinado B2B vía RPC. */
    data class Entitlements(
        val effectivePro: Boolean = false,
        val storePro: Boolean = false,
        val businessSponsoredPro: Boolean = false,
        val storeGatePending: Boolean = true,
        val primarySponsorName: String? = null
    )

    data class Snapshot(
        val centers: List<Organization> = emptyList(),
        val invitations: List<Invitation> = emptyList(),
        val athleteCenterIds: Set<String> = emptySet(),
        val clientLinks: List<ClientLink> = emptyList(),
        val occurrences: List<Occurrence> = emptyList(),
        val operationSettingsByOrg: Map<String, OperationSettings> = emptyMap(),
        val facilityRooms: List<FacilityRoom> = emptyList(),
        val passes: List<Pass> = emptyList(),
        val passOffers: List<PassOffer> = emptyList(),
        val bookings: List<Booking> = emptyList(),
        val availability: Map<String, Availability> = emptyMap(),
        val notices:List<Notice> = emptyList(),
        val chatMessages: List<ChatMessage> = emptyList(),
        val trainingSessions:List<ProfessionalSession> = emptyList(),
        val entitlements: Entitlements? = null
    ) {
        val grantsFullAppAccess: Boolean
            get() = entitlements?.businessSponsoredPro == true

        fun openAccessEnabled(orgId: String): Boolean =
            operationSettingsByOrg[orgId]?.openAccessEnabled == true

        fun useRooms(orgId: String): Boolean =
            operationSettingsByOrg[orgId]?.useRooms == true

        fun roomName(occurrence: Occurrence): String? {
            val id = occurrence.roomId
            if (!id.isNullOrBlank()) {
                facilityRooms.firstOrNull { it.id == id }?.name?.let { return it }
            }
            return occurrence.location?.takeIf { it.isNotBlank() }
        }
        val isLinkedOrInvited: Boolean
            get() = athleteCenterIds.isNotEmpty() || invitations.isNotEmpty()

        fun centerName(id: String): String =
            centers.firstOrNull { it.id == id }?.name ?: "Centro"

        fun clientIdFor(orgId: String): String? =
            clientLinks.firstOrNull { it.orgId == orgId }?.id
                ?: passes.firstOrNull { it.orgId == orgId }?.clientId
                ?: notices.firstOrNull { it.orgId == orgId }?.clientId

        fun bookingFor(occurrenceId: String): Booking? =
            bookings.firstOrNull {
                it.occurrenceId == occurrenceId && (it.status == "booked" || it.status == "waitlist")
            }

        fun remainingPlaces(occurrence: Occurrence): Int? {
            val item = availability[occurrence.id] ?: return null
            return (item.capacity - item.reserved).coerceAtLeast(0)
        }

        fun bookingOpensAt(occurrence: Occurrence): Instant? {
            val start = parseInstant(occurrence.startsAt) ?: return null
            val hours = centers.firstOrNull { it.id == occurrence.orgId }?.classBookingOpenHours ?: 168
            val opens = start.minusSeconds(hours.coerceAtLeast(1).toLong() * 3600L)
            return if (opens.isAfter(Instant.now())) opens else null
        }

        fun canBookNow(occurrence: Occurrence): Boolean =
            bookingOpensAt(occurrence) == null &&
                (parseInstant(occurrence.startsAt)?.isAfter(Instant.now()) == true) &&
                occurrence.status == "active"

        fun activePasses(orgId: String): List<Pass> =
            passes.filter { it.orgId == orgId && it.status == "active" }

        fun availablePasses(occurrence: Occurrence): List<Pass> {
            val begins = parseInstant(occurrence.startsAt) ?: return emptyList()
            return passes.filter { pass ->
                val kindOk = pass.kind == occurrence.kind ||
                    (occurrence.kind == "open_access" && pass.kind == "class")
                pass.orgId == occurrence.orgId && kindOk &&
                    pass.status == "active" && pass.remainingCredits > 0 &&
                    (parseInstant(pass.validFrom) ?: Instant.MAX) <= begins &&
                    (parseInstant(pass.validUntil) ?: Instant.EPOCH) >= begins
            }
        }

        fun offerName(pass: Pass): String? =
            pass.offerId?.let { oid -> passOffers.firstOrNull { it.id == oid }?.name }

        fun paymentHistory(orgId: String): List<Pass> =
            passes.filter { it.orgId == orgId }
                .sortedByDescending { parseInstant(it.paidAt ?: it.validFrom) ?: Instant.EPOCH }

        fun pastBookings(orgId: String): List<Booking> {
            val occById = occurrences.associateBy { it.id }
            return bookings.filter { booking ->
                if (booking.orgId != orgId) return@filter false
                val occ = occById[booking.occurrenceId] ?: return@filter false
                val start = parseInstant(occ.startsAt) ?: return@filter false
                start.isBefore(Instant.now()) ||
                    booking.status == "attended" ||
                    booking.status == "cancelled" ||
                    booking.status == "no_show"
            }.sortedByDescending { booking ->
                parseInstant(occById[booking.occurrenceId]?.startsAt) ?: Instant.EPOCH
            }
        }

        fun classTrainingSession(occurrenceId: String, clientId: String? = null): ProfessionalSession? {
            if (clientId != null) {
                trainingSessions.firstOrNull {
                    it.sourceOccurrenceId == occurrenceId && it.clientId == clientId
                }?.let { return it }
            }
            return trainingSessions.firstOrNull { it.sourceOccurrenceId == occurrenceId }
        }

        fun classPrescription(occurrence: Occurrence, clientId: String? = null): JSONObject? {
            classTrainingSession(occurrence.id, clientId)?.prescription
                ?.takeIf { isCanonicalPrescription(it) }
                ?.let { return it }
            return occurrence.prescription?.takeIf { isCanonicalPrescription(it) }
        }

        fun classPlanSummary(occurrence: Occurrence, clientId: String? = null): String? {
            val rx = classPrescription(occurrence, clientId) ?: return null
            val blocks = rx.optJSONArray("blocks") ?: return null
            val title = classTrainingSession(occurrence.id, clientId)?.title
                ?.takeIf { it.isNotBlank() }
                ?: occurrence.trainingTitle?.takeIf { it.isNotBlank() }
                ?: occurrence.title
            return "$title · ${blocks.length()} bloq."
        }

        fun asClassPlanSession(
            occurrence: Occurrence,
            clientId: String? = null
        ): ProfessionalSession? {
            classTrainingSession(occurrence.id, clientId)
                ?.takeIf { isCanonicalPrescription(it.prescription) }
                ?.let { return it }
            val rx = occurrence.prescription?.takeIf { isCanonicalPrescription(it) } ?: return null
            val day = runCatching {
                Instant.parse(occurrence.startsAt).atZone(ZoneId.systemDefault()).toLocalDate().toString()
            }.getOrElse { LocalDate.now().toString() }
            return ProfessionalSession(
                id = occurrence.id,
                orgId = occurrence.orgId,
                clientId = clientId.orEmpty(),
                coachUserId = "",
                scheduledDate = day,
                title = occurrence.trainingTitle?.takeIf { it.isNotBlank() } ?: occurrence.title,
                instructions = occurrence.trainingInstructions.orEmpty(),
                status = "scheduled",
                prescription = rx,
                sourceOccurrenceId = occurrence.id
            )
        }
    }

    companion object {
        fun isCanonicalPrescription(prescription: JSONObject?): Boolean {
            if (prescription == null) return false
            if (prescription.optInt("schemaVersion") != 1 && prescription.optInt("version") != 1) return false
            return (prescription.optJSONArray("blocks")?.length() ?: 0) > 0
        }
    }

    sealed class LoadResult {
        data class Loaded(val snapshot: Snapshot) : LoadResult()
        data class Failed(val message: String) : LoadResult()
    }

    /** Mensaje corto para UI: nunca volcar JSON/PostgREST crudo. */
    private fun friendlyCentersLoadError(error: Exception): String {
        val raw = error.localizedMessage.orEmpty()
        return when {
            raw.contains("PGRST201", ignoreCase = true)
                || raw.contains("more than one relationship", ignoreCase = true) ->
                "No se han podido cargar tus centros y reservas. Actualiza la app e inténtalo de nuevo."
            raw.contains("PGRST", ignoreCase = true)
                || raw.contains("\"code\"")
                || raw.length > 140 ->
                "No se han podido cargar tus centros y reservas. Comprueba la conexión e inténtalo de nuevo."
            else -> "No se han podido cargar tus centros y reservas."
        }
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
                    params: JSONObject, expectTrue: Boolean = false): JSONArray {
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
            if (expectTrue && body.trim() != "true") {
                throw IllegalStateException("No se ha confirmado la desvinculación. Inténtalo de nuevo.")
            }
            return if (body.startsWith("[")) JSONArray(body) else JSONArray()
        }
    }

    /** Port de BusinessDataStore.refresh(): mismas consultas y filtros. */
    fun refresh(session: SupabaseIdentity.Session): LoadResult {
        return try {
            val currentUser = session.userId
            val centers = parseOrganizations(get(session, "organizations",
                "id,name,kind,slug,avatar_url,tagline,public_email,phone,class_booking_open_hours"))
            val invitations = parseInvitations(get(session, "organization_invitations",
                "id,organization_id,invited_role,expires_at,accepted_at,cancelled_at"))
            val links = parseLinks(get(session, "clients", "id,org_id,user_id"))
            val myLinks = links.filter { it.userId == currentUser }
            val ownedClientIds = myLinks.map { it.id }.toSet()
            val occurrences = parseOccurrences(get(session, "service_occurrences",
                "id,org_id,kind,title,starts_at,ends_at,capacity,status,room_id," +
                    "service_occurrence_details!service_occurrence_details_occurrence_id_fkey(" +
                    "color,location,training_title,training_instructions,prescription)"))
            val passes = parsePasses(get(session, "service_passes",
                "id,org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,status," +
                    "issuance_type,payment_method,paid_at,paid_amount_cents,offer_id"))
            val offers = parseOffers(get(session, "business_pass_offers",
                "id,org_id,name,kind,is_active"))
            val bookings = parseBookings(get(session, "service_bookings",
                "id,org_id,client_id,occurrence_id,status"))
            val notices=parseNotices(get(session,"business_client_notifications","id,org_id,client_id,title,body,created_at"))
            val training=parseProfessionalSessions(get(session,"professional_training_sessions",
                "id,org_id,client_id,coach_user_id,scheduled_date,scheduled_time_minutes,title,instructions,prescription,status,source_occurrence_id"))
            val counts = mutableMapOf<String, Availability>()
            val settingsByOrg = mutableMapOf<String, OperationSettings>()
            val roomsAcc = mutableListOf<FacilityRoom>()
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
                loadScheduleBundle(session, center.id)?.let { (settings, rooms) ->
                    settingsByOrg[center.id] = settings
                    roomsAcc.addAll(rooms)
                }
            }
            val now = Instant.now()
            val linkedIds = myLinks.map { it.orgId }.toSet()
            val entitlements = refreshEntitlements(session)
            LoadResult.Loaded(Snapshot(
                centers = centers,
                invitations = invitations.filter {
                    it.acceptedAt == null && it.cancelledAt == null &&
                        (parseInstant(it.expiresAt) ?: Instant.MAX) > now
                },
                athleteCenterIds = linkedIds,
                clientLinks = myLinks,
                occurrences = occurrences.filter { it.status == "active" },
                operationSettingsByOrg = settingsByOrg,
                facilityRooms = roomsAcc,
                passes = passes.filter { it.clientId in ownedClientIds },
                passOffers = offers.filter { it.isActive && it.orgId in linkedIds },
                bookings = bookings.filter { it.clientId in ownedClientIds },
                availability = counts,notices=ownedNotices(notices,ownedClientIds),
                trainingSessions=ownedTraining(training,ownedClientIds),
                entitlements = entitlements))
        } catch (error: Exception) {
            LoadResult.Failed(friendlyCentersLoadError(error))
        }
    }

    /** Port de BusinessDataStore.refreshEntitlements → get_my_effective_entitlements (jsonb). */
    fun refreshEntitlements(session: SupabaseIdentity.Session): Entitlements? {
        return try {
            val request = Request.Builder()
                .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/get_my_effective_entitlements")
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .header("Content-Type", "application/json")
                .post("{}".toRequestBody("application/json".toMediaType()))
                .build()
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful || body.isBlank()) return null
                val root = when {
                    body.trimStart().startsWith("{") -> JSONObject(body)
                    body.trimStart().startsWith("[") -> JSONArray(body).optJSONObject(0) ?: return null
                    else -> return null
                }
                val sponsors = root.optJSONArray("sponsors")
                val sponsorName = sponsors?.optJSONObject(0)?.optString("org_name")
                    ?.takeIf { it.isNotBlank() }
                Entitlements(
                    effectivePro = root.optBoolean("effective_pro", false),
                    storePro = root.optBoolean("store_pro", false),
                    businessSponsoredPro = root.optBoolean("business_sponsored_pro", false),
                    storeGatePending = root.optBoolean("store_gate_pending", true),
                    primarySponsorName = sponsorName
                )
            }
        } catch (_: Exception) {
            null
        }
    }

    fun loadClassRoster(session: SupabaseIdentity.Session, occurrenceId: String): ClassRoster? {
        return try {
            val request = Request.Builder()
                .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/class_occurrence_roster")
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .header("Content-Type", "application/json")
                .post(JSONObject().put("p_occurrence", occurrenceId).toString()
                    .toRequestBody("application/json".toMediaType()))
                .build()
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful || body.isBlank()) return null
                val root = when {
                    body.startsWith("{") -> JSONObject(body)
                    body.startsWith("[") -> JSONArray(body).optJSONObject(0) ?: return null
                    else -> return null
                }
                parseRoster(root)
            }
        } catch (_: Exception) {
            null
        }
    }

    /** Port de BusinessDataStore.loadInvitationPreview (RPC get_my_invitation_preview). */
    fun loadInvitationPreview(session: SupabaseIdentity.Session, invitationId: String): InvitationPreviewResult {
        val id = runCatching { UUID.fromString(invitationId).toString() }.getOrNull()
            ?: return InvitationPreviewResult.Unavailable
        return try {
            val request = Request.Builder()
                .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/get_my_invitation_preview")
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .header("Content-Type", "application/json")
                .post(JSONObject().put("p_invitation_id", id).toString()
                    .toRequestBody("application/json".toMediaType()))
                .build()
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful) {
                    return if (response.code in 400..499) InvitationPreviewResult.Unavailable
                    else InvitationPreviewResult.Failed
                }
                parseInvitationPreview(body)?.takeIf { it.invitationId.equals(id, ignoreCase = true) }
                    ?.let { InvitationPreviewResult.Found(it) }
                    ?: InvitationPreviewResult.Failed
            }
        } catch (_: java.io.IOException) {
            InvitationPreviewResult.Offline
        } catch (_: Exception) {
            InvitationPreviewResult.Failed
        }
    }

    internal fun parseInvitationPreview(body: String): InvitationPreview? = runCatching {
        val row = JSONObject(body.trim())
        InvitationPreview(
            invitationId = row.getString("invitation_id"),
            organizationId = row.getString("organization_id"),
            organizationName = row.optString("organization_name"),
            organizationKind = row.optString("organization_kind"),
            organizationTagline = row.optString("organization_tagline").takeIf { it.isNotBlank() && it != "null" },
            expiresAt = row.optString("expires_at").takeIf { it.isNotBlank() && it != "null" })
    }.getOrNull()

    fun searchDirectory(session:SupabaseIdentity.Session,query:String):List<Organization> =
        parseOrganizations(rpc(session,"search_discoverable_organizations",JSONObject().put("p_query",query)))

    fun requestLink(session:SupabaseIdentity.Session,organization:Organization,passKind:String,note:String?) {
        require(passKind in setOf("class","appointment","unlimited"))
        // El backend solo acepta class|appointment; unlimited → appointment (PT).
        val kind=if(passKind=="unlimited") "appointment" else passKind
        rpc(session,"request_org_athlete_link",JSONObject().put("p_org",organization.id)
            .put("p_pass_kind",kind).put("p_note",note.orEmpty()))
    }
    fun leave(session:SupabaseIdentity.Session,organization:Organization) {
        try {
            rpc(session,"leave_org_as_athlete",JSONObject().put("p_org",organization.id),
                expectTrue = true)
            ReperaAnalytics.track(
                ReperaAnalytics.Event.CENTER_UNLINKED,
                mapOf("feature_area" to "center", "result" to "success")
            )
        } catch (error: IllegalStateException) {
            val reason = error.message.orEmpty()
            val message = when {
                "NOT_LINKED_CLIENT" in reason || "NOT_LINKED_ATHLETE" in reason ->
                    "Ya no tienes una vinculación activa como cliente con este centro."
                "No se ha confirmado la desvinculación" in reason -> reason
                else -> "No se ha podido completar la desvinculación. Comprueba tu conexión e inténtalo de nuevo."
            }
            throw IllegalStateException(message, error)
        }
    }

    fun decline(session: SupabaseIdentity.Session, invitation: Invitation) {
        rpc(session, "decline_org_invitation",
            JSONObject().put("p_invitation_id", invitation.id))
    }

    fun book(session: SupabaseIdentity.Session, occurrence: Occurrence, pass: Pass) {
        val serviceKind = if (occurrence.kind == "appointment") "appointment" else "class"
        ReperaAnalytics.track(
            ReperaAnalytics.Event.CLASS_BOOKING_REQUESTED,
            mapOf(
                "feature_area" to "center",
                "service_kind" to serviceKind,
                "result" to "pending"
            )
        )
        val intent = "book:${session.userId}:${occurrence.id}:${pass.id}"
        try {
            idempotentRpc(session, intent, "book_service_occurrence", JSONObject()
                .put("p_occurrence", occurrence.id)
                .put("p_pass", pass.id))
        } catch (error: Exception) {
            ReperaAnalytics.track(
                ReperaAnalytics.Event.OPERATION_FAILED,
                mapOf(
                    "feature_area" to "center",
                    "error_code" to "booking_failed",
                    "result" to "failure"
                )
            )
            throw error
        }
        // Status (booked vs waitlist) is resolved after refreshCenter().
        ReperaAnalytics.track(
            if (occurrence.kind == "appointment") ReperaAnalytics.Event.APPOINTMENT_CONFIRMED
            else ReperaAnalytics.Event.CLASS_BOOKING_CONFIRMED,
            mapOf(
                "feature_area" to "center",
                "service_kind" to serviceKind,
                "result" to "success"
            )
        )
    }

    fun cancel(session: SupabaseIdentity.Session, booking: Booking) {
        idempotentRpc(session, "cancel:${session.userId}:${booking.id}", "cancel_service_booking",
            JSONObject().put("p_booking", booking.id))
        ReperaAnalytics.track(
            ReperaAnalytics.Event.CLASS_BOOKING_CANCELLED,
            mapOf(
                "feature_area" to "center",
                "service_kind" to "class",
                "result" to "success"
            )
        )
    }

    fun accept(session: SupabaseIdentity.Session, invitation: Invitation) {
        ReperaAnalytics.track(
            ReperaAnalytics.Event.CENTER_INVITE_OPENED,
            mapOf("feature_area" to "center", "result" to "pending")
        )
        rpc(session, "accept_org_invitation",
            JSONObject().put("p_invitation_id", invitation.id))
        ReperaAnalytics.track(
            ReperaAnalytics.Event.CENTER_LINK_COMPLETED,
            mapOf("feature_area" to "center", "result" to "success")
        )
    }

    /** Retries of the same intent reuse `p_request` until the server answers (RPCs are idempotent per id). */
    private fun idempotentRpc(session: SupabaseIdentity.Session, intent: String, fn: String, params: JSONObject) {
        try {
            rpc(session, fn, params.put("p_request", PendingRequestIds.reuse(intent)))
        } catch (error: Exception) {
            if ("REQUEST_ID_REUSED" in error.message.orEmpty()) PendingRequestIds.confirm(intent)
            throw error
        }
        PendingRequestIds.confirm(intent)
    }

    internal object PendingRequestIds {
        private const val TTL_MS = 24L * 60 * 60 * 1000
        private val ids = java.util.concurrent.ConcurrentHashMap<String, Pair<String, Long>>()

        fun reuse(intent: String, now: Long = System.currentTimeMillis()): String {
            ids.entries.removeIf { now - it.value.second >= TTL_MS }
            return ids.computeIfAbsent(intent) { UUID.randomUUID().toString() to now }.first
        }

        fun confirm(intent: String) { ids.remove(intent) }
    }

    fun sendMessage(session:SupabaseIdentity.Session,orgId:String,title:String,body:String) {
        // Compat: avisos legacy; el chat nativo usa sendChatMessage.
        require(orgId.isNotBlank() && body.trim().length>=2)
        rpc(session,"athlete_send_org_message",JSONObject().put("p_org",orgId)
            .put("p_title",title.trim().ifEmpty {"Mensaje"}).put("p_body",body.trim()))
    }

    fun loadThread(session: SupabaseIdentity.Session, orgId: String, clientId: String): List<ChatMessage> {
        val rows = rpc(session, "business_list_thread", JSONObject()
            .put("p_org", orgId).put("p_client", clientId).put("p_limit", 80))
        return parseChatMessages(rows).sortedBy { it.createdAt }
    }

    fun sendChatMessage(session: SupabaseIdentity.Session, orgId: String, clientId: String, body: String) {
        require(body.trim().isNotEmpty())
        rpc(session, "business_send_message", JSONObject()
            .put("p_org", orgId).put("p_client", clientId).put("p_body", body.trim()))
    }

    fun markThreadRead(session: SupabaseIdentity.Session, orgId: String, clientId: String) {
        rpc(session, "business_mark_thread_read",
            JSONObject().put("p_org", orgId).put("p_client", clientId))
    }

    fun registerPushToken(session: SupabaseIdentity.Session, token: String, platform: String = "android") {
        if (token.length < 10) return
        rpc(session, "register_push_device", JSONObject()
            .put("p_platform", platform).put("p_token", token).put("p_environment", "production"))
    }

    private fun parseChatMessages(data: JSONArray): List<ChatMessage> =
        (0 until data.length()).map { i ->
            val r = data.getJSONObject(i)
            ChatMessage(
                r.getString("id"), r.getString("org_id"), r.getString("client_id"),
                r.getString("sender_user_id"), r.optString("sender_role"),
                r.getString("body"), r.getString("created_at"),
                r.optString("batch_id").ifBlank { null }
            )
        }
    internal fun ownedNotices(rows:List<Notice>,owned:Set<String>)=rows.filter {it.clientId in owned}
    internal fun ownedTraining(rows:List<ProfessionalSession>,owned:Set<String>)=rows.filter {it.clientId in owned && it.status=="scheduled"}.sortedBy {it.scheduledDate}
    internal fun parseNotices(data:JSONArray):List<Notice> = (0 until data.length()).map { i ->
        val r=data.getJSONObject(i)
        Notice(r.getString("id"),r.getString("org_id"),r.getString("client_id"),r.getString("title"),r.getString("body"),r.getString("created_at"))
    }
    internal fun parseProfessionalSessions(data:JSONArray):List<ProfessionalSession> = (0 until data.length()).map { i ->
        val r=data.getJSONObject(i)
        ProfessionalSession(r.getString("id"),r.getString("org_id"),r.getString("client_id"),r.getString("coach_user_id"),
            r.getString("scheduled_date"),r.getString("title"),r.getString("instructions"),r.getString("status"),
            r.optJSONObject("prescription"),
            r.optString("source_occurrence_id").ifBlank { null },
            if (r.has("scheduled_time_minutes") && !r.isNull("scheduled_time_minutes"))
                r.optInt("scheduled_time_minutes") else null)
    }

    private fun parseOrganizations(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Organization(row.getString("id"), row.optString("name"),
            row.optString("kind"), row.optString("slug").ifBlank { null },
            row.optString("avatar_url").ifBlank { null },
            row.optString("tagline").ifBlank { null },
            row.optString("public_email").ifBlank { null },
            row.optString("phone").ifBlank { null },
            row.optInt("class_booking_open_hours", 168))
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

    private fun loadScheduleBundle(
        session: SupabaseIdentity.Session,
        orgId: String
    ): Pair<OperationSettings, List<FacilityRoom>>? {
        return try {
            val request = Request.Builder()
                .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/get_org_schedule_bundle")
                .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                .header("Authorization", "Bearer " + session.accessToken)
                .header("Content-Type", "application/json")
                .post(JSONObject().put("p_org", orgId).toString()
                    .toRequestBody("application/json".toMediaType()))
                .build()
            http.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful || body.isBlank()) return null
                val root = when {
                    body.startsWith("{") -> JSONObject(body)
                    body.startsWith("[") -> JSONArray(body).optJSONObject(0) ?: return null
                    else -> return null
                }
                val settingsJson = root.optJSONObject("settings") ?: JSONObject()
                val settings = OperationSettings(
                    orgId = settingsJson.optString("org_id").ifBlank { orgId },
                    profile = settingsJson.optString("profile").ifBlank { null },
                    useRooms = settingsJson.optBoolean("use_rooms", false),
                    dayProgramEnabled = settingsJson.optBoolean("day_program_enabled", true),
                    openAccessEnabled = settingsJson.optBoolean("open_access_enabled", false),
                    openAccessRequiresBooking = settingsJson.optBoolean("open_access_requires_booking", true),
                    cancelCreditHours = settingsJson.optInt("cancel_credit_hours", 12)
                )
                val roomsArr = root.optJSONArray("rooms") ?: JSONArray()
                val rooms = (0 until roomsArr.length()).map { i ->
                    val r = roomsArr.getJSONObject(i)
                    FacilityRoom(
                        r.getString("id"),
                        r.optString("org_id").ifBlank { orgId },
                        r.optString("name"),
                        r.optInt("capacity", 20)
                    )
                }
                settings to rooms
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun parseOccurrences(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        val details = row.optJSONObject("service_occurrence_details")
            ?: row.optJSONArray("service_occurrence_details")?.optJSONObject(0)
        Occurrence(
            row.getString("id"), row.getString("org_id"),
            row.optString("kind"), row.optString("title"),
            row.getString("starts_at"),
            row.optString("ends_at").ifBlank { null },
            row.optInt("capacity").takeIf { row.has("capacity") && !row.isNull("capacity") },
            row.optString("status"),
            details?.optString("color")?.ifBlank { null } ?: row.optString("color").ifBlank { null },
            details?.optString("location")?.ifBlank { null } ?: row.optString("location").ifBlank { null },
            row.optString("room_id").ifBlank { null },
            details?.optString("training_title")?.ifBlank { null },
            details?.optString("training_instructions")?.ifBlank { null },
            details?.optJSONObject("prescription")
        )
    }

    private fun parsePasses(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Pass(row.getString("id"), row.getString("org_id"), row.getString("client_id"),
            row.optString("kind"), row.optInt("total_credits"),
            row.optInt("remaining_credits"),
            row.optString("valid_from").ifBlank { null },
            row.optString("valid_until").ifBlank { null },
            row.optString("status"),
            row.optString("offer_id").ifBlank { null },
            row.optString("paid_at").ifBlank { null },
            row.optInt("paid_amount_cents").takeIf { row.has("paid_amount_cents") && !row.isNull("paid_amount_cents") },
            row.optString("payment_method").ifBlank { null },
            row.optString("issuance_type").ifBlank { null })
    }

    private fun parseOffers(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        PassOffer(
            row.getString("id"), row.getString("org_id"), row.optString("name"),
            row.optString("kind"), row.optBoolean("is_active", true)
        )
    }

    private fun parseRoster(root: JSONObject): ClassRoster {
        val coachObj = root.optJSONObject("coach")
        val coach = coachObj?.let {
            ClassRosterPerson(
                it.optString("display_name").ifBlank { "Entrenador" },
                it.optString("avatar_url").ifBlank { null }
            )
        }
        val attendeesArr = root.optJSONArray("attendees") ?: JSONArray()
        val attendees = (0 until attendeesArr.length()).map { i ->
            val p = attendeesArr.getJSONObject(i)
            ClassRosterPerson(
                p.optString("display_name").ifBlank { "Socio" },
                p.optString("avatar_url").ifBlank { null },
                p.optString("status").ifBlank { null }
            )
        }
        return ClassRoster(
            occurrenceId = root.optString("occurrence_id").ifBlank { null },
            coach = coach,
            attendees = attendees,
            capacity = root.optInt("capacity").takeIf { root.has("capacity") && !root.isNull("capacity") },
            reserved = root.optInt("reserved").takeIf { root.has("reserved") && !root.isNull("reserved") }
        )
    }

    private fun parseBookings(data: JSONArray) = (0 until data.length()).map { i ->
        val row = data.getJSONObject(i)
        Booking(row.getString("id"), row.getString("org_id"), row.getString("client_id"),
            row.getString("occurrence_id"), row.optString("status"))
    }
}
