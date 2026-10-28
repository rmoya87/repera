package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class SupabaseAuthErrorsTest {
 @Test fun onlyConfirmedRevocationIsUnrecoverable() {
  assertTrue(SupabaseAuthErrors.isUnrecoverable(AuthHttpException(400,"refresh_token_not_found")))
  assertTrue(SupabaseAuthErrors.isUnrecoverable(AuthHttpException(403,"user_banned")))
  assertTrue(SupabaseAuthErrors.isUnrecoverable(AuthHttpException(400,"session_not_found")))
  assertFalse(SupabaseAuthErrors.isUnrecoverable(AuthHttpException(500,null)))
  assertFalse(SupabaseAuthErrors.isUnrecoverable(AuthHttpException(400,"validation_failed")))
  assertFalse(SupabaseAuthErrors.isUnrecoverable(java.io.IOException("timeout")))
  assertFalse(SupabaseAuthErrors.isUnrecoverable(IllegalStateException("x")))
 }
 @Test fun messageNeverCarriesBodyOrTokens() {
  assertEquals("Supabase Auth HTTP 400: revisa Google Client IDs",AuthHttpException(400,"refresh_token_not_found").message)
 }
}
