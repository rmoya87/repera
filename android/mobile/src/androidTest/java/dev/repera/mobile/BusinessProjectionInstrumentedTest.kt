package dev.repera.mobile
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.platform.app.InstrumentationRegistry
import org.json.*
import org.junit.*
import org.junit.Assert.*

/** Synthetic read/send callback fixtures only. No network, real messages or account. */
class BusinessProjectionInstrumentedTest {
    @get:Rule val compose=createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Test fun professionalPlanProjectsWithoutMutatingPrivateSnapshot() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val id="professional-${java.util.UUID.randomUUID()}";val local=LocalSnapshotStore(ctx,id)
        local.write(JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray()).toString().toByteArray())
        val before=local.read()!!
        val payload=JSONObject().put("schemaVersion",1).put("blocks",JSONArray().put(JSONObject().put("id","b").put("title","Fuerza prescrita").put("kind","strength")
            .put("exercises",JSONArray().put(JSONObject().put("id","e").put("name","Sentadilla").put("source","catalog")
                .put("plannedSets",JSONArray().put(JSONObject().put("targetReps",5).put("targetWeightKg",80).put("targetRir",2)))))))
        val session=BusinessCenterStore.ProfessionalSession("p","org","client","coach","2026-10-25","Plan entrenador","Técnica controlada","scheduled",payload)
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize()) {Column(Modifier.padding(16.dp)) {ProfessionalSessionCard(session,"Centro sintético",false)}}}}
        compose.onNodeWithText("Fuerza prescrita").assertIsDisplayed()
        compose.onNodeWithText("Sentadilla").assertIsDisplayed()
        compose.onNodeWithText("5 rep · 80 kg · RIR 2").assertIsDisplayed()
        assertArrayEquals(before,local.read())
        capture("profesional_solo_lectura")
    }
    @Test fun messagesSelectLinkedRecipientAndOnlyExplicitSendCallsCallback() {
        var sent:Triple<String,String,String>?=null
        val snapshot=BusinessCenterStore.Snapshot(centers=listOf(
            BusinessCenterStore.Organization("org","Centro sintético","gym",null,null,null)),athleteCenterIds=setOf("org"),
            notices=listOf(BusinessCenterStore.Notice("m","org","c","Aviso sintético","Hola","2026-10-25T20:00:00Z")))
        compose.setContent {MaterialTheme(colorScheme=reperaColorScheme(false)) {Surface(Modifier.fillMaxSize()) {CenterMessagesScreen(true,false,false,null,snapshot,{}, {org,title,body -> sent=Triple(org,title,body)})}}}
        compose.onNodeWithText("Aviso sintético").assertIsDisplayed()
        capture("mensajes_bandeja")
        compose.onNodeWithText("Escribir mensaje").performClick()
        compose.onNodeWithText("Enviar").assertIsNotEnabled()
        compose.onNodeWithText("Asunto").performTextInput("Consulta")
        compose.onNodeWithText("Mensaje").performTextInput("Prueba local")
        capture("mensajes_borrador")
        assertNull(sent)
        compose.onNodeWithText("Enviar").performClick()
        assertEquals(Triple("org","Consulta","Prueba local"),sent)
    }
    private fun capture(name:String) {
        compose.waitForIdle()
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val bitmap=InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()!!
        val values=android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
        }
        val uri=ctx.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
        ctx.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it)}
    }
}
