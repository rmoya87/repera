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
    private const val COMPLETED_KEYS = "completed.v1"
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
    @Volatile private var appContext: Context? = null
    @Volatile private var deviceClass = "phone"

    fun isConfigured(): Boolean = firebase != null

    /** Maps LiveSport UI groups to closed GA4 family IDs (never Spanish labels). */
    fun activityFamily(forSportGroup: String): String = when (forSportGroup) {
        "A pie" -> "foot"
        "Ciclismo" -> "cycling"
        "Fuerza y fitness" -> "strength_fitness"
        "Deportes de raqueta" -> "racket"
        "Deportes acuáticos" -> "water"
        "Deportes de invierno" -> "winter"
        "Deportes de equipo" -> "team"
        "Combate" -> "combat"
        "Cardio y gimnasio" -> "cardio_gym"
        else -> "other"
    }

    /** Planned gym work without liveSportID maps to strength/crossfit catalog IDs. */
    fun resolveActivity(
        liveSportId: String?,
        hasWodBlocks: Boolean,
        hasExercises: Boolean
    ): Pair<String?, String?> {
        if (!liveSportId.isNullOrBlank()) return liveSportId to null
        if (hasWodBlocks) return "crossfit" to "strength_fitness"
        if (hasExercises) return "strength" to "strength_fitness"
        return null to null
    }

    /** No Firebase resource? No-op. Never break the app or simulate configured analytics. */
    fun configure(context: Context) {
        val appContext = context.applicationContext
        this.appContext = appContext
        deviceClass = if (appContext.resources.configuration.smallestScreenWidthDp >= 600) "tablet" else "phone"
        val app = FirebaseApp.initializeApp(appContext) ?: return
        firebase = FirebaseAnalytics.getInstance(app.applicationContext).also {
            // Product metrics (not ads): enable once Firebase initializes from real google-services.json.
            it.setAnalyticsCollectionEnabled(true)
        }
    }

    fun clearLocalState(context: Context) {
        context.applicationContext
            .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit().remove(COMPLETED_KEYS).apply()
    }

    fun track(event: Event, parameters: Map<String, String> = emptyMap()) {
        val service = firebase ?: return
        service.logEvent(event.wire, bundle(parameters))
    }

    /** Emits at most once per opaque logical key (session id hashed locally; never sent to GA4). */
    fun trackOnce(event: Event, logicalKey: String, parameters: Map<String, String> = emptyMap()): Boolean {
        if (firebase == null) return false
        val prefs = (appContext ?: return false)
            .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val token = opaqueToken(logicalKey)
        val seen = prefs.getStringSet(COMPLETED_KEYS, emptySet())?.toMutableSet() ?: mutableSetOf()
        if (!seen.add(token)) return false
        if (seen.size > 400) {
            val trimmed = seen.toList().takeLast(400).toSet()
            prefs.edit().putStringSet(COMPLETED_KEYS, HashSet(trimmed)).apply()
        } else {
            prefs.edit().putStringSet(COMPLETED_KEYS, HashSet(seen)).apply()
        }
        track(event, parameters)
        return true
    }

    fun trackWorkoutCompleted(
        sessionId: String,
        workoutType: String,
        activityType: String? = null,
        activityFamily: String? = null,
        wodFormat: String? = null,
        featureArea: String = "training",
        sessionOrigin: String = "android",
        completionPlatform: String = "android",
        accessTier: String? = null
    ) {
        val parameters = mutableMapOf(
            "feature_area" to featureArea,
            "workout_type" to workoutType,
            "result" to "success",
            "session_origin_platform" to sessionOrigin,
            "completion_platform" to completionPlatform
        )
        activityType?.let { parameters["activity_type"] = it }
        activityFamily?.let { parameters["activity_family"] = it }
        wodFormat?.let { parameters["wod_format"] = it }
        accessTier?.let { parameters["access_tier"] = it }
        trackOnce(Event.WORKOUT_COMPLETED, sessionId, parameters)
    }

    private fun bundle(parameters: Map<String, String>): Bundle = Bundle().apply {
        putLong("schema_version", 1)
        putString("origin_platform", "android")
        putString("device_class", deviceClass)
        parameters.forEach { (key, value) ->
            if (key in allowedKeys && safeValue.matches(value)) putString(key, value)
        }
    }

    private fun opaqueToken(logicalKey: String): String {
        var hash = 5381L
        for (ch in logicalKey) {
            hash = ((hash shl 5) + hash) + ch.code
        }
        return java.lang.Long.toHexString(hash)
    }
}
