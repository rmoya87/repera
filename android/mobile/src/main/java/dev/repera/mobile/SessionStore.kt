package dev.repera.mobile

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Durable Supabase session, encrypted with an Android Keystore key.
 *
 * The refresh token and access token never leave the device unencrypted:
 * the AES-GCM key lives in hardware-backed AndroidKeyStore when the device
 * supports it, and the preference file itself stays in the app sandbox.
 * No tokens are written to logs or error messages.
 */
internal class SessionStore(context: Context) {

    data class StoredSession(
        val uniqueId: String,
        val email: String,
        val displayName: String,
        val userId: String,
        val accessToken: String,
        val refreshToken: String,
        val expiresAtEpochSeconds: Long
    ) {
        fun expiresWithin(seconds: Long, nowEpochSeconds: Long = System.currentTimeMillis() / 1000): Boolean =
            expiresAtEpochSeconds - nowEpochSeconds <= seconds
    }

    private val preferences = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun load(): StoredSession? {
        val packed = preferences.getString(KEY_BLOB, null) ?: return null
        return runCatching {
            val plain = decrypt(Base64.decode(packed, Base64.NO_WRAP))
            val json = JSONObject(String(plain, Charsets.UTF_8))
            StoredSession(
                uniqueId = json.getString("uniqueId"),
                email = json.optString("email"),
                displayName = json.optString("displayName").ifBlank { "Deportista" },
                userId = json.getString("userId"),
                accessToken = json.getString("accessToken"),
                refreshToken = json.getString("refreshToken"),
                expiresAtEpochSeconds = json.getLong("expiresAt")
            )
        }.getOrNull()
    }

    fun save(session: StoredSession) {
        val json = JSONObject()
            .put("uniqueId", session.uniqueId)
            .put("email", session.email)
            .put("displayName", session.displayName)
            .put("userId", session.userId)
            .put("accessToken", session.accessToken)
            .put("refreshToken", session.refreshToken)
            .put("expiresAt", session.expiresAtEpochSeconds)
        val packed = Base64.encodeToString(encrypt(json.toString().toByteArray(Charsets.UTF_8)), Base64.NO_WRAP)
        preferences.edit().putString(KEY_BLOB, packed).apply()
    }

    fun clear() {
        preferences.edit().remove(KEY_BLOB).apply()
    }

    private fun encrypt(data: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(data)
        return cipher.iv + encrypted
    }

    private fun decrypt(data: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(GCM_TAG_BITS, data, 0, GCM_IV_BYTES)
        cipher.init(Cipher.DECRYPT_MODE, key(), spec)
        return cipher.doFinal(data, GCM_IV_BYTES, data.size - GCM_IV_BYTES)
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (store.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }

    companion object {
        private const val PREFS = "repera_session"
        private const val KEY_BLOB = "session_blob"
        private const val KEY_ALIAS = "repera_session_key"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_IV_BYTES = 12
        private const val GCM_TAG_BITS = 128
    }
}
