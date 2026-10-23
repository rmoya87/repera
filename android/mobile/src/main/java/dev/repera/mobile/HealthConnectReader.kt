package dev.repera.mobile

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Observed health information only. No MET estimates, synthetic readings or implicit writes. */
data class TodayHealth(val steps: Long?, val activeKcal: Double?)

class HealthConnectReader(private val context: Context) {
    companion object {
        val permissions = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class)
        )
    }

    fun available() = HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    suspend fun hasPermissions(): Boolean {
        if (!available()) return false
        val granted = HealthConnectClient.getOrCreate(context)
            .permissionController.getGrantedPermissions()
        return granted.containsAll(permissions)
    }

    suspend fun readToday(): TodayHealth {
        check(available()) { "Health Connect no está disponible en este dispositivo" }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = client.permissionController.getGrantedPermissions()
        require(granted.containsAll(permissions)) { "Debes autorizar Salud para leer actividad" }
        val zone = ZoneId.systemDefault()
        val start = LocalDate.now(zone).atStartOfDay(zone).toInstant()
        val now = Instant.now()
        val result = client.aggregate(
            AggregateRequest(
                metrics = setOf(StepsRecord.COUNT_TOTAL, ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
                timeRangeFilter = TimeRangeFilter.between(start, now)
            )
        )
        // Null means no verified reading. Zero and unknown are not interchangeable.
        return TodayHealth(
            steps = result[StepsRecord.COUNT_TOTAL],
            activeKcal = result[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]
                ?.inKilocalories
        )
    }
}
