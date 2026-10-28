package dev.repera.mobile

import java.security.MessageDigest
import java.security.SecureRandom

/**
 * Nonce binding for Google ID token → Supabase Auth (parity with iOS
 * BusinessAuthStore): Credential Manager / Google Sign-In receive the
 * SHA-256 hex digest; Supabase receives the raw nonce and re-hashes it.
 * Passing the same string to both ends causes Auth HTTP 400 (nonce mismatch),
 * often surfaced as the generic "revisa Google Client IDs" message.
 */
internal object GoogleAuthNonce {
    data class Pair(val raw: String, val hashedHex: String)

    fun generate(random: SecureRandom = SecureRandom()): Pair {
        val rawBytes = ByteArray(32).also { random.nextBytes(it) }
        val raw = rawBytes.joinToString("") { "%02x".format(it) }
        return Pair(raw, sha256Hex(raw))
    }

    fun sha256Hex(raw: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(raw.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }
}
