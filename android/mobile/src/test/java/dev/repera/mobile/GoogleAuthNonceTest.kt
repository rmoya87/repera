package dev.repera.mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GoogleAuthNonceTest {
    @Test
    fun hashedDiffersFromRawAndIsStableSha256Hex() {
        val pair = GoogleAuthNonce.generate()
        assertEquals(64, pair.raw.length)
        assertEquals(64, pair.hashedHex.length)
        assertNotEquals(pair.raw, pair.hashedHex)
        assertEquals(GoogleAuthNonce.sha256Hex(pair.raw), pair.hashedHex)
        assertTrue(pair.hashedHex.matches(Regex("[0-9a-f]{64}")))
    }

    @Test
    fun knownVectorMatchesSha256OfUtf8() {
        // echo -n "abc" | shasum -a 256
        assertEquals(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            GoogleAuthNonce.sha256Hex("abc")
        )
    }
}
