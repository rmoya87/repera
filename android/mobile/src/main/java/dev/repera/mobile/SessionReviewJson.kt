package dev.repera.mobile

import dev.repera.domain.AthleteLevel
import dev.repera.domain.ExerciseInput
import dev.repera.domain.ExerciseInputMode
import dev.repera.domain.ExerciseLoadField
import dev.repera.domain.ExerciseLoggingStyle
import dev.repera.domain.MovementReview
import dev.repera.domain.MovementVerdict
import dev.repera.domain.ReviewDimension
import dev.repera.domain.ReviewExercise
import dev.repera.domain.ReviewIndicator
import dev.repera.domain.ReviewLoggedSet
import dev.repera.domain.ReviewPlannedSet
import dev.repera.domain.ReviewRoutineBlock
import dev.repera.domain.ReviewSessionExercise
import dev.repera.domain.ReviewWodBlockResult
import dev.repera.domain.ReviewWodMovement
import dev.repera.domain.ReviewWorkoutSession
import dev.repera.domain.ScoreBasis
import dev.repera.domain.SessionReview
import dev.repera.domain.WodFormat
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

/**
 * Adaptador JSON ⇄ modelo de valoración. Claves y valores wire idénticos al
 * Codable de iOS (SessionReview se persiste dentro de la sesión, clave
 * "sessionReview", y se sincroniza entre plataformas).
 */
object SessionReviewJson {

    // MARK: - Serialización (wire = Codable iOS)

    fun toJson(review: SessionReview): JSONObject {
        val obj = JSONObject()
        obj.put("overallScore", review.overallScore)
        review.level?.let { obj.put("level", it.wire) }
        obj.put("headline", review.headline)
        review.vsHistorySummary?.let { obj.put("vsHistorySummary", it) }
        review.vsStandardSummary?.let { obj.put("vsStandardSummary", it) }
        obj.put("keepTips", JSONArray(review.keepTips))
        obj.put("improveTips", JSONArray(review.improveTips))
        obj.put("movements", JSONArray().also { arr ->
            review.movements.forEach { movement ->
                arr.put(JSONObject()
                    .put("id", movement.id)
                    .put("name", movement.name)
                    .put("verdict", movement.verdict.wire)
                    .put("detail", movement.detail).also { m ->
                        movement.exerciseId?.let { m.put("exerciseId", it) }
                        movement.comparedToName?.let { m.put("comparedToName", it) }
                        movement.performanceRatio?.let { m.put("performanceRatio", it) }
                    })
            }
        })
        review.wodTemplateId?.let { obj.put("wodTemplateId", it) }
        review.scoreBasis?.let { obj.put("scoreBasis", it.wire) }
        obj.put("indicators", JSONArray().also { arr ->
            review.indicators.forEach { indicator ->
                arr.put(JSONObject()
                    .put("dimension", indicator.dimension.wire)
                    .put("detail", indicator.detail)
                    .put("referenceSessions", indicator.referenceSessions).also { i ->
                        indicator.score?.let { i.put("score", it) }
                        indicator.comparisonLevel?.let { i.put("comparisonLevel", it) }
                    })
            }
        })
        review.evidenceCoverage?.let { obj.put("evidenceCoverage", it) }
        review.confidenceLabel?.let { obj.put("confidenceLabel", it) }
        return obj
    }

    fun fromJson(obj: JSONObject): SessionReview? = runCatching {
        val movements = obj.optJSONArray("movements") ?: JSONArray()
        val indicators = obj.optJSONArray("indicators") ?: JSONArray()
        SessionReview(
            overallScore = obj.getInt("overallScore"),
            level = obj.optString("level").takeIf { it.isNotBlank() }
                ?.let { AthleteLevel.fromWire(it) },
            headline = obj.getString("headline"),
            vsHistorySummary = obj.optString("vsHistorySummary").takeIf { it.isNotBlank() },
            vsStandardSummary = obj.optString("vsStandardSummary").takeIf { it.isNotBlank() },
            keepTips = obj.optJSONArray("keepTips")?.let { a ->
                (0 until a.length()).map { a.getString(it) } } ?: emptyList(),
            improveTips = obj.optJSONArray("improveTips")?.let { a ->
                (0 until a.length()).map { a.getString(it) } } ?: emptyList(),
            movements = (0 until movements.length()).map { i ->
                val m = movements.getJSONObject(i)
                MovementReview(
                    id = m.optString("id"),
                    exerciseId = m.optString("exerciseId").takeIf { it.isNotBlank() },
                    name = m.optString("name"),
                    verdict = MovementVerdict.fromWire(m.optString("verdict"))
                        ?: MovementVerdict.GOOD,
                    detail = m.optString("detail"),
                    comparedToName = m.optString("comparedToName").takeIf { it.isNotBlank() },
                    performanceRatio = if (m.has("performanceRatio") && !m.isNull("performanceRatio"))
                        m.getDouble("performanceRatio") else null
                )
            },
            wodTemplateId = obj.optString("wodTemplateId").takeIf { it.isNotBlank() },
            scoreBasis = obj.optString("scoreBasis").takeIf { it.isNotBlank() }
                ?.let { ScoreBasis.fromWire(it) },
            indicators = (0 until indicators.length()).mapNotNull { i ->
                val ind = indicators.getJSONObject(i)
                val dimension = ReviewDimension.fromWire(ind.optString("dimension"))
                    ?: return@mapNotNull null
                ReviewIndicator(
                    dimension = dimension,
                    score = if (ind.has("score") && !ind.isNull("score"))
                        ind.getInt("score") else null,
                    detail = ind.optString("detail"),
                    referenceSessions = ind.optInt("referenceSessions"),
                    comparisonLevel = if (ind.has("comparisonLevel") && !ind.isNull("comparisonLevel"))
                        ind.getInt("comparisonLevel") else null
                )
            },
            evidenceCoverage = if (obj.has("evidenceCoverage") && !obj.isNull("evidenceCoverage"))
                obj.getDouble("evidenceCoverage") else null,
            confidenceLabel = obj.optString("confidenceLabel").takeIf { it.isNotBlank() }
        )
    }.getOrNull()

    // MARK: - Sesión JSON → modelo tipado del motor

    fun sessionToModel(session: JSONObject): ReviewWorkoutSession {
        val exercisesJson = session.optJSONArray("exercises") ?: JSONArray()
        val exercises = (0 until exercisesJson.length()).mapNotNull { i ->
            val entry = exercisesJson.optJSONObject(i) ?: return@mapNotNull null
            val detail = entry.optJSONObject("exercise") ?: return@mapNotNull null
            val name = detail.optString("name")
            if (name.isBlank()) return@mapNotNull null
            val equipment = detail.optString("equipment").takeIf { it.isNotBlank() }
            val target = detail.optString("targetMuscle").takeIf { it.isNotBlank() }
            val group = detail.optString("muscleGroup").takeIf { it.isNotBlank() }
            val sportTag = detail.optString("sportTag").takeIf { it.isNotBlank() }
            val mode = ExerciseInput.mode(name, equipment, target, group, sportTag)
            val style = when (mode) {
                ExerciseInputMode.LOAD_REPS, ExerciseInputMode.HSPU_DEFICIT ->
                    ExerciseLoggingStyle.LOAD_AND_REPS
                ExerciseInputMode.REPS_ONLY -> ExerciseLoggingStyle.REPS_ONLY
                ExerciseInputMode.REPS_AND_TIME -> ExerciseLoggingStyle.REPS_AND_TIME
                ExerciseInputMode.MACHINE_WORK, ExerciseInputMode.LOAD_DISTANCE ->
                    ExerciseLoggingStyle.MACHINE_WORK
            }
            val loadField = when (mode) {
                ExerciseInputMode.LOAD_REPS -> ExerciseLoadField.WEIGHT_KG
                ExerciseInputMode.HSPU_DEFICIT -> ExerciseLoadField.DEFICIT_CM
                else -> ExerciseLoadField.NONE
            }
            val planned = entry.optJSONArray("plannedSets") ?: JSONArray()
            val logged = entry.optJSONArray("loggedSets") ?: JSONArray()
            ReviewSessionExercise(
                id = entry.optString("id"),
                exercise = ReviewExercise(
                    id = detail.optString("id").ifBlank { entry.optString("exerciseId") },
                    name = name,
                    equipment = equipment,
                    catalogId = detail.optString("catalogId").takeIf { it.isNotBlank() },
                    loggingStyle = style,
                    loadField = loadField
                ),
                plannedSets = (0 until planned.length()).map { p ->
                    val set = planned.getJSONObject(p)
                    ReviewPlannedSet(
                        targetReps = set.optInt("targetReps"),
                        targetWeightKg = if (set.has("targetWeightKg") && !set.isNull("targetWeightKg"))
                            set.getDouble("targetWeightKg") else null
                    )
                },
                loggedSets = (0 until logged.length()).map { s ->
                    val set = logged.getJSONObject(s)
                    ReviewLoggedSet(
                        reps = set.optInt("reps"),
                        weightKg = if (set.has("weightKg") && !set.isNull("weightKg"))
                            set.getDouble("weightKg") else null,
                        durationSeconds = set.optInt("durationSeconds").takeIf { it > 0 },
                        isWarmup = set.optString("phase") == "warmup",
                        rir = if (set.has("rir") && !set.isNull("rir")) set.getDouble("rir") else null
                    )
                },
                adaptedReps = entry.optInt("adaptedReps").takeIf { it > 0 },
                adaptedWeightKg = if (entry.has("adaptedWeightKg") && !entry.isNull("adaptedWeightKg"))
                    entry.getDouble("adaptedWeightKg") else null,
                blockId = entry.optString("blockId").takeIf { it.isNotBlank() },
                wodFormat = WodFormat.fromWire(entry.optString("wodFormat")),
                blockTimeCapMinutes = entry.optInt("blockTimeCapMinutes").takeIf { it > 0 },
                blockIntervalSeconds = entry.optInt("blockIntervalSeconds").takeIf { it > 0 }
            )
        }
        val resultsJson = session.optJSONArray("wodResults") ?: JSONArray()
        val results = (0 until resultsJson.length()).mapNotNull { i ->
            val r = resultsJson.optJSONObject(i) ?: return@mapNotNull null
            ReviewWodBlockResult(
                id = r.optString("id"),
                format = WodFormat.fromWire(r.optString("format")),
                totalReps = if (r.has("totalReps") && !r.isNull("totalReps")) r.getInt("totalReps") else null,
                elapsedSeconds = if (r.has("elapsedSeconds") && !r.isNull("elapsedSeconds")) r.getInt("elapsedSeconds") else null,
                roundsCompleted = if (r.has("roundsCompleted") && !r.isNull("roundsCompleted")) r.getInt("roundsCompleted") else null,
                wodTemplateId = r.optString("wodTemplateId").takeIf { it.isNotBlank() }
            )
        }
        val blocksJson = session.optJSONArray("routineBlocks")
        val blocks = blocksJson?.let { arr ->
            (0 until arr.length()).mapNotNull { i ->
                val b = arr.optJSONObject(i) ?: return@mapNotNull null
                val movesJson = b.optJSONArray("movements") ?: JSONArray()
                ReviewRoutineBlock(
                    id = b.optString("id"),
                    title = b.optString("title"),
                    movements = (0 until movesJson.length()).mapNotNull { m ->
                        val move = movesJson.optJSONObject(m) ?: return@mapNotNull null
                        ReviewWodMovement(
                            name = move.optString("name"),
                            reps = move.optInt("reps").takeIf { it > 0 },
                            repScheme = move.optJSONArray("repScheme")?.let { rs ->
                                (0 until rs.length()).map { rs.getInt(it) } },
                            distanceMeters = move.optInt("distanceMeters").takeIf { it > 0 },
                            calories = move.optInt("calories").takeIf { it > 0 },
                            weightMaleKg = if (move.has("weightMaleKg") && !move.isNull("weightMaleKg"))
                                move.getDouble("weightMaleKg") else null,
                            weightFemaleKg = if (move.has("weightFemaleKg") && !move.isNull("weightFemaleKg"))
                                move.getDouble("weightFemaleKg") else null,
                            isRest = move.optBoolean("isRest"),
                            scaleAlternative = move.optString("scaleAlternative").takeIf { it.isNotBlank() }
                        )
                    },
                    wodFormat = WodFormat.fromWire(b.optString("wodFormat")),
                    timeCapMinutes = b.optInt("timeCapMinutes").takeIf { it > 0 },
                    emomIntervalSeconds = b.optInt("emomIntervalSeconds").takeIf { it > 0 },
                    rounds = b.optInt("rounds").takeIf { it > 0 }
                )
            }
        }
        val finished = session.optString("phase") == "finished" ||
            session.optString("finishedAt").isNotBlank()
        val finishedMillis = runCatching {
            Instant.parse(session.optString("finishedAt")).toEpochMilli()
        }.getOrNull()
        return ReviewWorkoutSession(
            id = session.optString("id"),
            title = session.optString("title"),
            finished = finished,
            finishedAtMillis = finishedMillis,
            exercises = exercises,
            wodResults = results,
            routineBlocks = blocks
        )
    }
}
