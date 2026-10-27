package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
class ManualMirrorSyncTextTest {
 @Test fun footerPrefersErrorThenLastSyncThenIdleText() {
  assertEquals(ManualMirrorSyncText.IDLE,ManualMirrorSyncText.footer(ManualMirrorSyncState()))
  assertEquals("Última sincronización con Supabase: 26 oct · 4 registros remotos",
   ManualMirrorSyncText.footer(ManualMirrorSyncState(lastSyncAtText="26 oct",mirroredCount=4)))
  assertEquals("fallo",ManualMirrorSyncText.footer(ManualMirrorSyncState(lastSyncAtText="x",error="fallo")))
 }
}
