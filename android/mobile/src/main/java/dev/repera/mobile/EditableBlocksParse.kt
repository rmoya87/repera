package dev.repera.mobile

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import org.json.JSONArray

/**
 * Convierte `editableBlocksJson` (snapshot de sesión terminada) a
 * [RoutineBlockInfo] para reutilizar [RoutineBlocksEditorScreen] al editar.
 */
internal fun parseRoutineBlocksFromEditableJson(
    editableBlocksJson: String?,
    catalog: List<ExerciseEntry>
): List<RoutineBlockInfo> {
    val raw = editableBlocksJson?.takeIf { it.isNotBlank() } ?: return emptyList()
    val array = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
    val catalogNameById = catalog.associate { it.id to it.name }
    return (0 until array.length()).map { bi ->
        val block = array.getJSONObject(bi)
        val kind = block.optString("kind")
        val entries = if (kind == "strength") {
            block.optJSONArray("exercises")?.let { exs ->
                (0 until exs.length()).map { ei ->
                    val ex = exs.getJSONObject(ei)
                    val planned = ex.optJSONArray("plannedSets")
                    val first = planned?.optJSONObject(0)
                    RoutineBlockEntryInfo(
                        id = ex.optString("id").ifBlank { null },
                        sourceJson = ex.toString(),
                        exerciseId = ex.getString("exerciseId"),
                        name = ex.optString("name").ifBlank {
                            catalogNameById[ex.getString("exerciseId")].orEmpty()
                        },
                        quantity = first?.optInt("targetReps")?.takeIf { it > 0 } ?: 8,
                        sets = planned?.length() ?: 1,
                        weightKg = if (first?.has("targetWeightKg") == true)
                            first.getDouble("targetWeightKg") else null,
                        quantityUnit = ex.optString("quantityUnit").ifBlank { null },
                        plannedSets = planned?.let { arr ->
                            (0 until arr.length()).map { si ->
                                val ps = arr.getJSONObject(si)
                                PlannedSetDraft(
                                    id = ps.optString("id").ifBlank { null },
                                    targetReps = ps.optInt("targetReps", 8),
                                    targetWeightKg = if (ps.has("targetWeightKg") &&
                                        !ps.isNull("targetWeightKg")
                                    ) ps.getDouble("targetWeightKg") else null,
                                    targetRir = if (ps.has("targetRir") && !ps.isNull("targetRir"))
                                        ps.getDouble("targetRir") else null,
                                    targetDurationSeconds = if (
                                        ps.has("targetDurationSeconds") &&
                                        !ps.isNull("targetDurationSeconds")
                                    ) ps.getInt("targetDurationSeconds") else null,
                                    sourceJson = EditorBlockOps.plannedSetUnknownFields(ps)
                                )
                            }
                        }
                    )
                }
            }.orEmpty()
        } else {
            block.optJSONArray("movements")?.let { mv ->
                (0 until mv.length()).map { mi ->
                    val m = mv.getJSONObject(mi)
                    RoutineBlockEntryInfo(
                        id = m.optString("id").ifBlank { null },
                        sourceJson = m.toString(),
                        exerciseId = m.optString("exerciseId"),
                        name = m.optString("name"),
                        quantity = when {
                            m.has("reps") -> m.getInt("reps")
                            m.has("calories") -> m.getInt("calories")
                            m.has("distanceMeters") -> m.getInt("distanceMeters")
                            else -> 1
                        },
                        weightKg = m.optDouble("weightMaleKg").takeIf { m.has("weightMaleKg") },
                        quantityUnit = m.optString("quantityUnit").ifBlank { null }
                            ?: if (m.has("distanceMeters")) "meters"
                            else if (m.has("calories")) "calories" else null
                    )
                }
            }.orEmpty()
        }
        val scheme = block.optJSONArray("movements")?.optJSONObject(0)
            ?.optJSONArray("repScheme")
            ?.let { s -> (0 until s.length()).map { s.getInt(it) } }
        RoutineBlockInfo(
            id = block.optString("id").ifBlank { null },
            sourceJson = block.toString(),
            title = block.optString("title"),
            format = when {
                kind == "strength" ->
                    block.optString("wodFormat").takeIf {
                        it.isNotBlank() && it != "null" &&
                            block.has("wodFormat") && !block.isNull("wodFormat")
                    }.orEmpty()
                else -> block.optString("wodFormat").ifBlank { "strength" }
            },
            timeCapMinutes = block.optInt("timeCapMinutes", 12),
            rounds = block.optInt("rounds", 1),
            emomIntervalSeconds = block.optInt("emomIntervalSeconds", 60),
            workSeconds = block.optInt("workSeconds", 20),
            restSeconds = block.optInt(
                "restBetweenRoundsSeconds",
                block.optInt("restSeconds", 10)
            ),
            ladderScheme = scheme,
            entries = entries
        )
    }
}

/** Instantánea estable del historial para no cerrar el editor si overview se refresca. */
@Composable
internal fun rememberCachedHistoryWorkout(
    workoutId: String,
    overview: StateOverview?
): WorkoutHistoryEntry? {
    var cached by remember(workoutId) { mutableStateOf<WorkoutHistoryEntry?>(null) }
    val current = overview?.completeHistory.orEmpty().firstOrNull { it.id == workoutId }
    LaunchedEffect(current) {
        if (current != null) cached = current
    }
    return current ?: cached
}
