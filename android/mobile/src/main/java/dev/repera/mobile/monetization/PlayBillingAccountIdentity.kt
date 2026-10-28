package dev.repera.mobile.monetization

import java.security.MessageDigest
import java.util.Locale

/** Same SHA-256 UUID binding as the verifier. No email or raw user ID goes to Play. */
object PlayBillingAccountIdentity {
    fun fromUserId(userId: String): String = MessageDigest.getInstance("SHA-256")
        .digest(userId.lowercase(Locale.ROOT).toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it.toInt() and 0xff) }
}
