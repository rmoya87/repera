package dev.repera.mobile

/** Port 1:1 de AIProviderLaunch (AIAccessView.swift iOS): servidor MCP común,
 *  apps de cada asistente y el texto de instrucciones copiable. */
object AIProviderLaunch {
    const val SERVER = "https://uvzgujlrqohreoucirms.supabase.co/functions/v1/repera-mcp"

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
                        ?.takeIf { kind == "claude_prompt" || kind == "oauth" }
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

    fun urlFor(id: String): String? = when (id) {
        "chatgpt" -> "https://chatgpt.com/"
        "claude" -> "https://claude.ai/"
        "grok" -> "https://grok.com/"
        else -> null
    }

    fun instructions(provider: AIAccessStore.AIProvider): String {
        val name = provider.name
        val clientID = provider.oauthClientID?.takeIf { provider.id == "claude" }
        val connectorSteps = if (clientID != null) {
            """
            En Claude, abre https://claude.ai/customize/connectors y añade un conector personalizado Web con:
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Autenticación: OAuth / Iniciar sesión ahora
            Cliente OAuth: Usar tu propio cliente
            ID de cliente OAuth: ${clientID.lowercase()}
            Secreto: vacío (cliente público PKCE).
            """.trimIndent()
        } else {
            """
            Comprueba si tu versión de $name permite añadir un servidor MCP remoto con autenticación OAuth.
            Nombre: Repera
            URL del servidor MCP: $SERVER
            Si solicita un ID de cliente, configuración especial o un plan que no tengo, explícamelo sin inventar datos ni dar por realizada la conexión.
            """.trimIndent()
        }
        return """
        Quiero conectar Repera (https://repera.app) con $name para consultar y preparar mis entrenamientos. Ayúdame en español, paso a paso, sin realizar cambios todavía.

        Si tienes disponible la herramienta de Repera get_mcp_access_info, ejecútala únicamente para verificar la conexión, sin leer ni modificar mis entrenamientos. Si responde correctamente, confirma la conexión.

        Si no está conectado, indícame cómo configurar un conector MCP remoto en $name. No basta con leer la web de Repera ni con recibir este mensaje.
        $connectorSteps

        Debo autorizar el acceso en Repera mediante el flujo oficial de inicio de sesión. No me pidas contraseñas, tokens ni claves privadas en el chat. Si tu aplicación o mi plan no admite conectores MCP remotos, dímelo claramente y no confirmes ninguna conexión.

        Comprueba el acceso solo con get_mcp_access_info. No crees, borres ni modifiques entrenamientos sin mi solicitud expresa.
        """.trimIndent()
    }
}
