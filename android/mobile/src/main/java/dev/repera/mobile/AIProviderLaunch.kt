package dev.repera.mobile

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

/** Port 1:1 de AIProviderLaunch (AIAccessView.swift iOS): servidor MCP común,
 *  chat nuevo con instrucciones en `q`, preferencia de paquete instalado. */
object AIProviderLaunch {
    /** URL pública para pegar en asistentes (proxy canónico en repera.app). */
    const val PUBLIC_SERVER = "https://repera.app/mcp"
    /** Endpoint Edge real (OAuth / discovery / Bearer). */
    const val SERVER = "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp"

    private val packageByProvider = mapOf(
        "chatgpt" to "com.openai.chatgpt",
        "claude" to "com.anthropic.claude",
        "grok" to "ai.x.grok"
    )

    /** Catálogo público de conexiones guiadas (port de refreshProviders iOS:
     *  GET sin auth a repera-ai-connect/catalog; valida chatgpt+claude,
     *  añade Grok y ordena chatgpt/claude/grok; ante cualquier fallo, los
     *  tres proveedores base sin OAuth y flag de error). Llamar fuera del
     *  hilo principal. */
    fun fetchProviderCatalog(): Pair<List<AIAccessStore.AIProvider>, Boolean> {
        val base = listOf(
            AIAccessStore.AIProvider("chatgpt", "ChatGPT", null, null),
            AIAccessStore.AIProvider("claude", "Claude", null, null),
            AIAccessStore.AIProvider("grok", "Grok", null, null)
        )
        return try {
            val request = okhttp3.Request.Builder()
                .url(BuildConfig.SUPABASE_URL + "/functions/v1/repera-ai-connect/catalog")
                .get().build()
            okhttp3.OkHttpClient().newCall(request).execute().use { response ->
                if (response.code != 200) return base to true
                val root = org.json.JSONObject(response.body.string())
                val arr = root.optJSONArray("providers") ?: return base to true
                val parsed = (0 until arr.length()).map { i ->
                    val p = arr.getJSONObject(i)
                    val setup = p.optJSONObject("setup")
                    val kind = setup?.optString("kind")
                    // Catálogo publica camelCase `clientID` (paridad iOS / ai-oauth.ts).
                    val clientId = listOf("clientID", "client_id")
                        .mapNotNull { key -> setup?.optString(key)?.takeIf { it.isNotBlank() } }
                        .firstOrNull()
                        ?.takeIf {
                            kind == "claude_prompt" || kind == "chatgpt_prompt" ||
                                kind == "oauth"
                        }
                    AIAccessStore.AIProvider(
                        id = p.optString("id"),
                        name = p.optString("name"),
                        oauthClientID = clientId,
                        directoryURL = p.optString("directory_url")
                            .takeIf { it.isNotBlank() }
                    )
                }
                // Misma guardia que iOS: el catálogo debe ser exactamente chatgpt+claude.
                if (parsed.size != 2 ||
                    parsed.map { it.id }.toSet() != setOf("chatgpt", "claude")) {
                    return base to true
                }
                val order = listOf("chatgpt", "claude", "grok")
                (parsed + AIAccessStore.AIProvider("grok", "Grok", null, null))
                    .sortedBy { order.indexOf(it.id) } to false
            }
        } catch (_: Exception) {
            base to true
        }
    }

    fun chatUrlFor(id: String, prompt: String): String? {
        val encoded = Uri.encode(prompt) ?: return null
        return when (id) {
            "chatgpt" -> "https://chatgpt.com/?q=$encoded"
            "claude" -> "https://claude.ai/new?q=$encoded"
            "grok" -> "https://grok.com/?q=$encoded"
            else -> null
        }
    }

    fun openProvider(context: Context, id: String, prompt: String): Boolean {
        val url = chatUrlFor(id, prompt) ?: return false
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val pkg = packageByProvider[id]
        if (pkg != null && isPackageInstalled(context, pkg)) {
            intent.setPackage(pkg)
        }
        return try {
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            if (pkg != null) {
                intent.setPackage(null)
                try {
                    context.startActivity(intent)
                    true
                } catch (_: Exception) {
                    false
                }
            } else false
        }
    }

    private fun isPackageInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /** ChatGPT / Claude: OAuth → consentimiento en https://repera.app/ai/. */
    fun oauthInstructions(provider: AIAccessStore.AIProvider, clientID: String): String {
        val name = provider.name
        val mcp = PUBLIC_SERVER
        val id = clientID.lowercase()
        return """
        Quiero conectar Repera (https://repera.app) solo con $name para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía. No menciones ni configures otros asistentes.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo añadir un conector MCP remoto en $name con:
        Nombre: Repera
        URL del servidor MCP: $mcp
        Autenticación: OAuth
        Usa tu propio cliente OAuth (no registro automático / CIMD).
        Client ID: $id
        Client secret: (vacío)
        La autorización debe abrir https://repera.app/ai/ para que yo inicie sesión en Repera y apruebe el acceso. No me pidas tokens en el chat.

        Si tu plan o interfaz no admite OAuth con cliente propio para MCP, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """.trimIndent()
    }

    /** Grok / Conexión manual: Bearer + enlace de setup en /ai (pide login). */
    fun instructions(provider: AIAccessStore.AIProvider, setupUrl: String): String {
        val name = provider.name
        val mcp = PUBLIC_SERVER
        return """
        Quiero conectar Repera (https://repera.app) solo con $name para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía. No menciones ni configures otros asistentes.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo añadir un conector MCP remoto o plugin en $name con:
        Nombre: Repera
        URL del servidor MCP: $mcp
        Autenticación: token Bearer / API key en el header Authorization.

        El token de un solo uso lo obtengo yo abriendo este enlace (pide autenticación en Repera; válido 15 minutos; no lo pegues en el chat):
        $setupUrl
        Indícame dónde configurar el token en $name; no me pidas que lo escriba aquí.

        Si tu aplicación o mi plan no admite conectores MCP / plugins con Bearer, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """.trimIndent()
    }

    fun reopenInstructions(provider: AIAccessStore.AIProvider): String {
        val name = provider.name
        return """
        Ya tengo Repera conectado o pendiente con $name. Ayúdame en español a comprobar la conexión.
        Servidor MCP: $PUBLIC_SERVER
        Si tienes get_mcp_access_info, ejecútala solo para verificar, sin leer ni modificar entrenamientos.
        Si hace falta reconfigurar el conector, dime los pasos en $name sin pedirme tokens en el chat; generaré un enlace de setup nuevo desde la app Repera.
        """.trimIndent()
    }
}
