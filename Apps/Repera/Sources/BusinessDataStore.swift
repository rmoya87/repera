import Foundation
import Observation
import Supabase

/// Professional data read through the verified Supabase Auth session and row-level security.
/// Local ReperaStore workouts and HealthKit are never uploaded or overwritten.
struct BusinessOrganization: Decodable, Identifiable {
    let id: UUID
    let name: String
    let kind: String
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
struct BusinessProfessionalTrainingSession: Decodable, Identifiable {
    let id: UUID
    let orgId: UUID
    let clientId: UUID
    let coachUserId: UUID
    let scheduledDate: String  // yyyy-MM-dd, date-only (never UTC-shifted)
    let title: String
    let instructions: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, title, instructions, status
        case orgId = "org_id"
        case clientId = "client_id"
        case coachUserId = "coach_user_id"
        case scheduledDate = "scheduled_date"
    }
}

private struct BusinessClientLink: Decodable {
    let id: UUID
    let userId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
    }
}

@MainActor
@Observable
final class BusinessDataStore {
    static let shared = BusinessDataStore()

    private(set) var centers: [BusinessOrganization] = []
    private(set) var invitations: [BusinessInvitation] = []
    private(set) var occurrences: [BusinessOccurrence] = []
    private(set) var passes: [BusinessPass] = []
    private(set) var bookings: [BusinessBooking] = []
    private(set) var trainingSessions: [BusinessProfessionalTrainingSession] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSubmitting = false

    private init() {}

    func clear() {
        centers = []
        invitations = []
        occurrences = []
        passes = []
        bookings = []
        trainingSessions = []
        errorMessage = nil
    }

    func refresh() async {
        guard BusinessAuthStore.shared.isConnected,
              let client = BusinessAuthStore.shared.apiClient else {
            clear()
            return
        }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await client.auth.session.user
            let currentUser = user.id
            let fetchedCenters: [BusinessOrganization] = try await client
                .from("organizations")
                .select("id,name,kind")
                .execute().value
            let fetchedInvitations: [BusinessInvitation] = try await client
                .from("organization_invitations")
                .select("id,organization_id,invited_role,expires_at,accepted_at,cancelled_at")
                .execute().value
            let fetchedLinks: [BusinessClientLink] = try await client
                .from("clients")
                .select("id,user_id")
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
                .select("id,org_id,client_id,coach_user_id,scheduled_date,title,instructions,status")
                .execute().value
            centers = fetchedCenters
            invitations = fetchedInvitations.filter { $0.acceptedAt == nil && $0.cancelledAt == nil && (Self.date($0.expiresAt) ?? .distantPast) > Date() }
            occurrences = fetchedOccurrences.filter { $0.status == "active" }
            passes = fetchedPasses.filter { ownedClientIds.contains($0.clientId) }
            bookings = fetchedBookings.filter { ownedClientIds.contains($0.clientId) }
            trainingSessions = fetchedTrainingSessions.filter { ownedClientIds.contains($0.clientId) && $0.status == "scheduled" }.sorted { $0.scheduledDate < $1.scheduledDate }
            errorMessage = nil
        } catch {
            // Do not display stale bookings or balances after an authorization/network failure.
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
        centers.first(where: { $0.id == id })?.name ?? "Centro deportivo"
    }

    func booking(for occurrenceId: UUID) -> BusinessBooking? {
        bookings.first { $0.occurrenceId == occurrenceId && $0.status == "booked" }
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
}
