package dev.repera.mobile.monetization

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import dev.repera.domain.monetization.FreeUsageLedger
import dev.repera.domain.monetization.FreeUsageState
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persistencia local-first de cuotas gratuitas (fuera del JSON deportivo).
 * Port 1:1 de FreeUsageStore.swift: UN archivo local por dispositivo
 * (iOS usa Application Support/Repera/free_usage.json, sin clave de cuenta)
 * y NO concede nada: solo registra consumo. Gap real frente a iOS: la
 * sincronización iCloud best-effort entre dispositivos del mismo Apple ID
 * no tiene equivalente Android todavía (Drive/backend: autorización
 * pendiente, sin activar). Cambiar de cuenta en el mismo dispositivo NO
 * reinicia la cuota, igual que en iOS.
 */
class FreeUsageStore(private val file: File) {
    var state by mutableStateOf(FreeUsageState())
        private set

    fun load() {
        val decoded = runCatching {
            if (file.exists()) fromJson(JSONObject(file.readText())) else null
        }.getOrNull()
        state = FreeUsageLedger.normalized(decoded ?: FreeUsageState())
        if (decoded == null) persist()
    }

    fun persist() {
        state = FreeUsageLedger.normalized(state)
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, file.name + ".new")
        tmp.writeText(toJson(state).toString())
        if (!tmp.renameTo(file)) {
            file.writeText(toJson(state).toString())
            tmp.delete()
        }
    }

    /** Consume un escaneo exitoso. Idempotente por attemptID. */
    fun consumeBoardScan(attemptID: String, isPro: Boolean): Boolean {
        val (next, consumed) = FreeUsageLedger.consumeBoardScan(state, attemptID, isPro)
        state = next
        if (consumed) persist()
        return consumed
    }

    fun resetForDebug() {
        state = FreeUsageLedger.normalized(FreeUsageState())
        persist()
    }

    companion object {
        private const val FILE_NAME = "free_usage.json"

        fun forAccount(folder: File): FreeUsageStore =
            FreeUsageStore(File(folder, FILE_NAME))

        fun toJson(state: FreeUsageState): JSONObject = JSONObject()
            .put("boardScanPeriodKey", state.boardScanPeriodKey)
            .put("boardScansConsumed", state.boardScansConsumed)
            .put("consumedAttemptIDs", JSONArray(state.consumedAttemptIDs))
            .put("lastBoardScanConsumedAt", state.lastBoardScanConsumedAt?.let {
                java.time.Instant.ofEpochMilli(it).toString()
            } ?: JSONObject.NULL)

        fun fromJson(obj: JSONObject): FreeUsageState = FreeUsageState(
            boardScanPeriodKey = obj.optString("boardScanPeriodKey", ""),
            boardScansConsumed = obj.optInt("boardScansConsumed", 0),
            consumedAttemptIDs = obj.optJSONArray("consumedAttemptIDs")?.let { arr ->
                (0 until arr.length()).map { arr.getString(it) }
            } ?: emptyList(),
            lastBoardScanConsumedAt = obj.optString("lastBoardScanConsumedAt", "")
                .takeIf { it.isNotEmpty() && it != "null" }
                ?.let { runCatching { java.time.Instant.parse(it).toEpochMilli() }.getOrNull() }
        )
    }
}
