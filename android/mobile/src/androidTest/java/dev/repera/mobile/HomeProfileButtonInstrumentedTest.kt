package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.*
import org.junit.Assert.*
class HomeProfileButtonInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun missingOrMalformedAvatarStillOpensSettingsWithoutNetwork() {
  var opened=false
  compose.setContent {MaterialTheme {HomeProfileButton(ProfileSettings(avatarJPEG="bad")) {opened=true}}}
  compose.onNodeWithContentDescription("Ajustes y cuenta").performClick()
  compose.runOnIdle {assertTrue(opened)}
 }
}
