package dev.repera.mobile.render

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.performScrollToNode
import dev.repera.mobile.AIAccessScreen
import dev.repera.mobile.AIAccessStore
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.io.FileOutputStream

/**
 * Render headless inspeccionable de AIAccessScreen (NO validacion de
 * dispositivo): fixtures de tokens (OAuth conectado, manual activo, revocado)
 * y captura revisable en build/reports/render/.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class AIAccessRenderTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun aiAccessScreenRendersConnectionsAndTokens() {
        val tokens = listOf(
            // Conexion OAuth usada (chatgpt): Conectado, sin caducidad, Abrir
            AIAccessStore.TokenInfo(
                id = "t1", label = "ChatGPT", tokenPrefix = "rpa_abc",
                createdAt = "2026-10-01T10:00:00Z", expiresAt = null,
                revokedAt = null, lastUsedAt = "2026-10-26T18:30:00Z",
                scopes = listOf("training:read"), oauthClientID = "chatgpt-mcp"),
            // Token manual activo sin usar: Pendiente de conexion, con caducidad
            AIAccessStore.TokenInfo(
                id = "t2", label = "Mi entrenador IA", tokenPrefix = "rpa_xyz",
                createdAt = "2026-10-20T10:00:00Z", expiresAt = "2027-10-20T10:00:00Z",
                revokedAt = null, lastUsedAt = null,
                scopes = listOf("training:read", "training:write")),
            // Revocado: Desconectado
            AIAccessStore.TokenInfo(
                id = "t3", label = "Claude", tokenPrefix = "rpa_old",
                createdAt = "2026-09-01T10:00:00Z", expiresAt = null,
                revokedAt = "2026-10-15T10:00:00Z", lastUsedAt = "2026-10-10T10:00:00Z",
                scopes = listOf("training:read"), oauthClientID = "claude-mcp"))
        composeRule.setContent {
            MaterialTheme {
                Surface(modifier = Modifier.testTag("airoot")) {
                    AIAccessScreen(
                        connected = true, busy = false,
                        tokens = tokens, errorMessage = null,
                        successMessage = null, createdToken = null,
                        changes = emptyList(), changeBusy = false,
                        changeError = null, inboxPending = 0,
                        inboxConflicts = emptyList(),
                        onRefresh = {}, onCreate = { _, _, _ -> },
                        onRevoke = {}, onDecide = { _, _ -> },
                        onDismissCreated = {}, onCopyCreated = {})
                }
            }
        }
        // El catalogo de proveedores carga en LaunchedEffect (red real o
        // fallback offline): esperar a que los botones existan antes de capturar.
        composeRule.waitUntil(timeoutMillis = 15000) {
            runCatching {
                composeRule.onAllNodes(
                    androidx.compose.ui.test.hasText("Continuar con", substring = true)
                ).fetchSemanticsNodes().isNotEmpty()
            }.getOrDefault(false)
        }
        val bitmap = composeRule.onNodeWithTag("airoot").captureToImage().asAndroidBitmap()
        val dir = File("build/reports/render").apply { mkdirs() }
        val out = File(dir, "ai_access_screen.png")
        FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        // Pantalla no vacia
        val px = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(px, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        assert(px.any { it != 0 }) { "AIAccessScreen renderizo vacia" }
        // Estados de token 1:1 Apple
        composeRule.onNodeWithTag("airoot").assertIsDisplayed()
        assert(tokens[0].hasConnected) { "fixture oauth debe ser hasConnected" }
        assert(!tokens[1].hasConnected && tokens[1].isActive) { "fixture manual pendiente" }
        assert(!tokens[2].isActive) { "fixture revocado inactivo" }
        // Seccion de tokens bajo el fold: scroll y segunda captura.
        composeRule.onNodeWithTag("airoot")
            .performScrollToNode(androidx.compose.ui.test.hasText("Mi entrenador IA"))
        val bitmap2 = composeRule.onNodeWithTag("airoot").captureToImage().asAndroidBitmap()
        val out2 = File(dir, "ai_access_tokens.png")
        FileOutputStream(out2).use { bitmap2.compress(Bitmap.CompressFormat.PNG, 100, it) }
        // Tarjeta revocada (Claude, "Desconectado") bajo el fold.
        composeRule.onNodeWithTag("airoot")
            .performScrollToNode(androidx.compose.ui.test.hasText("Desconectado"))
        val bitmap3 = composeRule.onNodeWithTag("airoot").captureToImage().asAndroidBitmap()
        val out3 = File(dir, "ai_access_revoked.png")
        FileOutputStream(out3).use { bitmap3.compress(Bitmap.CompressFormat.PNG, 100, it) }
        println("RENDERED_AIACCESS=" + out.absolutePath)
        println("RENDERED_AITOKENS=" + out2.absolutePath)
        println("RENDERED_AIREVOKED=" + out3.absolutePath)
    }

    @Test
    fun disconnectDialogRenders() {
        composeRule.setContent {
            MaterialTheme {
                Surface {
                    dev.repera.mobile.DisconnectAssistantDialog(
                        providerName = "ChatGPT", onConfirm = {}, onDismiss = {})
                }
            }
        }
        val bitmap = composeRule.onRoot().captureToImage().asAndroidBitmap()
        val dir = File("build/reports/render").apply { mkdirs() }
        val out = File(dir, "ai_disconnect_dialog.png")
        FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        composeRule.onNodeWithText("Desconectar asistente").assertIsDisplayed()
        composeRule.onNodeWithText(
            "Se revocará el acceso del asistente a tu cuenta de Repera.").assertIsDisplayed()
        composeRule.onNodeWithText("Desconectar ChatGPT").assertIsDisplayed()
        composeRule.onNodeWithText("Cancelar").assertIsDisplayed()
        println("RENDERED_AIDIALOG=" + out.absolutePath)
    }
}
