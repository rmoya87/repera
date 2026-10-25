package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*
import dev.repera.mobile.monetization.*

class FreeMuscleAccessInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun actualFreeManagerShowsMuscleCardButStillRejectsMonthRange() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val free=SubscriptionManager(freeUsage=FreeUsageStore(java.io.File(context.cacheDir,"free-muscle-test.json")))
        assertFalse(free.isPro)
        assertFalse(free.canSelectProgressRange(dev.repera.domain.ProgressTimeRange.MONTH).allowed)
        val ex=JSONObject().put("id","bench").put("name","Press banca").put("muscleGroup","Pecho").put("targetMuscle","chest")
        val item=JSONObject().put("id","entry").put("exercise",ex).put("blockKind","strength").put("isCompleted",true)
            .put("loggedSets",JSONArray().put(JSONObject().put("id","set").put("reps",5).put("weightKg",60).put("rir",2).put("phase","work")))
        val start=java.time.LocalDate.now().atTime(9,0).atZone(java.time.ZoneId.systemDefault()).toInstant()
        val state=JSONObject().put("exercises",JSONArray().put(ex)).put("routines",JSONArray()).put("workouts",JSONArray().put(
            JSONObject().put("id","session").put("title","Banca").put("phase","finished").put("startedAt",start.toString())
                .put("finishedAt",start.plusSeconds(3600).toString()).put("exercises",JSONArray().put(item))))
        val overview=StateOverview.fromBytes(state.toString().toByteArray())!!
        compose.setContent {CompositionLocalProvider(LocalSubscriptions provides free) {
            MaterialTheme(colorScheme=reperaColorScheme(false)) {
                ProgressTab(false,false,null,overview,{},{},{},{},{},{_,_,_,_,_,_->},{_,_,_->})
            }
        }}
        compose.onNodeWithTag("progress_list").performScrollToNode(hasText("Equilibrio muscular"))
        compose.onNodeWithText("Equilibrio muscular").assertIsDisplayed()
        compose.onNodeWithText("Conoce tu equilibrio muscular").assertDoesNotExist()
    }
}
