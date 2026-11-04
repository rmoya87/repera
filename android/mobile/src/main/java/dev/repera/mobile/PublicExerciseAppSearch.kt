package dev.repera.mobile

import android.content.Context
import android.util.Log
import androidx.appsearch.app.AppSearchSchema
import androidx.appsearch.app.AppSearchSession
import androidx.appsearch.app.GenericDocument
import androidx.appsearch.app.PutDocumentsRequest
import androidx.appsearch.app.SetSchemaRequest
import androidx.appsearch.localstorage.LocalStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.withContext
import org.json.JSONArray

/**
 * Opt-in AppSearch index of the **public** exercise catalog only.
 * Private routines, Health Connect samples and custom exercises stay out.
 * Consent is account-scoped; clearing consent or signing out wipes documents.
 */
internal object PublicExerciseAppSearch {
    private const val PREFS = "repera.appsearch.consent"
    private const val DB = "repera-public-exercises"
    private const val NAMESPACE = "public"
    private const val SCHEMA = "PublicExercise"
    private const val TAG = "ReperaAppSearch"

    fun isConsentGranted(context: Context, accountId: String?): Boolean {
        if (accountId.isNullOrBlank()) return false
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(consentKey(accountId), false)
    }

    fun setConsent(context: Context, accountId: String?, granted: Boolean) {
        if (accountId.isNullOrBlank()) return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(consentKey(accountId), granted)
            .apply()
    }

    fun clearConsent(context: Context, accountId: String?) {
        if (accountId.isNullOrBlank()) return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(consentKey(accountId))
            .apply()
    }

    private fun consentKey(accountId: String) = "consent.$accountId"

    suspend fun reconcile(
        context: Context,
        accountId: String?,
        exercises: JSONArray,
    ) = withContext(Dispatchers.IO) {
        if (accountId.isNullOrBlank()) return@withContext
        if (!isConsentGranted(context, accountId)) {
            clearAll(context)
            return@withContext
        }
        try {
            val session = openSession(context)
            try {
                ensureSchema(session)
                val publicDocs = ArrayList<GenericDocument>()
                for (i in 0 until exercises.length()) {
                    val item = exercises.optJSONObject(i) ?: continue
                    if (item.optBoolean("isCustom") || item.optBoolean("isCatalogArchived")) continue
                    val id = item.optString("id")
                    val name = item.optString("name")
                    if (id.isBlank() || name.isBlank()) continue
                    publicDocs += GenericDocument.Builder<GenericDocument.Builder<*>>(NAMESPACE, id, SCHEMA)
                        .setPropertyString("name", name)
                        .setPropertyString("muscleGroup", item.optString("muscleGroup"))
                        .setScore(1)
                        .build()
                }
                session.putAsync(
                    PutDocumentsRequest.Builder().addGenericDocuments(publicDocs).build()
                ).await()
            } finally {
                session.close()
            }
        } catch (error: Exception) {
            Log.w(TAG, "AppSearch reconcile skipped", error)
        }
    }

    suspend fun clearAll(context: Context) = withContext(Dispatchers.IO) {
        try {
            val session = openSession(context)
            try {
                session.setSchemaAsync(
                    SetSchemaRequest.Builder()
                        .setForceOverride(true)
                        .build()
                ).await()
            } finally {
                session.close()
            }
        } catch (error: Exception) {
            Log.w(TAG, "AppSearch clear skipped", error)
        }
    }

    private suspend fun openSession(context: Context): AppSearchSession {
        return LocalStorage.createSearchSessionAsync(
            LocalStorage.SearchContext.Builder(context, DB).build()
        ).await()
    }

    private suspend fun ensureSchema(session: AppSearchSession) {
        val schema = AppSearchSchema.Builder(SCHEMA)
            .addProperty(
                AppSearchSchema.StringPropertyConfig.Builder("name")
                    .setCardinality(AppSearchSchema.PropertyConfig.CARDINALITY_REQUIRED)
                    .setIndexingType(AppSearchSchema.StringPropertyConfig.INDEXING_TYPE_PREFIXES)
                    .setTokenizerType(AppSearchSchema.StringPropertyConfig.TOKENIZER_TYPE_PLAIN)
                    .build()
            )
            .addProperty(
                AppSearchSchema.StringPropertyConfig.Builder("muscleGroup")
                    .setCardinality(AppSearchSchema.PropertyConfig.CARDINALITY_OPTIONAL)
                    .setIndexingType(AppSearchSchema.StringPropertyConfig.INDEXING_TYPE_PREFIXES)
                    .setTokenizerType(AppSearchSchema.StringPropertyConfig.TOKENIZER_TYPE_PLAIN)
                    .build()
            )
            .build()
        session.setSchemaAsync(
            SetSchemaRequest.Builder()
                .addSchemas(schema)
                .setVersion(1)
                .build()
        ).await()
    }
}
