import Foundation
import UIKit
#if canImport(FirebaseCore) && canImport(FirebaseAnalytics)
import FirebaseCore
import FirebaseAnalytics
#endif

/// Shared wire contract: analytics/contract.json. Only iOS hosts Firebase; watchOS relays later.
/// Product metrics (Cafesito-style): enable when Firebase is configured. No in-app consent UI.
/// No HealthKit, GPS, user-entered labels or auth credentials may reach this boundary.
@MainActor
enum ReperaAnalytics {
    enum Event: String, CaseIterable, Sendable {
        case screenView = "screen_view"
        case login = "login"
        case signUp = "sign_up"
        case settingsChanged = "settings_changed"
        case onboardingStarted = "onboarding_started"
        case onboardingCompleted = "onboarding_completed"
        case uiInteraction = "ui_interaction"
        case watchAppOpened = "watch_app_opened"
        case workoutCreated = "workout_created"
        case workoutScheduled = "workout_scheduled"
        case workoutEdited = "workout_edited"
        case workoutDeleted = "workout_deleted"
        case workoutStarted = "workout_started"
        case workoutPaused = "workout_paused"
        case workoutResumed = "workout_resumed"
        case workoutSetRecorded = "workout_set_recorded"
        case workoutBlockCompleted = "workout_block_completed"
        case workoutSaveRequested = "workout_save_requested"
        case workoutCompleted = "workout_completed"
        case workoutDiscarded = "workout_discarded"
        case workoutSaveFailed = "workout_save_failed"
        case favoriteAdded = "favorite_added"
        case favoriteReused = "favorite_reused"
        case favoriteRemoved = "favorite_removed"
        case activitySelected = "activity_selected"
        case routeLoaded = "route_loaded"
        case routeSaved = "route_saved"
        case navigationStarted = "navigation_started"
        case navigationModeChanged = "navigation_mode_changed"
        case mapRecenterRequested = "map_recenter_requested"
        case sportFavoriteAdded = "sport_favorite_added"
        case timerStarted = "timer_started"
        case timerPaused = "timer_paused"
        case timerResumed = "timer_resumed"
        case timerCompleted = "timer_completed"
        case timerDiscarded = "timer_discarded"
        case restTimerSkipped = "rest_timer_skipped"
        case exerciseSearchUsed = "exercise_search_used"
        case exerciseDetailViewed = "exercise_detail_viewed"
        case customExerciseCreated = "custom_exercise_created"
        case scanStarted = "scan_started"
        case scanProcessed = "scan_processed"
        case scanResultAccepted = "scan_result_accepted"
        case scanSaved = "scan_saved"
        case scanFailed = "scan_failed"
        case progressSectionViewed = "progress_section_viewed"
        case progressPeriodSelected = "progress_period_selected"
        case progressDetailOpened = "progress_detail_opened"
        case exerciseHistoryViewed = "exercise_history_viewed"
        case personalRecordViewed = "personal_record_viewed"
        case centerSearchUsed = "center_search_used"
        case centerInviteOpened = "center_invite_opened"
        case centerLinkCompleted = "center_link_completed"
        case centerUnlinked = "center_unlinked"
        case classListViewed = "class_list_viewed"
        case classViewed = "class_viewed"
        case classBookingRequested = "class_booking_requested"
        case classBookingConfirmed = "class_booking_confirmed"
        case classBookingCancelled = "class_booking_cancelled"
        case classWaitlistJoined = "class_waitlist_joined"
        case classAttended = "class_attended"
        case appointmentConfirmed = "appointment_confirmed"
        case classPlanOpened = "class_plan_opened"
        case premiumFeatureTapped = "premium_feature_tapped"
        case freeLimitReached = "free_limit_reached"
        case paywallViewed = "paywall_viewed"
        case paywallDismissed = "paywall_dismissed"
        case checkoutStarted = "checkout_started"
        case checkoutCancelled = "checkout_cancelled"
        case trialStarted = "trial_started"
        case subscriptionStarted = "subscription_started"
        case subscriptionRestored = "subscription_restored"
        case purchaseFailed = "purchase_failed"
        case entitlementChanged = "entitlement_changed"
        case aiConnectionStarted = "ai_connection_started"
        case aiConnectionVerified = "ai_connection_verified"
        case aiProgramReceived = "ai_program_received"
        case aiProgramActivated = "ai_program_activated"
        case aiProgramPaused = "ai_program_paused"
        case operationFailed = "operation_failed"
        case syncCompleted = "sync_completed"
        case syncFailed = "sync_failed"
        case watchCommandUsed = "watch_command_used"
        case watchSyncConfirmed = "watch_sync_confirmed"
        case watchSyncFailed = "watch_sync_failed"
        case notificationOpened = "notification_opened"
        case dataImportCompleted = "data_import_completed"
        case dataExportCompleted = "data_export_completed"
    }

    private static let completedKeysStore = "repera.analytics.completed.v1"
    private(set) static var isConfigured = false
    private static let allowedKeys: Set<String> = [
        "feature_area", "screen_name", "section_name", "entry_point",
        "access_tier", "result", "flow_type", "activity_family",
        "activity_type", "workout_type", "wod_format", "service_kind",
        "class_category", "interaction_type", "component_id",
        "action_name", "timer_type", "paywall_context", "feature_id",
        "error_code", "session_origin_platform", "completion_platform"
    ]
    private static let safeValue = try! NSRegularExpression(pattern: "^[a-zA-Z0-9_]{1,40}$")

    /// Maps LiveSport UI groups to closed GA4 family IDs (never Spanish labels).
    static func activityFamily(forSportGroup group: String) -> String {
        switch group {
        case "A pie": return "foot"
        case "Ciclismo": return "cycling"
        case "Fuerza y fitness": return "strength_fitness"
        case "Deportes de raqueta": return "racket"
        case "Deportes acuáticos": return "water"
        case "Deportes de invierno": return "winter"
        case "Deportes de equipo": return "team"
        case "Combate": return "combat"
        case "Cardio y gimnasio": return "cardio_gym"
        default: return "other"
        }
    }

    /// The plist is supplied by the real Firebase project, not embedded as a placeholder.
    /// Missing configuration leaves Analytics disabled and does not affect app startup.
    static func configure() {
        #if canImport(FirebaseCore) && canImport(FirebaseAnalytics)
        guard !isConfigured,
              let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else { return }
        if FirebaseApp.app() == nil { FirebaseApp.configure(options: options) }
        // Product metrics (not ads): enable collection once Firebase is present.
        Analytics.setAnalyticsCollectionEnabled(true)
        isConfigured = true
        #endif
    }

    /// Clears local completion dedup (e.g. account switch). Does not touch Firebase identity.
    static func clearLocalState() {
        UserDefaults.standard.removeObject(forKey: completedKeysStore)
    }

    static func track(_ event: Event, parameters: [String: String] = [:]) {
        #if canImport(FirebaseAnalytics)
        guard isConfigured else { return }
        Analytics.logEvent(event.rawValue, parameters: sanitized(parameters))
        #endif
    }

    /// Emits at most once per opaque logical key (session UUID hashed locally; never sent to GA4).
    @discardableResult
    static func trackOnce(
        _ event: Event,
        logicalKey: String,
        parameters: [String: String] = [:]
    ) -> Bool {
        guard isConfigured else { return false }
        let token = opaqueToken(logicalKey)
        var seen = Set(UserDefaults.standard.stringArray(forKey: completedKeysStore) ?? [])
        guard !seen.contains(token) else { return false }
        seen.insert(token)
        // Bound growth: keep the most recent ~400 completions.
        if seen.count > 400 {
            seen = Set(seen.suffix(400))
        }
        UserDefaults.standard.set(Array(seen), forKey: completedKeysStore)
        track(event, parameters: parameters)
        return true
    }

    static func trackWorkoutCompleted(
        sessionID: UUID,
        workoutType: String,
        activityType: String? = nil,
        activityFamily: String? = nil,
        wodFormat: String? = nil,
        featureArea: String = "training",
        sessionOrigin: String = "ios",
        completionPlatform: String = "ios",
        accessTier: String? = nil
    ) {
        var parameters: [String: String] = [
            "feature_area": featureArea,
            "workout_type": workoutType,
            "result": "success",
            "session_origin_platform": sessionOrigin,
            "completion_platform": completionPlatform
        ]
        if let activityType { parameters["activity_type"] = activityType }
        if let activityFamily { parameters["activity_family"] = activityFamily }
        if let wodFormat { parameters["wod_format"] = wodFormat }
        if let accessTier { parameters["access_tier"] = accessTier }
        _ = trackOnce(.workoutCompleted, logicalKey: sessionID.uuidString, parameters: parameters)
    }

    private static func sanitized(_ parameters: [String: String]) -> [String: Any] {
        var data: [String: Any] = [
            "schema_version": 1,
            "origin_platform": "ios",
            "device_class": UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        ]
        for (key, value) in parameters where allowedKeys.contains(key) {
            let range = NSRange(value.startIndex..<value.endIndex, in: value)
            guard safeValue.firstMatch(in: value, range: range) != nil else { continue }
            data[key] = value
        }
        return data
    }

    private static func opaqueToken(_ logicalKey: String) -> String {
        // Stable local token; not a GA4 dimension.
        String(logicalKey.utf8.reduce(UInt64(5381)) { ($0 << 5) &+ $0 &+ UInt64($1) }, radix: 16)
    }
}
