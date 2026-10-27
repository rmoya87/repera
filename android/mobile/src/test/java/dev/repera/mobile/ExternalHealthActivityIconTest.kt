package dev.repera.mobile
import dev.repera.domain.LiveSport
import org.junit.Assert.assertEquals
import org.junit.Test
class ExternalHealthActivityIconTest {
 @Test fun addedHealthFamiliesHaveSpecificIcons() {
  mapOf("surfingSports" to LiveSport.SURFING,"paddleSports" to LiveSport.KAYAKING,
   "sailing" to LiveSport.SAILING,"waterSports" to LiveSport.SWIMMING,
   "downhillSkiing" to LiveSport.SKIING,"crossCountrySkiing" to LiveSport.CROSS_COUNTRY_SKIING,
   "snowboarding" to LiveSport.SNOWBOARDING,"skatingSports" to LiveSport.ICE_SKATING,
   "volleyball" to LiveSport.VOLLEYBALL,"climbing" to LiveSport.CLIMBING).forEach {(key,sport) ->
    assertEquals(key,sport,externalHealthSport(key))
   }
 }
 @Test fun unknownAndLegacyRemainGenericWithoutTitleInference() {
  assertEquals(LiveSport.OTHER,externalHealthSport(""))
  assertEquals(LiveSport.OTHER,externalHealthSport("unknown"))
  assertEquals("other",ExternalHealthHistoryEntry("id","Surfing",0L,1L,1.0,"pkg").exerciseTypeKey)
 }
}
