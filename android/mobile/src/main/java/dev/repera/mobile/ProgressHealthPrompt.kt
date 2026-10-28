package dev.repera.mobile

import dev.repera.domain.ProgressPreparedCharts

/** Result of the last real Health Connect check (availability + granted read permission). */
enum class HealthAccessState { UNKNOWN, UNAVAILABLE, NOT_GRANTED, GRANTED }

internal enum class ProgressHealthPromptKind { NONE, NOT_AUTHORIZED, UNAVAILABLE }

/** Apple StatsView.healthPermissionCard, driven by a checked state instead of "no data":
 *  nothing is said while the check is pending (UNKNOWN), when access is granted (empty
 *  charts then just mean no data), or when there are HR/kcal series to draw. */
internal object ProgressHealthPrompt {
    fun kind(access: HealthAccessState, charts: ProgressPreparedCharts?): ProgressHealthPromptKind {
        val hasSeries = charts != null && (charts.heartRate.isNotEmpty() || charts.calories.isNotEmpty())
        if (hasSeries) return ProgressHealthPromptKind.NONE
        return when (access) {
            HealthAccessState.NOT_GRANTED -> ProgressHealthPromptKind.NOT_AUTHORIZED
            HealthAccessState.UNAVAILABLE -> ProgressHealthPromptKind.UNAVAILABLE
            else -> ProgressHealthPromptKind.NONE
        }
    }
}
