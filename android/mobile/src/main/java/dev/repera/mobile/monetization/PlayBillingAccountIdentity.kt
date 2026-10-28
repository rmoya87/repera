package dev.repera.mobile.monetization

import java.security.MessageDigest
import java.util.Locale

/**
 * SHA-256 of the lowercase Supabase user id for Play `obfuscatedAccountId`
 * (Console correlation only). Pro restore after delete+recreate does **not**
 * require this hash to match the new UUID — see verify/claim Apple parity.
 * No email or raw user ID goes to Play.
 */
object PlayBillingAccountIdentity {
    fun fromUserId(userId: String): String = MessageDigest.getInstance("SHA-256")
        .digest(userId.lowercase(Locale.ROOT).toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it.toInt() and 0xff) }
}
