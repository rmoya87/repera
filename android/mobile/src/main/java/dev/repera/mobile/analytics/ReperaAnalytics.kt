package dev.repera.mobile.analytics

import android.content.Context
import android.os.Bundle
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics

/** Wire names generated from analytics/contract.json; this object never reads health or GPS. */
object ReperaAnalytics {
    enum class Event(val wire: String) {
        SCREEN_VIEW("screen_view"),
        LOGIN("login"),
        SIGN_UP("sign_up"),
        SETTINGS_CHANGED("settings_changed"),
        ONBOARDING_STARTED("onboarding_started"),
        ONBOARDING_COMPLETED("onboarding_completed"),
        UI_INTERACTION("ui_interaction"),
        WATCH_APP_OPENED("watch_app_opened"),
        WORKOUT_CREATED("workout_created"),
        WORKOUT_SCHEDULED("workout_scheduled"),
        WORKOUT_EDITED("workout_edited"),
        WORKOUT_DELETED("workout_deleted"),
        WORKOUT_STARTED("workout_started"),
        WORKOUT_PAUSED("workout_paused"),
        WORKOUT_RESUMED("workout_resumed"),
        WORKOUT_SET_RECORDED("workout_set_recorded"),
        WORKOUT_BLOCK_COMPLETED("workout_block_completed"),
        WORKOUT_SAVE_REQUESTED("workout_save_requested"),
        WORKOUT_COMPLETED("workout_completed"),
        WORKOUT_DISCARDED("workout_discarded"),
        WORKOUT_SAVE_FAILED("workout_save_failed"),
        FAVORITE_ADDED("favorite_added"),
        FAVORITE_REUSED("favorite_reused"),
        FAVORITE_REMOVED("favorite_removed"),
        ACTIVITY_SELECTED("activity_selected"),
        ROUTE_LOADED("route_loaded"),
        ROUTE_SAVED("route_saved"),
        NAVIGATION_STARTED("navigation_started"),
        NAVIGATION_MODE_CHANGED("navigation_mode_changed"),
        MAP_RECENTER_REQUESTED("map_recenter_requested"),
        SPORT_FAVORITE_ADDED("sport_favorite_added"),
        TIMER_STARTED("timer_started"),
        TIMER_PAUSED("timer_paused"),
        TIMER_RESUMED("timer_resumed"),
        TIMER_COMPLETED("timer_completed"),
        TIMER_DISCARDED("timer_discarded"),
        REST_TIMER_SKIPPED("rest_timer_skipped"),
        EXERCISE_SEARCH_USED("exercise_search_used"),
        EXERCISE_DETAIL_VIEWED("exercise_detail_viewed"),
        CUSTOM_EXERCISE_CREATED("custom_exercise_created"),
        SCAN_STARTED("scan_started"),
        SCAN_PROCESSED("scan_processed"),
        SCAN_RESULT_ACCEPTED("scan_result_accepted"),
        SCAN_SAVED("scan_saved"),
        SCAN_FAILED("scan_failed"),
        PROGRESS_SECTION_VIEWED("progress_section_viewed"),
        PROGRESS_PERIOD_SELECTED("progress_period_selected"),
        PROGRESS_DETAIL_OPENED("progress_detail_opened"),
        EXERCISE_HISTORY_VIEWED("exercise_history_viewed"),
        PERSONAL_RECORD_VIEWED("personal_record_viewed"),
        CENTER_SEARCH_USED("center_search_used"),
        CENTER_INVITE_OPENED("center_invite_opened"),
        CENTER_LINK_COMPLETED("center_link_completed"),
        CENTER_UNLINKED("center_unlinked"),
        CLASS_LIST_VIEWED("class_list_viewed"),
        CLASS_VIEWED("class_viewed"),
        CLASS_BOOKING_REQUESTED("class_booking_requested"),
        CLASS_BOOKING_CONFIRMED("class_booking_confirmed"),
        CLASS_BOOKING_CANCELLED("class_booking_cancelled"),
        CLASS_WAITLIST_JOINED("class_waitlist_joined"),
        CLASS_ATTENDED("class_attended"),
        APPOINTMENT_CONFIRMED("appointment_confirmed"),
        CLASS_PLAN_OPENED("class_plan_opened"),
        PREMIUM_FEATURE_TAPPED("premium_feature_tapped"),
        FREE_LIMIT_REACHED("free_limit_reached"),
        PAYWALL_VIEWED("paywall_viewed"),
        PAYWALL_DISMISSED("paywall_dismissed"),
        CHECKOUT_STARTED("checkout_started"),
        CHECKOUT_CANCELLED("checkout_cancelled"),
        TRIAL_STARTED("trial_started"),
        SUBSCRIPTION_STARTED("subscription_started"),
        SUBSCRIPTION_RESTORED("subscription_restored"),
        PURCHASE_FAILED("purchase_failed"),
        ENTITLEMENT_CHANGED("entitlement_changed"),
        AI_CONNECTION_STARTED("ai_connection_started"),
        AI_CONNECTION_VERIFIED("ai_connection_verified"),
        AI_PROGRAM_RECEIVED("ai_program_received"),
        AI_PROGRAM_ACTIVATED("ai_program_activated"),
        AI_PROGRAM_PAUSED("ai_program_paused"),
        OPERATION_FAILED("operation_failed"),
        SYNC_COMPLETED("sync_completed"),
        SYNC_FAILED("sync_failed"),
        WATCH_COMMAND_USED("watch_command_used"),
        WATCH_SYNC_CONFIRMED("watch_sync_confirmed"),
        WATCH_SYNC_FAILED("watch_sync_failed"),
        NOTIFICATION_OPENED("notification_opened"),
        DATA_IMPORT_COMPLETED("data_import_completed"),
        DATA_EXPORT_COMPLETED("data_export_completed")
    }

    private const val PREFERENCES = "repera.analytics"
    private const val CONSENT_KEY = "consent.v1"
    private val allowedKeys = setOf(
        "feature_area", "screen_name", "section_name", "entry_point",
        "access_tier", "result", "flow_type", "activity_family",
        "activity_type", "workout_type", "wod_format", "service_kind",
        "class_category", "interaction_type", "component_id",
        "action_name", "timer_type", "paywall_context", "feature_id",
        "error_code", "session_origin_platform", "completion_platform"
    )
    private val safeValue = Regex("^[a-zA-Z0-9_]{1,40}$")
    @Volatile private var firebase: FirebaseAnalytics? = null
    @Volatile private var consentGranted = false

    /** No Firebase resource? No-op. Never break the app or simulate configured analytics. */
    fun configure(context: Context) {
        consentGranted = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(CONSENT_KEY, false)
        val app = FirebaseApp.initializeApp(context) ?: return
        firebase = FirebaseAnalytics.getInstance(app.applicationContext).also {
            it.setAnalyticsCollectionEnabled(consentGranted)
        }
    }

    fun setConsent(context: Context, granted: Boolean) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit().putBoolean(CONSENT_KEY, granted).apply()
        consentGranted = granted
        firebase?.setAnalyticsCollectionEnabled(granted)
        if (!granted) firebase?.setUserId(null)
    }

    fun track(event: Event, parameters: Map<String, String> = emptyMap()) {
        val service = firebase ?: return
        if (!consentGranted) return
        val data = Bundle().apply {
            putLong("schema_version", 1)
            putString("origin_platform", "android")
            putString("device_class", "phone")
            parameters.forEach { (key, value) ->
                if (key in allowedKeys && safeValue.matches(value)) putString(key, value)
            }
        }
        service.logEvent(event.wire, data)
    }
}
