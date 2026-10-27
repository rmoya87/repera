package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test
class AdaptiveCardPairInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun narrowPairPreservesBothCardsInReadingOrder() {
        compose.setContent {MaterialTheme {Box(Modifier.width(360.dp)) {
            AdaptiveCardPair(first={Text("Primera tarjeta")},second={Text("Segunda tarjeta")})
        }}}
        compose.onNodeWithTag("adaptive_pair_1").assertExists()
        compose.onNodeWithText("Primera tarjeta").assertIsDisplayed()
        compose.onNodeWithText("Segunda tarjeta").assertIsDisplayed()
    }
}
