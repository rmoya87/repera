import Foundation
import Observation
import Supabase
import UserNotifications

/// Professional data read through the verified Supabase Auth session and row-level security.
/// Only athlete-owned completed-workout results are mirrored to Supabase
/// by BusinessWorkoutSyncStore; coaches see them only with explicit consent.
/// HealthKit/location remain local/iCloud and private.
struct BusinessOrganization: Decodable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let kind: String
    let slug: String?
    let avatarUrl: String?
    let tagline: String?
    /// Contacto público del centro (visible al atleta vinculado).
    var publicEmail: String?
    var phone: String?
    /// Horas antes del inicio en las que se puede apuntar (default 168 = 7 días).
    var classBookingOpenHours: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, kind, slug, tagline, phone
        case avatarUrl = "avatar_url"
        case publicEmail = "public_email"
        case classBookingOpenHours = "class_booking_open_hours"
    }

    var kindLabel: String {
        switch kind {
        case "personal_trainer": return "Entrenador"
        case "gym": return "Gimnasio"
        case "sports_center": return "Centro deportivo"
        default: return "Centro"
        }
    }

    var isTrainer: Bool { kind == "personal_trainer" }
}
struct BusinessInvitation: Decodable, Identifiable {
    let id: UUID
    let organizationId: UUID
    let invitedRole: String
    let expiresAt: String
    let acceptedAt: String?
    let cancelledAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case invitedRole = "invited_role"
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
        case cancelledAt = "cancelled_at"
    }
}

/// Preview segura de una invitación (nombre del centro) para Ajustes / deep link.
struct BusinessInvitationPreview: Decodable, Hashable {
    let invitationId: UUID
    let organizationId: UUID
    let organizationName: String
    let organizationKind: String
    let organizationAvatarUrl: String?
    let organizationTagline: String?
    let invitedRole: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case invitationId = "invitation_id"
        case organizationId = "organization_id"
        case organizationName = "organization_name"
        case organizationKind = "organization_kind"
        case organizationAvatarUrl = "organization_avatar_url"
        case organizationTagline = "organization_tagline"
        case invitedRole = "invited_role"
        case expiresAt = "expires_at"
    }

    var kindLabel: String {
        switch organizationKind {
        case "personal_trainer": return "Entrenador"
        case "gym": return "Gimnasio"
        case "sports_center": return "Centro deportivo"
        default: return "Centro"
        }
    }
}
struct BusinessOperationSettings: Decodable, Hashable {
    var orgId: UUID?
    var profile: String?
    var useRooms: Bool?
    var dayProgramEnabled: Bool?
    var dayProgramScope: String?
    var openAccessEnabled: Bool?
    var openAccessRequiresBooking: Bool?
    var cancelCreditHours: Int?

    enum CodingKeys: String, CodingKey {
        case profile
        case orgId = "org_id"
        case useRooms = "use_rooms"
        case dayProgramEnabled = "day_program_enabled"
        case dayProgramScope = "day_program_scope"
        case openAccessEnabled = "open_access_enabled"
        case openAccessRequiresBooking = "open_access_requires_booking"
        case cancelCreditHours = "cancel_credit_hours"
    }
}

struct BusinessFacilityRoom: Decodable, Identifiable, Hashable {
    let id: UUID
    let orgId: UUID
    let name: String
    let capacity: Int
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, capacity
        case orgId = "org_id"
        case isActive = "is_active"
    }
}

struct BusinessOccurrence: Decodable, Identifiable, Hashable {
    let id: UUID
    let orgId: UUID
    let kind: String
    let title: String
    let startsAt: String
    let endsAt: String
    let capacity: Int
    let status: String
    /// Color del calendario (`service_occurrence_details.color`).
    var color: String?
    var location: String?
    var coachUserId: UUID?
    var roomId: UUID?
    var activityTypeId: UUID?
    var seriesId: UUID?
    /// Prescripción asociada a la clase (plantilla del occurrence).
    var trainingTitle: String?
    var trainingInstructions: String?
    var prescription: BusinessPrescription?

    enum CodingKeys: String, CodingKey {
        case id, kind, title, capacity, status, color, location
        case orgId = "org_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case coachUserId = "coach_user_id"
        case roomId = "room_id"
        case activityTypeId = "activity_type_id"
        case seriesId = "series_id"
        case details = "service_occurrence_details"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        orgId = try c.decode(UUID.self, forKey: .orgId)
        kind = try c.decode(String.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title)
        startsAt = try c.decode(String.self, forKey: .startsAt)
        endsAt = try c.decode(String.self, forKey: .endsAt)
        capacity = try c.decode(Int.self, forKey: .capacity)
        status = try c.decode(String.self, forKey: .status)
        coachUserId = try c.decodeIfPresent(UUID.self, forKey: .coachUserId)
        roomId = try c.decodeIfPresent(UUID.self, forKey: .roomId)
        activityTypeId = try c.decodeIfPresent(UUID.self, forKey: .activityTypeId)
        seriesId = try c.decodeIfPresent(UUID.self, forKey: .seriesId)
        if let embedded = try? c.decodeIfPresent(OccurrenceDetailsEmbed.self, forKey: .details) {
            color = embedded.color
            location = embedded.location
            trainingTitle = embedded.trainingTitle
            trainingInstructions = embedded.trainingInstructions
            prescription = embedded.prescription
        } else if let list = try? c.decodeIfPresent([OccurrenceDetailsEmbed].self, forKey: .details),
                  let first = list.first {
            color = first.color
            location = first.location
            trainingTitle = first.trainingTitle
            trainingInstructions = first.trainingInstructions
            prescription = first.prescription
        } else {
            color = try c.decodeIfPresent(String.self, forKey: .color)
            location = try c.decodeIfPresent(String.self, forKey: .location)
            trainingTitle = nil
            trainingInstructions = nil
            prescription = nil
        }
    }

    private struct OccurrenceDetailsEmbed: Decodable {
        let color: String?
        let location: String?
        let trainingTitle: String?
        let trainingInstructions: String?
        let prescription: BusinessPrescription?

        enum CodingKeys: String, CodingKey {
            case color, location, prescription
            case trainingTitle = "training_title"
            case trainingInstructions = "training_instructions"
        }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: BusinessOccurrence, rhs: BusinessOccurrence) -> Bool { lhs.id == rhs.id }
}
struct BusinessPass: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let kind: String
    let totalCredits: Int
    let remainingCredits: Int
    let validFrom: String
    let validUntil: String
    let status: String
    var issuanceType: String?
    var paymentMethod: String?
    var paidAt: String?
    var paidAmountCents: Int?
    var offerId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, kind, status
        case orgId = "org_id"
        case clientId = "client_id"
        case totalCredits = "total_credits"
        case remainingCredits = "remaining_credits"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
        case issuanceType = "issuance_type"
        case paymentMethod = "payment_method"
        case paidAt = "paid_at"
        case paidAmountCents = "paid_amount_cents"
        case offerId = "offer_id"
    }
}

struct BusinessClassRosterPerson: Decodable, Hashable, Identifiable {
    var id: String { "\(displayName)-\(avatarUrl ?? "")-\(status ?? "")" }
    let displayName: String
    let avatarUrl: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
    }
}

struct BusinessClassRoster: Decodable, Hashable {
    let occurrenceId: UUID?
    let coach: BusinessClassRosterPerson?
    let attendees: [BusinessClassRosterPerson]
    let capacity: Int?
    let reserved: Int?

    enum CodingKeys: String, CodingKey {
        case occurrenceId = "occurrence_id"
        case coach, attendees, capacity, reserved
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        occurrenceId = try c.decodeIfPresent(UUID.self, forKey: .occurrenceId)
        coach = try c.decodeIfPresent(BusinessClassRosterPerson.self, forKey: .coach)
        attendees = try c.decodeIfPresent([BusinessClassRosterPerson].self, forKey: .attendees) ?? []
        capacity = try c.decodeIfPresent(Int.self, forKey: .capacity)
        reserved = try c.decodeIfPresent(Int.self, forKey: .reserved)
    }
}
struct BusinessPassOffer: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let name: String
    let kind: String
    let credits: Int
    let validityDays: Int
    let priceCents: Int
    let currency: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, kind, credits, currency
        case orgId = "org_id"
        case validityDays = "validity_days"
        case priceCents = "price_cents"
        case isActive = "is_active"
    }

    var localizedPrice: String {
        (Double(priceCents) / 100).formatted(.currency(code: currency))
    }
}

struct BusinessAvailability: Decodable {
    let occurrenceId: UUID
    let reserved: Int
    let capacity: Int

    enum CodingKeys: String, CodingKey {
        case occurrenceId = "occurrence_id"
        case reserved, capacity
    }
}

struct BusinessBooking: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let occurrenceId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case orgId = "org_id"
        case clientId = "client_id"
        case occurrenceId = "occurrence_id"
    }
}
// Wire contract v1, intentionally separate from private ReperaStore work sessions.
// IDs and catalog keys are authored by the trainer and authenticated by Supabase.
struct BusinessPrescription: Decodable {
    let schemaVersion: Int?
    let blocks: [BusinessPrescriptionBlock]

    /// Prescripción ejecutable en Play (clase o entreno profesional).
    var isCanonicalV1: Bool { schemaVersion == 1 && !blocks.isEmpty }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, version, blocks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion)
            ?? c.decodeIfPresent(Int.self, forKey: .version)
        blocks = try c.decodeIfPresent([BusinessPrescriptionBlock].self, forKey: .blocks) ?? []
    }
}
struct BusinessPrescriptionBlock: Decodable, Identifiable {
    let id: UUID
    let title: String
    let kind: String
    let exercises: [BusinessPrescriptionEntry]
    let movements: [BusinessPrescriptionEntry]
    let wodFormat: String?
    let rounds: Int?
    let timeCapMinutes: Int?
    var entries: [BusinessPrescriptionEntry] { kind == "wod" ? movements : exercises }

    enum CodingKeys: String, CodingKey {
        case id, title, kind, exercises, movements, wodFormat, rounds, timeCapMinutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        kind = try c.decode(String.self, forKey: .kind)
        exercises = try c.decodeIfPresent([BusinessPrescriptionEntry].self, forKey: .exercises) ?? []
        movements = try c.decodeIfPresent([BusinessPrescriptionEntry].self, forKey: .movements) ?? []
        wodFormat = try c.decodeIfPresent(String.self, forKey: .wodFormat)
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds)
        timeCapMinutes = try c.decodeIfPresent(Int.self, forKey: .timeCapMinutes)
    }
}
struct BusinessPrescriptionEntry: Decodable, Identifiable {
    let id: UUID
    let source: String
    let catalogKey: String?
    let name: String
    let plannedSets: [BusinessPrescriptionSet]?
    let reps: Int?
    let notes: String?
    /// Paridad con WODMovement: descansos prescritos por el entrenador.
    let isRest: Bool?
    let restSeconds: Int?
}
struct BusinessPrescriptionSet: Decodable, Identifiable {
    let id: UUID
    let targetReps: Int
    let targetWeightKg: Double?
    let targetRir: Double?
}

struct BusinessProfessionalTrainingSession: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let coachUserId: UUID?
    let scheduledDate: String  // yyyy-MM-dd, date-only (never UTC-shifted)
    let scheduledTimeMinutes: Int?
    let sourceOccurrenceId: UUID?
    let title: String
    let instructions: String
    let status: String
    let prescription: BusinessPrescription?

    enum CodingKeys: String, CodingKey {
        case id, title, instructions, status, prescription
        case orgId = "org_id"
        case clientId = "client_id"
        case coachUserId = "coach_user_id"
        case scheduledDate = "scheduled_date"
        case scheduledTimeMinutes = "scheduled_time_minutes"
        case sourceOccurrenceId = "source_occurrence_id"
    }
}

struct BusinessClientNotification: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let title: String
    let body: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case orgId = "org_id"
        case clientId = "client_id"
        case createdAt = "created_at"
    }
}

struct BusinessConversationMessage: Decodable, Identifiable, Hashable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let senderUserId: UUID
    let senderRole: String
    let body: String
    let createdAt: String
    let readAt: String?
    let batchId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, body
        case orgId = "org_id"
        case clientId = "client_id"
        case senderUserId = "sender_user_id"
        case senderRole = "sender_role"
        case createdAt = "created_at"
        case readAt = "read_at"
        case batchId = "batch_id"
    }

    var isFromStaff: Bool { senderRole == "staff" }
}

struct BusinessEntitlementSponsor: Decodable, Identifiable, Hashable {
    let orgId: UUID
    let orgName: String
    let kind: String?
    let validUntil: String?
    let reason: String?

    var id: UUID { orgId }

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case orgName = "org_name"
        case kind
        case validUntil = "valid_until"
        case reason
    }
}

struct BusinessEntitlements: Decodable {
    let effectivePro: Bool
    let storePro: Bool
    let businessSponsoredPro: Bool
    let storeGatePending: Bool
    let sponsors: [BusinessEntitlementSponsor]

    enum CodingKeys: String, CodingKey {
        case effectivePro = "effective_pro"
        case storePro = "store_pro"
        case businessSponsoredPro = "business_sponsored_pro"
        case storeGatePending = "store_gate_pending"
        case sponsors
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        effectivePro = try c.decodeIfPresent(Bool.self, forKey: .effectivePro) ?? false
        storePro = try c.decodeIfPresent(Bool.self, forKey: .storePro) ?? false
        businessSponsoredPro = try c.decodeIfPresent(Bool.self, forKey: .businessSponsoredPro) ?? false
        storeGatePending = try c.decodeIfPresent(Bool.self, forKey: .storeGatePending) ?? true
        sponsors = try c.decodeIfPresent([BusinessEntitlementSponsor].self, forKey: .sponsors) ?? []
    }

    var primarySponsorName: String? { sponsors.first?.orgName }
}

struct BusinessClientLink: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let userId: UUID?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case userId = "user_id"
        case status
    }
}

private enum BusinessScheduleBundleError: Error { case malformed }

@MainActor
@Observable
final class BusinessDataStore {
    static let shared = BusinessDataStore()

    private(set) var centers: [BusinessOrganization] = []
    private(set) var athleteCenterIds: Set<UUID> = []
    private(set) var invitations: [BusinessInvitation] = []
    /// Previews por id de invitación (nombre del centro antes de aceptar).
    private(set) var invitationPreviews: [UUID: BusinessInvitationPreview] = [:]
    /// Tras aceptar por deep link, Ajustes puede abrir el centro recién vinculado.
    var pendingOpenLinkedCenterId: UUID?
    private(set) var occurrences: [BusinessOccurrence] = []
    /// Historical occurrences (including archived) only for confirmed attendance.
    private var attendanceOccurrences: [BusinessOccurrence] = []
    private(set) var operationSettingsByOrg: [UUID: BusinessOperationSettings] = [:]
    private(set) var facilityRooms: [BusinessFacilityRoom] = []
    private(set) var passes: [BusinessPass] = []
    private(set) var passOffers: [BusinessPassOffer] = []
    private(set) var bookings: [BusinessBooking] = []
    /// Revision of attendance visible to this authenticated athlete.
    private(set) var progressDataRevision = 0
    /// Attendance is deliberately not equated with sensor measurements.
    var attendedClassesForProgress: [ProgressAttendedClass] {
        let byID = Dictionary(uniqueKeysWithValues: attendanceOccurrences.map { ($0.id, $0) })
        return bookings.compactMap { booking in
            guard booking.status == "attended",
                  let occurrence = byID[booking.occurrenceId],
                  occurrence.kind == "class" || occurrence.kind == "appointment",
                  let start = Self.date(occurrence.startsAt),
                  let end = Self.date(occurrence.endsAt),
                  end >= start else { return nil }
            let linkedRoutine = historicalProfessionalSessions.first {
                $0.sourceOccurrenceId == occurrence.id && $0.clientId == booking.clientId
            }?.id
            return ProgressAttendedClass(
                bookingID: booking.id, occurrenceID: occurrence.id,
                linkedRoutineID: linkedRoutine, title: occurrence.title,
                startsAt: start, endsAt: end
            )
        }
    }
    private(set) var availability: [UUID: BusinessAvailability] = [:]
    private(set) var trainingSessions: [BusinessProfessionalTrainingSession] = []
    /// Historical professional assignments used only for attendance de-duplication.
    private var historicalProfessionalSessions: [BusinessProfessionalTrainingSession] = []
    private(set) var personalNotices: [BusinessClientNotification] = []
    private(set) var conversationMessages: [BusinessConversationMessage] = []
    private(set) var entitlements: BusinessEntitlements?
    private(set) var clientLinks: [BusinessClientLink] = []
    private(set) var directory: [BusinessOrganization] = []
    private(set) var isLoading = false
    private(set) var isSearchingDirectory = false
    @ObservationIgnored private var refreshRevision = 0
    /// Owner of the data currently in memory; a failed refresh only keeps it
    /// for this same user.
    @ObservationIgnored private var loadedUserID: UUID?
    private(set) var errorMessage: String?
    private(set) var isSubmitting = false

    /// Acceso completo en la app mientras el deportista está vinculado a un centro/entrenador.
    /// Pro patrocinado B2B vía entitlements de servidor (no basta con estar vinculado).
    var grantsFullAppAccess: Bool {
        entitlements?.businessSponsoredPro == true
    }

    private init() {}

    func clear() {
        // Invalidate every in-flight response before clearing PII from a previous user.
        refreshRevision &+= 1
        loadedUserID = nil
        isLoading = false
        BusinessBookingReminderScheduler.clear()
        centers = []
        athleteCenterIds = []
        invitations = []
        invitationPreviews = [:]
        pendingOpenLinkedCenterId = nil
        occurrences = []
        attendanceOccurrences = []
        operationSettingsByOrg = [:]
        facilityRooms = []
        passes = []
        passOffers = []
        bookings = []
        progressDataRevision &+= 1
        availability = [:]
        trainingSessions = []
        historicalProfessionalSessions = []
        NotificationCenter.default.post(name: Notification.Name("repera.professionalPlansChanged"), object: nil)
        personalNotices = []
        conversationMessages = []
        entitlements = nil
        clientLinks = []
        directory = []
        errorMessage = nil
    }

    func refresh() async {
        guard BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else {
            clear()
            return
        }
        guard !isLoading else { return }
        let revision = refreshRevision
        isLoading = true
        defer {
            if refreshRevision == revision { isLoading = false }
        }
        var sessionUserID: UUID?
        do {
            let user = try await client.auth.session.user
            let currentUser = user.id
            sessionUserID = currentUser
            let fetchedCenters: [BusinessOrganization] = try await client
                .from("organizations")
                .select("id,name,kind,slug,avatar_url,tagline,public_email,phone,class_booking_open_hours")
                .execute().value
            let fetchedInvitations: [BusinessInvitation] = try await client
                .from("organization_invitations")
                .select("id,organization_id,invited_role,expires_at,accepted_at,cancelled_at")
                .execute().value
            let fetchedLinks: [BusinessClientLink] = try await client
                .from("clients")
                .select("id,org_id,user_id,status")
                .execute().value
            let ownedClientIds = Set(fetchedLinks.filter { $0.userId == currentUser && $0.status == "active" }.map(\.id))
            // FK explícita: hay dos relaciones (occurrence_id PK y (org_id,occurrence_id)).
            let fetchedOccurrences: [BusinessOccurrence] = try await client
                .from("service_occurrences")
                .select("id,org_id,kind,title,starts_at,ends_at,capacity,status,coach_user_id,room_id,activity_type_id,series_id,service_occurrence_details!service_occurrence_details_occurrence_id_fkey(color,location,training_title,training_instructions,prescription)")
                .execute().value
            var settingsMap: [UUID: BusinessOperationSettings] = [:]
            var roomsAcc: [BusinessFacilityRoom] = []
            // One center's schedule failing must not hide the others; keep its
            // last known settings/rooms (same user only) and report it.
            var scheduleFailures = 0
            let keepsPrevious = loadedUserID == currentUser
            for center in fetchedCenters {
                do {
                    let response = try await client
                        .rpc("get_org_schedule_bundle", params: ["p_org": center.id.uuidString])
                        .execute()
                    guard let root = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] else {
                        throw BusinessScheduleBundleError.malformed
                    }
                    if let settingsObj = root["settings"],
                       let settingsData = try? JSONSerialization.data(withJSONObject: settingsObj),
                       let settings = try? JSONDecoder().decode(BusinessOperationSettings.self, from: settingsData) {
                        settingsMap[center.id] = settings
                    }
                    if let roomsObj = root["rooms"] as? [[String: Any]],
                       let roomsData = try? JSONSerialization.data(withJSONObject: roomsObj),
                       let rooms = try? JSONDecoder().decode([BusinessFacilityRoom].self, from: roomsData) {
                        roomsAcc.append(contentsOf: rooms)
                    }
                } catch {
                    if Self.isAuthorizationFailure(error) { throw error }
                    scheduleFailures += 1
                    if keepsPrevious {
                        settingsMap[center.id] = operationSettingsByOrg[center.id]
                        roomsAcc.append(contentsOf: facilityRooms.filter { $0.orgId == center.id })
                    }
                }
            }
            let fetchedPasses: [BusinessPass] = try await client
                .from("service_passes")
                .select("id,org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,status,issuance_type,payment_method,paid_at,paid_amount_cents,offer_id")
                .execute().value
            let fetchedOffers: [BusinessPassOffer] = try await client
                .from("business_pass_offers")
                .select("id,org_id,name,kind,credits,validity_days,price_cents,currency,is_active")
                .execute().value
            let fetchedBookings: [BusinessBooking] = try await client
                .from("service_bookings")
                .select("id,org_id,client_id,occurrence_id,status")
                .execute().value
            let fetchedTrainingSessions: [BusinessProfessionalTrainingSession] = try await client
                .from("professional_training_sessions")
                .select("id,org_id,client_id,coach_user_id,scheduled_date,scheduled_time_minutes,source_occurrence_id,title,instructions,prescription,status")
                .execute().value
            let fetchedNotices: [BusinessClientNotification] = try await client
                .from("business_client_notifications")
                .select("id,org_id,client_id,title,body,created_at")
                .execute().value
            // Capacity counts are authorized by org membership, never exposing
            // the identities or bookings of other athletes.
            var counts: [UUID: BusinessAvailability] = [:]
            for center in fetchedCenters {
                let occupancy: [BusinessAvailability] = try await client
                    .rpc("get_service_availability",
                         params: ["p_org": center.id.uuidString])
                    .execute().value
                for item in occupancy {
                    counts[item.occurrenceId] = item
                }
            }
            // A logout, account change or superseding refresh must not resurrect old data.
            guard revision == refreshRevision, BusinessAuthStore.shared.isConnected else { return }
            let activeUserID = try? await client.auth.session.user.id
            guard revision == refreshRevision,
                  BusinessAuthStore.shared.isConnected,
                  activeUserID == currentUser else { return }

            availability = counts
            centers = fetchedCenters
            clientLinks = fetchedLinks.filter { $0.userId == currentUser && $0.status == "active" }
            athleteCenterIds = Set(clientLinks.map(\.orgId))
            invitations = fetchedInvitations.filter { $0.acceptedAt == nil && $0.cancelledAt == nil && (Self.date($0.expiresAt) ?? .distantPast) > Date() }
            await loadInvitationPreviews(for: invitations.map(\.id))
            await refreshEntitlements()
            attendanceOccurrences = fetchedOccurrences
            occurrences = fetchedOccurrences.filter { $0.status == "active" }
            operationSettingsByOrg = settingsMap
            facilityRooms = roomsAcc
            passes = fetchedPasses.filter { ownedClientIds.contains($0.clientId) }
            passOffers = fetchedOffers.filter {
                $0.isActive && athleteCenterIds.contains($0.orgId)
            }
            bookings = fetchedBookings.filter { ownedClientIds.contains($0.clientId) }
            await BusinessBookingReminderScheduler.reconcile(
                userID: currentUser, bookings: bookings, occurrences: occurrences
            )
            progressDataRevision &+= 1
            personalNotices = fetchedNotices.filter { ownedClientIds.contains($0.clientId) }
            historicalProfessionalSessions = fetchedTrainingSessions.filter {
                ownedClientIds.contains($0.clientId)
            }
            trainingSessions = historicalProfessionalSessions.filter {
                $0.status == "scheduled"
            }.sorted { $0.scheduledDate < $1.scheduledDate }
            NotificationCenter.default.post(name: Notification.Name("repera.professionalPlansChanged"), object: nil)
            loadedUserID = currentUser
            errorMessage = scheduleFailures == 0 ? nil
                : "No se han podido cargar los horarios de algún centro. Mostramos los últimos datos disponibles."
            Task { await self.retryPendingPushTokenIfNeeded() }
        } catch {
            // A failed request belonging to a prior session cannot reset the new session.
            guard revision == refreshRevision else { return }
            // Only a rejected session/permission or a different user wipes the
            // data; a network error keeps the last good snapshot visible.
            if Self.isAuthorizationFailure(error)
                || loadedUserID == nil
                || sessionUserID.map({ $0 != loadedUserID }) == true {
                clear()
            }
            errorMessage = Self.friendlyCentersLoadError(error)
        }
    }

    /// 401/403-equivalent failures: missing/invalid session or RLS denial.
    static func isAuthorizationFailure(_ error: Error) -> Bool {
        if let auth = error as? AuthError {
            switch auth {
            case .sessionMissing, .jwtVerificationFailed:
                return true
            case .api(_, _, _, let response):
                return response.statusCode == 401 || response.statusCode == 403
            default:
                return false
            }
        }
        if let postgrest = error as? PostgrestError, let code = postgrest.code {
            return ["PGRST301", "PGRST302", "PGRST303", "42501"].contains(code)
        }
        if let http = error as? HTTPError {
            return http.response.statusCode == 401 || http.response.statusCode == 403
        }
        return false
    }

    /// Sesión materializada de una clase (fan-out) para el cliente apuntado, si existe.
    func classTrainingSession(for occurrenceId: UUID, clientId: UUID? = nil) -> BusinessProfessionalTrainingSession? {
        if let clientId,
           let match = trainingSessions.first(where: {
               $0.sourceOccurrenceId == occurrenceId && $0.clientId == clientId
           }) {
            return match
        }
        return trainingSessions.first { $0.sourceOccurrenceId == occurrenceId }
    }

    /// Prescripción de clase: sesión personal o plantilla en `service_occurrence_details`.
    func classPrescription(for occurrence: BusinessOccurrence, clientId: UUID? = nil) -> BusinessPrescription? {
        if let session = classTrainingSession(for: occurrence.id, clientId: clientId),
           let rx = session.prescription, rx.isCanonicalV1 {
            return rx
        }
        if let rx = occurrence.prescription, rx.isCanonicalV1 { return rx }
        return nil
    }

    /// Resumen corto para fichas de Inicio / Clases.
    func classPlanSummary(for occurrence: BusinessOccurrence, clientId: UUID? = nil) -> String? {
        guard let rx = classPrescription(for: occurrence, clientId: clientId) else { return nil }
        let title = classTrainingSession(for: occurrence.id, clientId: clientId)?.title
            ?? occurrence.trainingTitle
            ?? occurrence.title
        let n = rx.blocks.count
        return "\(title) · \(n) bloq."
    }

    /// Mensaje corto para UI: nunca volcar JSON/PostgREST crudo.
    private static func friendlyCentersLoadError(_ error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("PGRST201")
            || raw.localizedCaseInsensitiveContains("more than one relationship") {
            return "No se han podido cargar tus centros y reservas. Actualiza la app e inténtalo de nuevo."
        }
        if raw.localizedCaseInsensitiveContains("PGRST")
            || raw.contains("\"code\"")
            || raw.count > 140 {
            return "No se han podido cargar tus centros y reservas. Comprueba la conexión e inténtalo de nuevo."
        }
        return "No se han podido cargar tus centros y reservas."
    }

    private static let preciseISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let isoFormatter = ISO8601DateFormatter()

    static func date(_ value: String) -> Date? {
        preciseISOFormatter.date(from: value) ?? isoFormatter.date(from: value)
    }

    /// Gregorian calendar in the CURRENT time zone on every call (a cached
    /// DateFormatter would freeze the zone at first use).
    private static var dayKeyCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func localDayKey(_ date: Date) -> String {
        let parts = dayKeyCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func parseDayKey(_ key: String) -> Date? {
        let fields = key.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3, fields[0].count == 4, fields[1].count == 2, fields[2].count == 2,
              let year = Int(fields[0]), let month = Int(fields[1]), let day = Int(fields[2])
        else { return nil }
        let calendar = dayKeyCalendar
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        // Reject overflowing keys such as 2026-02-31 instead of rolling over.
        let check = calendar.dateComponents([.year, .month, .day], from: date)
        guard check.year == year, check.month == month, check.day == day else { return nil }
        return date
    }

    func centerName(_ id: UUID) -> String {
        centers.first(where: { $0.id == id })?.name
            ?? directory.first(where: { $0.id == id })?.name
            ?? "Centro deportivo"
    }

    func center(for id: UUID) -> BusinessOrganization? {
        centers.first(where: { $0.id == id }) ?? directory.first(where: { $0.id == id })
    }

    func linkedCenters() -> [BusinessOrganization] {
        centers.filter { athleteCenterIds.contains($0.id) }
    }

    func passesForOrg(_ orgId: UUID) -> [BusinessPass] {
        passes.filter { $0.orgId == orgId }
    }

    func offersForOrg(_ orgId: UUID) -> [BusinessPassOffer] {
        passOffers.filter { $0.orgId == orgId }
    }

    func searchDirectory(query: String) async {
        guard let client = BusinessAuthStore.shared.apiClient else {
            directory = []
            return
        }
        isSearchingDirectory = true
        defer { isSearchingDirectory = false }
        do {
            let rows: [BusinessOrganization] = try await client
                .rpc(
                    "search_discoverable_organizations",
                    params: DirectorySearchParams(p_query: query)
                )
                .execute().value
            directory = rows
            // Solo limpiar el aviso de búsqueda; no tocar otros errores de Center.
            if errorMessage?.hasPrefix("No se pudo buscar") == true {
                errorMessage = nil
            }
        } catch {
            directory = []
            let raw = error.localizedDescription
            if raw.localizedCaseInsensitiveContains("could not find the function")
                || raw.localizedCaseInsensitiveContains("PGRST202") {
                errorMessage =
                    "El directorio aún no está activo en el servidor. Actualiza la app o vuelve a intentarlo en unos minutos."
            } else {
                errorMessage = "No se pudo buscar centros. Comprueba la conexión e inténtalo de nuevo."
            }
        }
    }

    private struct DirectorySearchParams: Encodable, Sendable {
        let p_query: String
    }

    func booking(for occurrenceId: UUID) -> BusinessBooking? {
        bookings.first {
            $0.occurrenceId == occurrenceId && ($0.status == "booked" || $0.status == "waitlist")
        }
    }

    func remainingPlaces(for occurrence: BusinessOccurrence) -> Int? {
        guard let item = availability[occurrence.id] else { return nil }
        return max(0, item.capacity - item.reserved)
    }

    /// `nil` = abierta; si hay fecha, aún no se puede apuntar hasta entonces.
    func bookingOpensAt(for occurrence: BusinessOccurrence) -> Date? {
        guard let start = Self.date(occurrence.startsAt) else { return nil }
        let hours = centers.first(where: { $0.id == occurrence.orgId })?.classBookingOpenHours ?? 168
        let opens = start.addingTimeInterval(-TimeInterval(max(1, hours)) * 3600)
        return opens > Date() ? opens : nil
    }

    func canBookNow(_ occurrence: BusinessOccurrence) -> Bool {
        bookingOpensAt(for: occurrence) == nil
            && (Self.date(occurrence.startsAt) ?? .distantPast) > Date()
            && occurrence.status == "active"
    }

    func availablePasses(for occurrence: BusinessOccurrence) -> [BusinessPass] {
        guard let begins = Self.date(occurrence.startsAt) else { return [] }
        return passes.filter {
            let kindOK = $0.kind == occurrence.kind
                || (occurrence.kind == "open_access" && $0.kind == "class")
            return $0.orgId == occurrence.orgId && kindOK
                && $0.status == "active" && $0.remainingCredits > 0
                && (Self.date($0.validFrom) ?? .distantFuture) <= begins
                && (Self.date($0.validUntil) ?? .distantPast) >= begins
        }
    }

    func roomName(for occurrence: BusinessOccurrence) -> String? {
        if let roomId = occurrence.roomId,
           let room = facilityRooms.first(where: { $0.id == roomId }) {
            return room.name
        }
        let loc = occurrence.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return loc.isEmpty ? nil : loc
    }

    func openAccessEnabled(for orgId: UUID) -> Bool {
        operationSettingsByOrg[orgId]?.openAccessEnabled == true
    }

    func useRooms(for orgId: UUID) -> Bool {
        operationSettingsByOrg[orgId]?.useRooms == true
    }

    func loadClassRoster(for occurrenceId: UUID) async -> BusinessClassRoster? {
        guard let client = BusinessAuthStore.shared.apiClient else { return nil }
        do {
            let response = try await client
                .rpc("class_occurrence_roster", params: ["p_occurrence": occurrenceId.uuidString])
                .execute()
            return try JSONDecoder().decode(BusinessClassRoster.self, from: response.data)
        } catch {
            return nil
        }
    }

    func pastBookings(for orgId: UUID) -> [BusinessBooking] {
        let occById = Dictionary(uniqueKeysWithValues: occurrences.map { ($0.id, $0) })
        return bookings.filter { booking in
            guard booking.orgId == orgId,
                  let occ = occById[booking.occurrenceId],
                  let start = Self.date(occ.startsAt) else { return false }
            return start < Date() || ["attended", "cancelled", "no_show"].contains(booking.status)
        }
        .sorted { a, b in
            let da = Self.date(occById[a.occurrenceId]?.startsAt ?? "") ?? .distantPast
            let db = Self.date(occById[b.occurrenceId]?.startsAt ?? "") ?? .distantPast
            return da > db
        }
    }

    func paymentHistory(for orgId: UUID) -> [BusinessPass] {
        passes.filter { $0.orgId == orgId }
            .sorted { (Self.date($0.paidAt ?? $0.validFrom) ?? .distantPast) > (Self.date($1.paidAt ?? $1.validFrom) ?? .distantPast) }
    }

    func offerName(for pass: BusinessPass) -> String? {
        guard let oid = pass.offerId else { return nil }
        return passOffers.first(where: { $0.id == oid })?.name
    }

    func accept(_ invitation: BusinessInvitation) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc("accept_org_invitation",
                                 params: ["p_invitation_id": invitation.id.uuidString]).execute()
            pendingOpenLinkedCenterId = invitation.organizationId
            await refresh()
            NotificationCenter.default.post(
                name: Notification.Name("repera.openSettingsLinkedCenter"),
                object: invitation.organizationId
            )
        } catch {
            errorMessage = "No se ha podido aceptar la invitación: \(error.localizedDescription)"
        }
    }

    func invitationPreview(for id: UUID) -> BusinessInvitationPreview? {
        invitationPreviews[id]
    }

    func loadInvitationPreview(id: UUID) async -> BusinessInvitationPreview? {
        if let cached = invitationPreviews[id] { return cached }
        await loadInvitationPreviews(for: [id])
        return invitationPreviews[id]
    }

    private func loadInvitationPreviews(for ids: [UUID]) async {
        guard let client = BusinessAuthStore.shared.apiClient, !ids.isEmpty else { return }
        var next = invitationPreviews
        for id in ids {
            if next[id] != nil { continue }
            do {
                let row: BusinessInvitationPreview = try await client
                    .rpc("get_my_invitation_preview", params: ["p_invitation_id": id.uuidString])
                    .execute()
                    .value
                next[row.invitationId] = row
            } catch {
                // Sin preview: la ficha genérica sigue siendo usable.
            }
        }
        invitationPreviews = next
    }

    /// Same intent reuses its RPC request id until the server confirms, so a retry after a timeout
    /// cannot create a second booking or cancellation (the RPCs are idempotent per `p_request`).
    private enum PendingRequestID {
        private static let defaultsKey = "business.pendingRequestIDs.v1"
        private static let ttl: TimeInterval = 24 * 60 * 60

        static func reuse(for intent: String) -> String {
            var all = load()
            if let entry = all[intent], let id = entry["id"] { return id }
            let id = UUID().uuidString
            all[intent] = ["id": id, "at": String(Date().timeIntervalSince1970)]
            save(all)
            return id
        }

        static func confirm(_ intent: String) {
            var all = load()
            all[intent] = nil
            save(all)
        }

        private static func load() -> [String: [String: String]] {
            let now = Date().timeIntervalSince1970
            let stored = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: [String: String]] ?? [:]
            return stored.filter { now - (Double($0.value["at"] ?? "") ?? 0) < ttl }
        }

        private static func save(_ value: [String: [String: String]]) {
            UserDefaults.standard.set(value, forKey: defaultsKey)
        }
    }

    func book(_ occurrence: BusinessOccurrence, using pass: BusinessPass) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        let intent = "book:\(occurrence.id.uuidString):\(pass.id.uuidString)"
        let request = PendingRequestID.reuse(for: intent)
        do {
            try await client.rpc("book_service_occurrence",
                                 params: ["p_occurrence": occurrence.id.uuidString,
                                          "p_pass": pass.id.uuidString,
                                          "p_request": request]).execute()
            PendingRequestID.confirm(intent)
            await refresh()
            await requestPushPermissionAfterBookingIfNeeded()
            if BusinessAuthStore.shared.isConnected,
               let currentUser = try? await client.auth.session.user.id {
                await BusinessBookingReminderScheduler.reconcile(
                    userID: currentUser, bookings: bookings, occurrences: occurrences
                )
            }
        } catch {
            let raw = error.localizedDescription
            if raw.localizedCaseInsensitiveContains("REQUEST_ID_REUSED") {
                PendingRequestID.confirm(intent)
            }
            if raw.localizedCaseInsensitiveContains("BOOKING_NOT_OPEN_YET") {
                errorMessage = "Todavía no está abierta la inscripción a esta clase. Vuelve más cerca de la fecha."
            } else if raw.localizedCaseInsensitiveContains("PASS_OUTSIDE_SLOT") {
                errorMessage = "Tu plan no cubre esta clase. Pide a tu centro un plan de clases o revisa la franja de tu bono."
            } else if raw.localizedCaseInsensitiveContains("NO_VALID_PASS") {
                errorMessage = "No tienes un plan activo con crédito para esta clase."
            } else if raw.localizedCaseInsensitiveContains("NO_AVAILABILITY") {
                errorMessage = "La clase está completa."
            } else if raw.localizedCaseInsensitiveContains("ALREADY_BOOKED") {
                errorMessage = "Ya estás apuntado a esta clase."
            } else if raw.localizedCaseInsensitiveContains("NOT_A_MEMBER")
                || raw.localizedCaseInsensitiveContains("NOT_OWN_PASS") {
                errorMessage = "Tu cuenta no tiene una vinculación activa con este centro y este bono. Comprueba tu acceso con el gimnasio."
            } else {
                errorMessage = "No se ha podido confirmar la reserva: \(raw)"
            }
        }
    }

    func cancel(_ booking: BusinessBooking) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        let intent = "cancel:\(booking.id.uuidString)"
        do {
            try await client.rpc("cancel_service_booking",
                                 params: ["p_booking": booking.id.uuidString,
                                          "p_request": PendingRequestID.reuse(for: intent)]).execute()
            PendingRequestID.confirm(intent)
            await refresh()
        } catch {
            if error.localizedDescription.localizedCaseInsensitiveContains("REQUEST_ID_REUSED") {
                PendingRequestID.confirm(intent)
            }
            errorMessage = "No se ha podido cancelar la reserva: \(error.localizedDescription)"
        }
    }

    func requestLink(to org: BusinessOrganization, passKind: String, note: String?) async -> Bool {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "request_org_athlete_link",
                params: [
                    "p_org": org.id.uuidString,
                    "p_pass_kind": passKind,
                    "p_note": note ?? "",
                ]
            ).execute()
            await refresh()
            return true
        } catch {
            errorMessage = "No se ha podido vincular: \(error.localizedDescription)"
            return false
        }
    }

    func leave(_ org: BusinessOrganization) async -> Bool {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            // The RPC returns the authoritative confirmation. A successful result
            // must not be misclassified as failure because a refresh was running.
            let removed: Bool = try await client.rpc(
                "leave_org_as_athlete",
                params: ["p_org": org.id.uuidString]
            ).execute().value
            guard removed else {
                errorMessage = "No se ha confirmado la desvinculación. Inténtalo de nuevo."
                return false
            }

            // Drop all stale reads started before the membership was revoked.
            refreshRevision &+= 1
            isLoading = false
            athleteCenterIds.remove(org.id)
            clientLinks.removeAll { $0.orgId == org.id }
            centers.removeAll { $0.id == org.id }
            passes.removeAll { $0.orgId == org.id }
            passOffers.removeAll { $0.orgId == org.id }
            bookings.removeAll { $0.orgId == org.id }
            occurrences.removeAll { $0.orgId == org.id }
            trainingSessions.removeAll { $0.orgId == org.id }
            personalNotices.removeAll { $0.orgId == org.id }
            NotificationCenter.default.post(
                name: Notification.Name("repera.professionalPlansChanged"), object: nil
            )
            await BusinessWorkoutSyncStore.shared.refreshSharing()
            await refresh()
            // The unlink already succeeded in the database even if the
            // subsequent network refresh could not fetch remaining centers.
            return true
        } catch {
            let raw = error.localizedDescription
            if raw.localizedCaseInsensitiveContains("NOT_LINKED_CLIENT")
                || raw.localizedCaseInsensitiveContains("NOT_LINKED_ATHLETE") {
                errorMessage = "Ya no tienes una vinculación activa como cliente con este centro. Actualiza los datos e inténtalo de nuevo."
            } else if raw.localizedCaseInsensitiveContains("42501") {
                errorMessage = "No tienes permiso para desvincular esta ficha de cliente."
            } else {
                errorMessage = "No se ha podido completar la desvinculación. Comprueba tu conexión e inténtalo de nuevo."
            }
            return false
        }
    }

    func sendMessage(to orgId: UUID, title: String, body: String) async -> Bool {
        // Prefer chat RPC; fall back to legacy notice title+body for older backends.
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if await sendChatMessage(to: orgId, body: trimmed) { return true }
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "athlete_send_org_message",
                params: [
                    "p_org": orgId.uuidString,
                    "p_title": title,
                    "p_body": trimmed,
                ]
            ).execute()
            await refresh()
            return true
        } catch {
            errorMessage = "No se ha podido enviar el mensaje: \(error.localizedDescription)"
            return false
        }
    }

    func clientId(for orgId: UUID) -> UUID? {
        if let link = clientLinks.first(where: { $0.orgId == orgId }) { return link.id }
        if let fromPass = passes.first(where: { $0.orgId == orgId })?.clientId { return fromPass }
        if let fromNotice = personalNotices.first(where: { $0.orgId == orgId })?.clientId { return fromNotice }
        if let fromBooking = bookings.first(where: { $0.orgId == orgId })?.clientId { return fromBooking }
        return nil
    }

    func loadThread(orgId: UUID) async {
        guard let client = BusinessAuthStore.shared.apiClient,
              let clientId = clientId(for: orgId) else {
            conversationMessages = []
            return
        }
        do {
            struct ThreadParams: Encodable {
                let p_org: String
                let p_client: String
                let p_limit: Int
            }
            let rows: [BusinessConversationMessage] = try await client.rpc(
                "business_list_thread",
                params: ThreadParams(p_org: orgId.uuidString, p_client: clientId.uuidString, p_limit: 80)
            ).execute().value
            conversationMessages = rows.sorted { $0.createdAt < $1.createdAt }
            struct ReadParams: Encodable {
                let p_org: String
                let p_client: String
            }
            _ = try? await client.rpc(
                "business_mark_thread_read",
                params: ReadParams(p_org: orgId.uuidString, p_client: clientId.uuidString)
            ).execute()
        } catch {
            conversationMessages = []
        }
    }

    func sendChatMessage(to orgId: UUID, body: String) async -> Bool {
        guard let client = BusinessAuthStore.shared.apiClient,
              let clientId = clientId(for: orgId),
              !isSubmitting else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "business_send_message",
                params: [
                    "p_org": orgId.uuidString,
                    "p_client": clientId.uuidString,
                    "p_body": body,
                ]
            ).execute()
            await loadThread(orgId: orgId)
            return true
        } catch {
            return false
        }
    }

    func decline(_ invitation: BusinessInvitation) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "decline_org_invitation",
                params: ["p_invitation_id": invitation.id.uuidString]
            ).execute()
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = "No se ha podido rechazar la invitación: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        guard let client = BusinessAuthStore.shared.apiClient else { return }
        do {
            entitlements = try await client.rpc("get_my_effective_entitlements").execute().value
        } catch {
            entitlements = nil
        }
    }

    func activePasses(for orgId: UUID) -> [BusinessPass] {
        passes.filter { $0.orgId == orgId && $0.status == "active" }
    }

    /// Registra token FCM/APNs vía RPC; sin secretos de envío la cola sigue siendo válida.
    private struct PendingPushToken: Codable, Equatable {
        var token: String
        var platform: String
        var environment: String
    }

    private static let pendingPushTokenKey = "repera.business.pendingPushToken.v1"

    /// Persists the token until the server confirms it, retrying with backoff;
    /// a later refresh retries again if every attempt failed.
    @discardableResult
    func registerPushToken(_ token: String, platform: String = "ios", environment: String = "production") async -> Bool {
        guard token.count >= 10 else { return false }
        let pending = PendingPushToken(token: token, platform: platform, environment: environment)
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: Self.pendingPushTokenKey)
        }
        guard let client = BusinessAuthStore.shared.apiClient,
              BusinessAuthStore.shared.isConnected else { return false }
        struct Params: Encodable {
            let p_platform: String
            let p_token: String
            let p_environment: String
        }
        for attempt in 0..<3 {
            do {
                _ = try await client.rpc(
                    "register_push_device",
                    params: Params(p_platform: platform, p_token: token, p_environment: environment)
                ).execute()
                if let data = UserDefaults.standard.data(forKey: Self.pendingPushTokenKey),
                   (try? JSONDecoder().decode(PendingPushToken.self, from: data)) == pending {
                    UserDefaults.standard.removeObject(forKey: Self.pendingPushTokenKey)
                }
                return true
            } catch {
                if Self.isAuthorizationFailure(error) || Task.isCancelled || attempt == 2 { break }
                try? await Task.sleep(for: .seconds(2 << attempt))
            }
        }
        return false
    }

    func retryPendingPushTokenIfNeeded() async {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingPushTokenKey),
              let pending = try? JSONDecoder().decode(PendingPushToken.self, from: data) else { return }
        await registerPushToken(pending.token, platform: pending.platform, environment: pending.environment)
    }

    private func requestPushPermissionAfterBookingIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
}
