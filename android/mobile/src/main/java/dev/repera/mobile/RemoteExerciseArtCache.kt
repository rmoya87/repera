package dev.repera.mobile

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * JPG públicos de Storage `exercise-art` → filesDir/exercise-art-remote/.
 * Solo arte editorial; sin historial ni JSON de cuenta.
 */
internal object RemoteExerciseArtCache {
    private val http = OkHttpClient.Builder().callTimeout(25, TimeUnit.SECONDS).build()

    fun directory(context: Context): File =
        File(context.filesDir, "exercise-art-remote").also { it.mkdirs() }

    fun fileFor(context: Context, stem: String): File {
        val safe = stem.replace("/", "_").replace("..", "_")
        return File(directory(context), "$safe.jpg")
    }

    fun hasFile(context: Context, stem: String): Boolean = fileFor(context, stem).isFile

    fun prefetchFromCatalogCache(context: Context) {
        val cache = File(context.filesDir, "exercise_catalog_remote_v1.json")
        if (!cache.isFile) return
        val roots = runCatching {
            JSONObject(cache.readText(Charsets.UTF_8)).optJSONObject("entries")
        }.getOrNull() ?: return
        val stems = mutableSetOf<String>()
        val keys = roots.keys()
        while (keys.hasNext()) {
            val entry = roots.optJSONObject(keys.next()) ?: continue
            val arts = entry.optJSONArray("art_keys") ?: continue
            for (i in 0 until arts.length()) {
                arts.optString(i).takeIf { it.isNotBlank() }?.let { stems.add(it) }
            }
        }
        for (stem in stems.sorted()) {
            if (hasFile(context, stem)) continue
            download(context, stem)
        }
    }

    private fun download(context: Context, stem: String) {
        val safe = stem.replace("/", "_").replace("..", "_")
        if (safe != stem) return
        val url = BuildConfig.SUPABASE_URL +
            "/storage/v1/object/public/exercise-art/" + stem + ".jpg"
        val request = Request.Builder()
            .url(url)
            .header("apikey", BuildConfig.SUPABASE_PUBLISHABLE_KEY)
            .get()
            .build()
        runCatching {
            http.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return
                val bytes = response.body.bytes()
                if (bytes.isEmpty()) return
                val dest = fileFor(context, stem)
                val tmp = File(dest.path + ".tmp")
                tmp.writeBytes(bytes)
                if (!tmp.renameTo(dest)) {
                    dest.writeBytes(bytes)
                    tmp.delete()
                }
            }
        }
    }
}
