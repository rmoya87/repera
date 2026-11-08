package dev.repera.mobile

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

/** Port 1:1 de AIProviderLaunch (AIAccessView.swift iOS): servidor MCP común,
 *  chat nuevo con instrucciones en `q`, preferencia de paquete instalado. */
object AIProviderLaunch {
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
                val root = org.json.JSONObject(response.body?.string() ?: return base to true)
                val arr = root.optJSONArray("providers") ?: return base to true
                val parsed = (0 until arr.length()).map { i ->
                    val p = arr.getJSONObject(i)
                    val setup = p.optJSONObject("setup")
                    val kind = setup?.optString("kind")
                    val clientId = setup?.optString("client_id")
                        ?.takeIf { it.isNotBlank() }
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
        } catch (e: Exception) {
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
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val pkg = packageByProvider[id]
        if (pkg != null && isPackageInstalled(context, pkg)) {
            intent.setPackage(pkg)
            return runCatching { context.startActivity(intent); true }.getOrElse {
                intent.setPackage(null)
                runCatching { context.startActivity(intent); true }.getOrDefault(false)
            }
        }
        return runCatching { context.startActivity(intent); true }.getOrDefault(false)
    }

    private fun isPackageInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    fun instructions(provider: AIAccessStore.AIProvider): String {
        val name = provider.name
        val clientID = provider.oauthClientID?.takeIf {
            provider.id == "claude" || provider.id == "chatgpt"
        }
        val connectorSteps = when {
            provider.id == "claude" && clientID != null -> """
            En Claude, abre https://claude.ai/customize/connectors y añade un conector personalizado Web con:
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Autenticación: OAuth / Iniciar sesión ahora
            Cliente OAuth: Usar tu propio cliente
            ID de cliente OAuth: ${clientID.lowercase()}
            Secreto: vacío (cliente público PKCE).
            """.trimIndent()
            provider.id == "chatgpt" && clientID != null -> """
            En ChatGPT web, abre Configuración → Plugins y crea un servidor MCP personalizado (si está disponible en tu cuenta).
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Autenticación: OAuth (cliente definido por el usuario).
            ID de cliente OAuth público: ${clientID.lowercase()}
            Secreto: vacío si ChatGPT admite el cliente público con PKCE.
            Antes de conectar, comprueba que la URL de retorno exacta que muestra ChatGPT está registrada en Supabase Auth para ese cliente.
            Si no aparece la opción de crear el conector, indica que esta función no está disponible en mi cuenta; no simules una conexión.
            """.trimIndent()
            provider.id == "chatgpt" -> """
            ChatGPT todavía no está habilitado en Repera: falta registrar un cliente OAuth y su URL de retorno exacta en Supabase.
            No basta con pegar la URL del servidor ni con copiar estas instrucciones.
            Si puedes crear un servidor MCP personalizado en ChatGPT web, empieza su configuración para obtener la URL de retorno exacta, que debe registrarse en Supabase Auth.
            Cuando el cliente esté registrado y habilitado en Repera, vuelve a cargar las conexiones de la app para obtener el ID público.
            URL del servidor MCP: $SERVER
            No inventes un ID de cliente ni pidas tokens o contraseñas.
            """.trimIndent()
            provider.id == "grok" -> """
            Comprueba si Grok permite añadir un servidor MCP remoto con autenticación OAuth.
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Si Grok no ofrece conectores MCP en tu cuenta o plan, dímelo claramente; no inventes pasos de Claude o ChatGPT.
            """.trimIndent()
            else -> """
            Comprueba si tu versión de $name permite añadir un servidor MCP remoto con autenticación OAuth.
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Si solicita un ID de cliente, configuración especial o un plan que no tengo, explícamelo sin inventar datos ni dar por realizada la conexión.
            """.trimIndent()
        }
        return """
        Quiero conectar Repera (https://repera.app) solo con $name para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía. No menciones ni configures otros asistentes.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo configurar un conector MCP remoto en $name. No basta con leer la web de Repera ni con recibir este mensaje.
        $connectorSteps

        Debo autorizar el acceso en Repera mediante el flujo oficial de inicio de sesión. No me pidas contraseñas, tokens ni claves privadas en el chat. Si tu aplicación o mi plan no admite conectores MCP remotos, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """.trimIndent()
    }
}
