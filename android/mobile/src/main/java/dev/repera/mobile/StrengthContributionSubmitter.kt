package dev.repera.mobile

import dev.repera.domain.StrengthBenchmarkLiftResolver
import dev.repera.domain.StrengthContributionBands
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** Best-effort anonymous Amateur contribution when a tested 1RM is saved. */
internal object StrengthContributionSubmitter {
    private val http = OkHttpClient.Builder()
        .connectTimeout(12, TimeUnit.SECONDS)
        .readTimeout(12, TimeUnit.SECONDS)
        .build()
    private val executor = Executors.newSingleThreadExecutor()

    fun submitIfNeeded(
        exerciseName: String,
        testedOneRMKg: Double?,
        settings: TrainingSettings,
        bodyWeightKg: Double?,
        accessToken: String?
    ) {
        val kg = testedOneRMKg?.takeIf { it.isFinite() && it > 0 } ?: return
        if (!settings.contributeAnonymousStrengthStats) return
        val token = accessToken?.takeIf { it.isNotBlank() } ?: return
        val lift = StrengthBenchmarkLiftResolver.liftForExerciseName(exerciseName) ?: return
        val sex = settings.competitionSex ?: return
        val birthYear = settings.birthYear ?: return
        val bodyKg = bodyWeightKg?.takeIf { it.isFinite() && it > 0 } ?: return
        val age = java.time.Year.now().value - birthYear
        if (StrengthContributionBands.ageBand(age) == null) return
        if (StrengthContributionBands.bodyWeightBand(bodyKg) == null) return
        val payload = JSONObject()
            .put("p_lift", StrengthBenchmarkLiftResolver.wire(lift))
            .put("p_sex", sex)
            .put("p_age", age)
            .put("p_body_weight_kg", bodyKg)
            .put("p_weight_kg", kg)
            .put("p_source_app", "android")
        executor.execute {
            runCatching {
                val body = payload.toString().toRequestBody("application/json".toMediaType())
                val request = Request.Builder()
                    .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/submit_strength_benchmark_contribution")
                    .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
                    .header("Authorization", "Bearer $token")
                    .header("Accept", "application/json")
                    .post(body)
                    .build()
                http.newCall(request).execute().use { /* best-effort; ignore body */ }
            }
        }
    }
}
