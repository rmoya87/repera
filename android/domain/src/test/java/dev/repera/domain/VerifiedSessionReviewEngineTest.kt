package dev.repera.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

/** Port 1:1 de SessionReviewEngineTests.swift (fórmula v11). */
class VerifiedSessionReviewEngineTest {

    private val today = 1_800_000_000_000L
    private fun ex(name: String, equipment: String? = null) = ReviewExercise(
        id = UUID.randomUUID().toString(), name = name, equipment = equipment,
        loggingStyle = when {
            equipment != null -> ExerciseLoggingStyle.LOAD_AND_REPS
            else -> ExerciseLoggingStyle.REPS_ONLY
        },
        loadField = if (equipment != null) ExerciseLoadField.WEIGHT_KG else ExerciseLoadField.NONE
    )
    private val push = ex("Push press", "Barra")
    private val bench = ex("Press banca", "Barra")

    private fun strength(
        exercise: ReviewExercise, kg: Double, reps: Int = 5, daysAgo: Double,
        id: String = UUID.randomUUID().toString(), targetKg: Double? = null,
        wodFormat: WodFormat? = null, blockIntervalSeconds: Int? = null, rir: Double? = null
    ): ReviewWorkoutSession {
        val finish = today - (daysAgo * 86_400_000).toLong()
        return ReviewWorkoutSession(
            id = id, title = exercise.name, finished = true, finishedAtMillis = finish,
            exercises = listOf(
                ReviewSessionExercise(
                    id = UUID.randomUUID().toString(),
                    exercise = exercise,
                    plannedSets = listOf(ReviewPlannedSet(reps, targetKg ?: kg)),
                    loggedSets = listOf(ReviewLoggedSet(reps = reps, weightKg = kg, rir = rir)),
                    wodFormat = wodFormat,
                    blockIntervalSeconds = blockIntervalSeconds
                )
            ),
            wodResults = emptyList(), routineBlocks = null
        )
    }

    private fun amrap(
        rounds: Int, partial: Int = 0, reps: Int = 10, daysAgo: Double, weight: Double = 0.0
    ): ReviewWorkoutSession {
        val exercise = ex("Burpee box jump over")
        val blockId = UUID.randomUUID().toString()
        val finish = today - (daysAgo * 86_400_000).toLong()
        return ReviewWorkoutSession(
            id = UUID.randomUUID().toString(), title = "AMRAP 8'", finished = true,
            finishedAtMillis = finish,
            exercises = listOf(
                ReviewSessionExercise(
                    id = UUID.randomUUID().toString(), exercise = exercise,
                    plannedSets = listOf(ReviewPlannedSet(reps)),
                    loggedSets = emptyList(),
                    blockId = blockId, wodFormat = WodFormat.AMRAP,
                    blockTimeCapMinutes = 8
                )
            ),
            wodResults = listOf(
                ReviewWodBlockResult(
                    id = blockId, format = WodFormat.AMRAP,
                    totalReps = partial, roundsCompleted = rounds)
            ),
            routineBlocks = listOf(
                ReviewRoutineBlock(
                    id = blockId, title = "AMRAP 8'",
                    movements = listOf(
                        ReviewWodMovement(name = exercise.name, reps = reps,
                            weightMaleKg = if (weight == 0.0) null else weight)),
                    wodFormat = WodFormat.AMRAP, timeCapMinutes = 8
                )
            )
        )
    }

    private fun review(s: ReviewWorkoutSession, h: List<ReviewWorkoutSession>) =
        VerifiedSessionReviewEngine.review(s, h, nowMillis = today)

    @Test fun noScoreOnFirstSessionEvenWithHighLoad() {
        val session = strength(push, 70.0, daysAgo = 0.0)
        assertNull(review(session, emptyList()))
    }

    @Test fun aSinglePreviousDayDoesNotQualify() {
        val prior = strength(push, 65.0, daysAgo = 2.0)
        val current = strength(push, 70.0, daysAgo = 0.0)
        assertNull(review(current, listOf(prior)))
    }

    @Test fun sameDayRepeatedSetsOrSessionsAreNotIndependentHistory() {
        val day1 = strength(push, 60.0, daysAgo = 1.2)
        val day1Again = strength(push, 65.0, daysAgo = 1.1)
        val current = strength(push, 70.0, daysAgo = 0.0)
        assertNull(review(current, listOf(day1, day1Again)))
    }

    @Test fun twoIndependentPreviousDaysUnlockThreeIndicatorsAndOverall() {
        val pastA = strength(push, 60.0, daysAgo = 6.0)
        val pastB = strength(push, 65.0, daysAgo = 3.0)
        val current = strength(push, 70.0, daysAgo = 0.0)
        val review = review(current, listOf(pastA, pastB))
        assertNotNull(review)
        review!!
        assertEquals(ScoreBasis.PERSONAL_HISTORY, review.scoreBasis)
        assertTrue(review.overallScore >= 7)
        assertNull(review.level)
        assertEquals(ReviewDimension.entries, review.indicators.map { it.dimension })
        assertNotNull(review.indicators[0].score)
        assertEquals(2, review.indicators[0].referenceSessions)
        assertNull(review.indicators[1].score) // registro no es nota
        assertNull(review.indicators[2].score) // WOD sin referencias
        assertEquals(1.0, review.evidenceCoverage!!, 1e-9)
    }

    @Test fun benchPressNeverUnlocksPushPressScore() {
        val a = strength(bench, 90.0, reps = 7, daysAgo = 5.0)
        val b = strength(bench, 95.0, reps = 7, daysAgo = 3.0)
        val current = strength(push, 70.0, reps = 2, daysAgo = 0.0)
        assertNull(review(current, listOf(a, b)))
        assertEquals(0.0, ExerciseEquivalence.transferFactor(current = push, prior = bench), 1e-9)
    }

    @Test fun lighterPrescribedDayMustNotBePunishedAsRegression() {
        val a = strength(push, 90.0, daysAgo = 6.0)
        val b = strength(push, 95.0, daysAgo = 3.0)
        val deload = strength(push, 60.0, daysAgo = 0.0, targetKg = 60.0)
        assertNull(review(deload, listOf(a, b)))
    }

    @Test fun twoSameWODPrescriptionsUnlockWODScore() {
        val a = amrap(rounds = 2, daysAgo = 7.0)
        val b = amrap(rounds = 3, daysAgo = 3.0)
        val current = amrap(rounds = 4, partial = 2, daysAgo = 0.0)
        val review = review(current, listOf(a, b))
        assertNotNull(review)
        review!!
        assertEquals(ScoreBasis.PERSONAL_HISTORY, review.scoreBasis)
        assertNull(review.indicators[0].score)
        assertNotNull(review.indicators[2].score)
        assertEquals(2, review.indicators[2].referenceSessions)
        assertTrue(review.overallScore > 0)
    }

    @Test fun adaptedOrDifferentPrescriptionCannotUnlockWODScore() {
        val a = amrap(rounds = 2, reps = 10, daysAgo = 7.0)
        val b = amrap(rounds = 3, reps = 12, daysAgo = 3.0)
        val current = amrap(rounds = 4, reps = 10, daysAgo = 0.0)
        assertNull(review(current, listOf(a, b)))
    }

    @Test fun insufficientCoverageHidesGlobalEvenIfOneExerciseQualifies() {
        val a = strength(push, 60.0, daysAgo = 8.0)
        val b = strength(push, 65.0, daysAgo = 4.0)
        val base = strength(push, 70.0, daysAgo = 0.0)
        val ex2 = ex("Peso muerto", "Barra")
        val ex3 = ex("Dominadas")
        val current = base.copy(exercises = base.exercises + listOf(
            ReviewSessionExercise(
                id = UUID.randomUUID().toString(), exercise = ex2,
                plannedSets = listOf(ReviewPlannedSet(5)),
                loggedSets = listOf(ReviewLoggedSet(reps = 5, weightKg = 110.0))),
            ReviewSessionExercise(
                id = UUID.randomUUID().toString(), exercise = ex3,
                plannedSets = listOf(ReviewPlannedSet(8)),
                loggedSets = listOf(ReviewLoggedSet(reps = 8)))
        ))
        assertNull(review(current, listOf(a, b)))
    }

    @Test fun oneHistoricallyComparableMovementCannotGradeLargeUnloggedWorkout() {
        val a = strength(push, 60.0, daysAgo = 8.0)
        val b = strength(push, 65.0, daysAgo = 4.0)
        val base = strength(push, 70.0, daysAgo = 0.0)
        val current = base.copy(exercises = base.exercises + listOf(
            ReviewSessionExercise(
                id = UUID.randomUUID().toString(), exercise = ex("Peso muerto", "Barra"),
                plannedSets = listOf(ReviewPlannedSet(5)), loggedSets = emptyList()),
            ReviewSessionExercise(
                id = UUID.randomUUID().toString(), exercise = ex("Sentadilla", "Barra"),
                plannedSets = listOf(ReviewPlannedSet(5)), loggedSets = emptyList())
        ))
        // Movimientos programados sin series cuentan contra la cobertura.
        assertNull(review(current, listOf(a, b)))
    }

    @Test fun samePushPressAcrossEMOMAndStrengthUsesTierTwoWithRIR() {
        val a = strength(push, 60.0, daysAgo = 7.0, wodFormat = WodFormat.EMOM,
            blockIntervalSeconds = 60, rir = 2.0)
        val b = strength(push, 65.0, daysAgo = 3.0, wodFormat = WodFormat.EMOM,
            blockIntervalSeconds = 60, rir = 2.0)
        val current = strength(push, 70.0, daysAgo = 0.0, rir = 2.0)
        val score = review(current, listOf(a, b))
        assertNotNull(score)
        score!!
        assertEquals(2, score.indicators[0].comparisonLevel)
        assertEquals(2, score.indicators[0].referenceSessions)
        assertTrue(score.confidenceLabel?.contains("Media") == true)
    }

    @Test fun differentFormatWithoutRIRStillDoesNotFabricateComparison() {
        val a = strength(push, 60.0, daysAgo = 7.0, wodFormat = WodFormat.EMOM)
        val b = strength(push, 65.0, daysAgo = 3.0, wodFormat = WodFormat.EMOM)
        val current = strength(push, 70.0, daysAgo = 0.0)
        assertNull(review(current, listOf(a, b)))
    }

    private fun differentFormatForTime(
        exerciseName: String = "Burpee box jump over",
        reps: Int = 12, minutes: Int = 8, daysAgo: Double
    ): ReviewWorkoutSession {
        val exercise = ex(exerciseName)
        val blockId = UUID.randomUUID().toString()
        val finish = today - (daysAgo * 86_400_000).toLong()
        return ReviewWorkoutSession(
            id = UUID.randomUUID().toString(), title = "For Time", finished = true,
            finishedAtMillis = finish,
            exercises = listOf(
                ReviewSessionExercise(
                    id = UUID.randomUUID().toString(), exercise = exercise,
                    plannedSets = listOf(ReviewPlannedSet(reps)),
                    loggedSets = emptyList(),
                    blockId = blockId, wodFormat = WodFormat.FOR_TIME,
                    blockTimeCapMinutes = 12
                )
            ),
            wodResults = listOf(
                ReviewWodBlockResult(id = blockId, format = WodFormat.FOR_TIME,
                    elapsedSeconds = minutes * 60)
            ),
            routineBlocks = listOf(
                ReviewRoutineBlock(
                    id = blockId, title = "3 RFT",
                    movements = listOf(ReviewWodMovement(name = exercise.name, reps = reps)),
                    wodFormat = WodFormat.FOR_TIME, timeCapMinutes = 12, rounds = 3
                )
            )
        )
    }

    @Test fun threePersonalWODDaysPermitCalibratedCrossFormatStimulus() {
        val earlier = listOf(
            differentFormatForTime(minutes = 8, daysAgo = 9.0),
            differentFormatForTime(minutes = 9, daysAgo = 6.0),
            differentFormatForTime(minutes = 7, daysAgo = 3.0)
        )
        val current = amrap(rounds = 4, partial = 0, reps = 10, daysAgo = 0.0)
        val result = review(current, earlier)
        assertNotNull(result)
        result!!
        assertEquals(3, result.indicators[2].comparisonLevel)
        assertEquals(3, result.indicators[2].referenceSessions)
        assertTrue(result.confidenceLabel?.contains("Baja") == true)
        assertTrue(result.indicators[2].detail.contains("densidad de reps"))
    }

    @Test fun stimulusRequiresThreeDaysAndSameMovementIdentity() {
        val a = differentFormatForTime(minutes = 8, daysAgo = 9.0)
        val b = differentFormatForTime(minutes = 9, daysAgo = 6.0)
        val current = amrap(rounds = 4, reps = 10, daysAgo = 0.0)
        assertNull(review(current, listOf(a, b)))
        val c = differentFormatForTime(exerciseName = "Press banca", daysAgo = 3.0)
        assertNull(review(current, listOf(a, b, c)))
    }

    @Test fun plannedButUnloggedMovementsNeverCreateScores() {
        val current = ReviewWorkoutSession(
            id = UUID.randomUUID().toString(), title = "Plan", finished = true,
            finishedAtMillis = today,
            exercises = listOf(
                ReviewSessionExercise(
                    id = UUID.randomUUID().toString(), exercise = push,
                    plannedSets = listOf(ReviewPlannedSet(5)), loggedSets = emptyList())
            ),
            wodResults = emptyList(), routineBlocks = null
        )
        assertNull(review(current, emptyList()))
    }
}
