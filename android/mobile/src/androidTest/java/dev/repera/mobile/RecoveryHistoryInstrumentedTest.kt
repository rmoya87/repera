package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.*
import dev.repera.domain.*
class RecoveryHistoryInstrumentedTest {
 @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
 @Test fun historicalSleepStagesAndRmssdAreExplicitWithoutClaimingSdnn() {
  val today=java.time.LocalDate.now()
  val recovery=RecoveryState(null,80,8.0,7.5,
   listOf(RecoverySleepNight(today,8.0,1.5,2.0),RecoverySleepNight(today.minusDays(1),7.0,1.0,1.5)),
   listOf(RecoveryEngine.DailyVitals(today,hrvMilliseconds=45.0,restingHeartRateBpm=55.0)))
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Column(Modifier.fillMaxSize().safeDrawingPadding().verticalScroll(rememberScrollState())) {
   RecoveryHistoryCards(recovery,ProgressTimeRange.WEEK,true)
  }}}
  compose.onAllNodesWithText("Profundo:",substring=true)[0].performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("VFC (RMSSD)").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("RMSSD de Health Connect no equivale a SDNN de Apple Salud.").performScrollTo().assertIsDisplayed()
 }
 @Test fun cycleShowsOnlyObservedDatesPositiveTestsAndCautiousEstimate() {
  val today=java.time.LocalDate.now()
  val recovery=RecoveryState(null,null,null,null,menstrualDays=listOf(today),positiveOvulationTests=listOf(today.minusDays(1)))
  compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Column(Modifier.fillMaxSize().safeDrawingPadding().verticalScroll(rememberScrollState())) {RecoveryHistoryCards(recovery,ProgressTimeRange.WEEK,true)}}}
  compose.onNodeWithText("Menstruación registrada").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("Calendario de las últimas seis semanas").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("Pruebas de ovulación positivas registradas: 1").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("Fase aproximada solo si hay suficientes ciclos compatibles.",substring=true).performScrollTo().assertIsDisplayed()
 }
 @Test fun freeConstantsPreviewNeverShowsPrivatePhysiology() {
  val recovery=RecoveryState(null,null,null,null,vitals=listOf(RecoveryEngine.DailyVitals(java.time.LocalDate.now(),hrvMilliseconds=123.0)))
  compose.setContent {MaterialTheme {Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {RecoveryHistoryCards(recovery,ProgressTimeRange.WEEK,true,pro=false)}}}
  compose.onNodeWithText("Constantes · Ejemplo ficticio").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("No son tus datos de Salud").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("Pulso en reposo").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("58 lpm").assertIsDisplayed()
  compose.onNodeWithText("Respiración").assertIsDisplayed()
  compose.onNodeWithText("13 rpm").assertIsDisplayed()
  compose.onAllNodesWithText("123",substring=true).assertCountEquals(0)
 }
 @Test fun noCycleCardWithoutObservedMenstrualDays() {
  compose.setContent {MaterialTheme {Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
   RecoveryHistoryCards(RecoveryState(null,null,null,null),ProgressTimeRange.WEEK,true,pro=false)
  }}}
  compose.onAllNodesWithText("Ciclo menstrual").assertCountEquals(0)
 }
 @Test fun currentPreparationShowsObservedFactorsWithoutGrantingHistoricalProCharts() {
  val today=java.time.LocalDate.now()
  val ready=RecoveryEngine.TrainingReadiness(8.4,RecoveryEngine.TrainingReadinessAdvice.USUAL,8.0,1.2,2,cardioMinutes48h=31.0)
  val recovery=RecoveryState(ready,80,8.0,7.5,vitals=listOf(RecoveryEngine.DailyVitals(today,hrvMilliseconds=48.0,restingHeartRateBpm=55.0)))
  compose.setContent {MaterialTheme {Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {TrainingReadinessCard(recovery)}}}
  compose.onNodeWithContentDescription("Preparación 8 de 10").assertExists()
  compose.onNodeWithText("Carga reciente").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("Moderada").assertIsDisplayed()
  compose.onNodeWithText("48 ms RMSSD · 55 lpm").performScrollTo().assertIsDisplayed()
  compose.onNodeWithText("31 min").assertIsDisplayed()
 }
}
