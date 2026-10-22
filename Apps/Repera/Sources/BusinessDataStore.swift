import Foundation
import Observation
import Supabase

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

    enum CodingKeys: String, CodingKey {
        case id, name, kind, slug, tagline
        case avatarUrl = "avatar_url"
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
struct BusinessOccurrence: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let kind: String
    let title: String
    let startsAt: String
    let endsAt: String
    let capacity: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, kind, title, capacity, status
        case orgId = "org_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
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

    enum CodingKeys: String, CodingKey {
        case id, kind, status
        case orgId = "org_id"
        case clientId = "client_id"
        case totalCredits = "total_credits"
        case remainingCredits = "remaining_credits"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
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
}
struct BusinessPrescriptionEntry: Decodable, Identifiable {
    let id: UUID
    let source: String
    let catalogKey: String?
    let name: String
    let plannedSets: [BusinessPrescriptionSet]?
    let reps: Int?
    let notes: String?
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
    let coachUserId: UUID
    let scheduledDate: String  // yyyy-MM-dd, date-only (never UTC-shifted)
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

private struct BusinessClientLink: Decodable {
    let id: UUID
    let orgId: UUID
    let userId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case userId = "user_id"
    }
}

@MainActor
@Observable
final class BusinessDataStore {
    static let shared = BusinessDataStore()

    private(set) var centers: [BusinessOrganization] = []
    private(set) var athleteCenterIds: Set<UUID> = []
    private(set) var invitations: [BusinessInvitation] = []
    private(set) var occurrences: [BusinessOccurrence] = []
    private(set) var passes: [BusinessPass] = []
    private(set) var bookings: [BusinessBooking] = []
    private(set) var availability: [UUID: BusinessAvailability] = [:]
    private(set) var trainingSessions: [BusinessProfessionalTrainingSession] = []
    private(set) var personalNotices: [BusinessClientNotification] = []
    private(set) var directory: [BusinessOrganization] = []
    private(set) var isLoading = false
    private(set) var isSearchingDirectory = false
    @ObservationIgnored private var refreshRevision = 0
    private(set) var errorMessage: String?
    private(set) var isSubmitting = false

    /// Acceso completo en la app mientras el deportista está vinculado a un centro/entrenador.
    var grantsFullAppAccess: Bool { !athleteCenterIds.isEmpty }

    private init() {}

    func clear() {
        // Invalidate every in-flight response before clearing PII from a previous user.
        refreshRevision &+= 1
        isLoading = false
        centers = []
        athleteCenterIds = []
        invitations = []
        occurrences = []
        passes = []
        bookings = []
        availability = [:]
        trainingSessions = []
        NotificationCenter.default.post(name: Notification.Name("repera.professionalPlansChanged"), object: nil)
        personalNotices = []
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
        do {
            let user = try await client.auth.session.user
            let currentUser = user.id
            let fetchedCenters: [BusinessOrganization] = try await client
                .from("organizations")
                .select("id,name,kind,slug,avatar_url,tagline")
                .execute().value
            let fetchedInvitations: [BusinessInvitation] = try await client
                .from("organization_invitations")
                .select("id,organization_id,invited_role,expires_at,accepted_at,cancelled_at")
                .execute().value
            let fetchedLinks: [BusinessClientLink] = try await client
                .from("clients")
                .select("id,org_id,user_id")
                .execute().value
            let ownedClientIds = Set(fetchedLinks.filter { $0.userId == currentUser }.map(\.id))
            let fetchedOccurrences: [BusinessOccurrence] = try await client
                .from("service_occurrences")
                .select("id,org_id,kind,title,starts_at,ends_at,capacity,status")
                .execute().value
            let fetchedPasses: [BusinessPass] = try await client
                .from("service_passes")
                .select("id,org_id,client_id,kind,total_credits,remaining_credits,valid_from,valid_until,status")
                .execute().value
            let fetchedBookings: [BusinessBooking] = try await client
                .from("service_bookings")
                .select("id,org_id,client_id,occurrence_id,status")
                .execute().value
            let fetchedTrainingSessions: [BusinessProfessionalTrainingSession] = try await client
                .from("professional_training_sessions")
                .select("id,org_id,client_id,coach_user_id,scheduled_date,title,instructions,prescription,status")
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
            athleteCenterIds = Set(fetchedLinks.filter { $0.userId == currentUser }.map(\.orgId))
            invitations = fetchedInvitations.filter { $0.acceptedAt == nil && $0.cancelledAt == nil && (Self.date($0.expiresAt) ?? .distantPast) > Date() }
            occurrences = fetchedOccurrences.filter { $0.status == "active" }
            passes = fetchedPasses.filter { ownedClientIds.contains($0.clientId) }
            bookings = fetchedBookings.filter { ownedClientIds.contains($0.clientId) }
            personalNotices = fetchedNotices.filter { ownedClientIds.contains($0.clientId) }
            trainingSessions = fetchedTrainingSessions.filter { ownedClientIds.contains($0.clientId) && $0.status == "scheduled" }.sorted { $0.scheduledDate < $1.scheduledDate }
            NotificationCenter.default.post(name: Notification.Name("repera.professionalPlansChanged"), object: nil)
            errorMessage = nil
        } catch {
            // A failed request belonging to a prior session cannot reset the new session.
            guard revision == refreshRevision else { return }
            clear()
            errorMessage = "No se han podido cargar tus centros y reservas. \(error.localizedDescription)"
        }
    }

    static func date(_ value: String) -> Date? {
        let precise = ISO8601DateFormatter()
        precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return precise.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static func localDayKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
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
        bookings.first { $0.occurrenceId == occurrenceId && $0.status == "booked" }
    }

    func remainingPlaces(for occurrence: BusinessOccurrence) -> Int? {
        guard let item = availability[occurrence.id] else { return nil }
        return max(0, item.capacity - item.reserved)
    }

    func availablePasses(for occurrence: BusinessOccurrence) -> [BusinessPass] {
        guard let begins = Self.date(occurrence.startsAt) else { return [] }
        return passes.filter {
            $0.orgId == occurrence.orgId && $0.kind == occurrence.kind
                && $0.status == "active" && $0.remainingCredits > 0
                && (Self.date($0.validFrom) ?? .distantFuture) <= begins
                && (Self.date($0.validUntil) ?? .distantPast) >= begins
        }
    }

    func accept(_ invitation: BusinessInvitation) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc("accept_org_invitation",
                                 params: ["p_invitation_id": invitation.id.uuidString]).execute()
            await refresh()
        } catch {
            errorMessage = "No se ha podido aceptar la invitación: \(error.localizedDescription)"
        }
    }

    func book(_ occurrence: BusinessOccurrence, using pass: BusinessPass) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        let request = UUID().uuidString
        do {
            try await client.rpc("book_service_occurrence",
                                 params: ["p_occurrence": occurrence.id.uuidString,
                                          "p_pass": pass.id.uuidString,
                                          "p_request": request]).execute()
            await refresh()
        } catch {
            errorMessage = "No se ha podido confirmar la reserva: \(error.localizedDescription)"
        }
    }

    func cancel(_ booking: BusinessBooking) async {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc("cancel_service_booking",
                                 params: ["p_booking": booking.id.uuidString,
                                          "p_request": UUID().uuidString]).execute()
            await refresh()
        } catch {
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
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "leave_org_as_athlete",
                params: ["p_org": org.id.uuidString]
            ).execute()
            await refresh()
            return true
        } catch {
            errorMessage = "No se ha podido desvincular: \(error.localizedDescription)"
            return false
        }
    }

    func sendMessage(to orgId: UUID, title: String, body: String) async -> Bool {
        guard let client = BusinessAuthStore.shared.apiClient, !isSubmitting else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await client.rpc(
                "athlete_send_org_message",
                params: [
                    "p_org": orgId.uuidString,
                    "p_title": title,
                    "p_body": body,
                ]
            ).execute()
            await refresh()
            return true
        } catch {
            errorMessage = "No se ha podido enviar el mensaje: \(error.localizedDescription)"
            return false
        }
    }
}
