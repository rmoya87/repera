package dev.repera.mobile

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertThrows
import org.junit.Test

class AccountDeletionClientTest {
    @Test
    fun blankTokenFailsFast() {
        assertThrows(AccountDeletionClient.AccountDeletionException::class.java) {
            runBlocking { AccountDeletionClient().request("preflight", "  ") }
        }
    }

    @Test
    fun invalidActionRejectedByRequire() {
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking { AccountDeletionClient().request("wipe", "token") }
        }
    }
}
