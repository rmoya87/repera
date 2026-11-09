package dev.repera.mobile

import android.content.Context
import dev.repera.domain.StrengthBenchmarkCohort
import dev.repera.domain.StrengthBenchmarkDistribution
import dev.repera.domain.StrengthBenchmarkEquipment
import dev.repera.domain.StrengthBenchmarkLift
import dev.repera.domain.StrengthBenchmarkLiftResolver
import dev.repera.domain.StrengthBenchmarkQuantile
import dev.repera.domain.StrengthBenchmarkSex
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Cuantiles de fuerza desde Supabase (copia propia OPL + SymmetricStrength).
 * Sin llamadas a terceros. El asset empaquetado solo arranca offline.
 */
internal class StrengthBenchmarkRemoteStore(private val context: Context) {
    private val http = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(45, TimeUnit.SECONDS)
        .build()
    private val cacheFile = File(context.filesDir, "strength_benchmarks_remote_v1.json")
    private val gate = Any()

    @Volatile private var memory: Cache? = null

    fun current(): List<StrengthBenchmarkDistribution> = synchronized(gate) {
        memory?.rows?.takeIf { it.isNotEmpty() }?.let { return it }
        val disk = readDisk()
        if (disk != null && disk.rows.isNotEmpty()) {
            memory = disk
            return disk.rows
        }
        val seed = bundleSeed()
        memory = Cache(0, seed)
        return seed
    }

    fun refresh(accessToken: String): Boolean = synchronized(gate) {
        require(accessToken.isNotBlank())
        var working = memory ?: readDisk() ?: Cache(0, bundleSeed())
        if (working.rows.isEmpty()) working = Cache(0, bundleSeed())

        val head = fetchHead(accessToken)
        if (working.revision == head && working.rows.isNotEmpty()) {
            memory = working
            writeDisk(working)
            return false
        }
        val lag = head - working.revision
        working = if (working.revision == 0L || working.rows.isEmpty() || lag > 200) {
            val boot = fetchBootstrap(accessToken)
            val rows = parseDistributions(boot.optJSONArray("distributions") ?: JSONArray())
            require(rows.isNotEmpty()) { "bootstrap vacío" }
            Cache(boot.optLong("revision", 0), rows)
        } else {
            val delta = fetchDelta(accessToken, working.revision)
            val byKey = working.rows.associateBy { key(it) }.toMutableMap()
            val events = delta.optJSONArray("events") ?: JSONArray()
            for (i in 0 until events.length()) {
                val event = events.getJSONObject(i)
                when (event.optString("operation")) {
                    "upsert" -> {
                        parseRow(event.optJSONObject("payload"))?.let { byKey[key(it)] = it }
                    }
                    "delete" -> {
                        parseRow(event.optJSONObject("payload"))?.let { byKey.remove(key(it)) }
                    }
                }
            }
            Cache(delta.optLong("revision", working.revision), byKey.values.toList())
        }
        memory = working
        writeDisk(working)
        true
    }

    private fun fetchHead(accessToken: String): Long {
        val request = Request.Builder()
            .url(
                BuildConfig.SUPABASE_URL +
                    "/rest/v1/strength_benchmark_events?select=id&order=id.desc&limit=1"
            )
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer $accessToken")
            .header("Accept", "application/json")
            .get()
            .build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("head HTTP ${response.code}")
            val arr = JSONArray(response.body.string().orEmpty().ifBlank { "[]" })
            if (arr.length() == 0) return 0L
            return arr.getJSONObject(0).optLong("id", 0)
        }
    }

    private fun fetchBootstrap(accessToken: String): JSONObject {
        val body = "{}".toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/strength_benchmark_bootstrap")
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer $accessToken")
            .header("Accept", "application/json")
            .post(body)
            .build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("bootstrap HTTP ${response.code}")
            return JSONObject(response.body.string())
        }
    }

    private fun fetchDelta(accessToken: String, after: Long): JSONObject {
        val body = JSONObject().put("p_after_revision", after)
            .toString().toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(BuildConfig.SUPABASE_URL + "/rest/v1/rpc/strength_benchmark_delta")
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .header("Authorization", "Bearer $accessToken")
            .header("Accept", "application/json")
            .post(body)
            .build()
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IllegalStateException("delta HTTP ${response.code}")
            return JSONObject(response.body.string())
        }
    }

    private fun readDisk(): Cache? = runCatching {
        if (!cacheFile.exists()) return null
        val root = JSONObject(cacheFile.readText())
        Cache(
            root.optLong("revision", 0),
            parseDistributions(root.optJSONArray("rows") ?: JSONArray())
        )
    }.getOrNull()

    private fun writeDisk(cache: Cache) {
        val arr = JSONArray()
        cache.rows.forEach { arr.put(encode(it)) }
        cacheFile.writeText(
            JSONObject().put("revision", cache.revision).put("rows", arr).toString()
        )
    }

    private fun bundleSeed(): List<StrengthBenchmarkDistribution> {
        return runCatching {
            val raw = context.assets.open("strength_benchmarks.json")
                .bufferedReader(Charsets.UTF_8).use { it.readText() }
            parseDistributions(JSONArray(raw))
        }.getOrDefault(emptyList())
    }

    private data class Cache(val revision: Long, val rows: List<StrengthBenchmarkDistribution>)

    companion object {
        @Volatile private var singleton: StrengthBenchmarkRemoteStore? = null
        fun get(context: Context): StrengthBenchmarkRemoteStore {
            singleton?.let { return it }
            return synchronized(this) {
                singleton ?: StrengthBenchmarkRemoteStore(context.applicationContext).also {
                    singleton = it
                }
            }
        }

        private fun key(row: StrengthBenchmarkDistribution): String {
            val c = row.cohort
            return listOf(
                c.lift.name, c.sex.name, c.equipment.name,
                c.ageMin.toString(), c.ageMax.toString(),
                c.bodyWeightMinKg.toString(), c.bodyWeightMaxKg.toString(),
                row.source, row.sourceRevision
            ).joinToString("|")
        }

        private fun parseDistributions(arr: JSONArray): List<StrengthBenchmarkDistribution> =
            buildList {
                for (i in 0 until arr.length()) {
                    parseRow(arr.optJSONObject(i))?.let(::add)
                }
            }

        private fun parseRow(row: JSONObject?): StrengthBenchmarkDistribution? {
            row ?: return null
            if (row.has("isActive") && !row.optBoolean("isActive", true)) return null
            val c = row.optJSONObject("cohort") ?: return null
            val lift = StrengthBenchmarkLiftResolver.fromWire(c.optString("lift")) ?: return null
            val sex = when (c.optString("sex")) {
                "female" -> StrengthBenchmarkSex.FEMALE
                "male" -> StrengthBenchmarkSex.MALE
                else -> return null
            }
            val q = row.optJSONArray("quantiles") ?: return null
            val points = buildList {
                for (i in 0 until q.length()) {
                    val x = q.optJSONObject(i) ?: continue
                    add(StrengthBenchmarkQuantile(x.getDouble("percentile"), x.getDouble("weightKg")))
                }
            }
            if (points.size < 2) return null
            return StrengthBenchmarkDistribution(
                cohort = StrengthBenchmarkCohort(
                    lift, sex, StrengthBenchmarkEquipment.RAW,
                    c.getInt("ageMin"), c.getInt("ageMax"),
                    c.getDouble("bodyWeightMinKg"), c.getDouble("bodyWeightMaxKg")
                ),
                source = row.getString("source"),
                sourceRevision = row.getString("sourceRevision"),
                sampleCount = row.getInt("sampleCount"),
                quantiles = points
            )
        }

        private fun encode(row: StrengthBenchmarkDistribution): JSONObject {
            val c = row.cohort
            val lift = StrengthBenchmarkLiftResolver.wire(c.lift)
            val sex = when (c.sex) {
                StrengthBenchmarkSex.FEMALE -> "female"
                StrengthBenchmarkSex.MALE -> "male"
            }
            val q = JSONArray()
            row.quantiles.forEach {
                q.put(JSONObject().put("percentile", it.percentile).put("weightKg", it.weightKg))
            }
            return JSONObject()
                .put(
                    "cohort",
                    JSONObject()
                        .put("lift", lift)
                        .put("sex", sex)
                        .put("equipment", "raw")
                        .put("ageMin", c.ageMin)
                        .put("ageMax", c.ageMax)
                        .put("bodyWeightMinKg", c.bodyWeightMinKg)
                        .put("bodyWeightMaxKg", c.bodyWeightMaxKg)
                )
                .put("source", row.source)
                .put("sourceRevision", row.sourceRevision)
                .put("sampleCount", row.sampleCount)
                .put("quantiles", q)
                .put("isActive", true)
        }
    }
}
