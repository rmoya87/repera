package dev.repera.mobile
import org.junit.Test
import org.junit.Assert.*
import org.json.JSONObject
class ProfileSettingsTest {
    @Test fun localOverrideTrimsNamePreservesOtherSettingsAndCanClear() {
        val state=JSONObject().put("settings",JSONObject().put("weightUnit","lb").put("future",true))
        assertEquals(ProfileSettings(),ProfileSettings.read(state))
        ProfileSettings.apply(state,ProfileSettings("  Ramón  ","/9j/test"))
        assertEquals(ProfileSettings("Ramón","/9j/test"),ProfileSettings.read(state))
        assertEquals("lb",state.getJSONObject("settings").getString("weightUnit"))
        assertTrue(state.getJSONObject("settings").getBoolean("future"))
        ProfileSettings.apply(state,ProfileSettings(" ",null))
        assertEquals(ProfileSettings(),ProfileSettings.read(state))
    }
    @Test fun invalidAvatarDoesNotPartiallyOverwriteSnapshot() {
        val state=JSONObject().put("settings",JSONObject().put("profileDisplayName","Antes"))
        val before=state.toString()
        try {ProfileSettings.apply(state,ProfileSettings("Nuevo","x".repeat(300_001)));fail()} catch(_:IllegalArgumentException) {}
        assertEquals(before,state.toString())
    }
    @Test fun longNameIsStoredLocallyAndOnlyPublicSyncTruncates() {
        val state=JSONObject()
        ProfileSettings.apply(state,ProfileSettings("x".repeat(101)))
        assertEquals("x".repeat(101),ProfileSettings.read(state).displayName)
    }
}
