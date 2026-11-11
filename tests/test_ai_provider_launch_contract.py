"""Contrato: Conecta tu IA — multi-conexión, Editar sheet y Continuar.

- Continuar siempre crea otra conexión (misma IA sin límite artificial).
- Mis conexiones: Editar (sheet) en lugar de Desactivar/Abrir.
- Sheet: nombre + Lectura/Editar/Borrar + Borrar conexión.
"""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
ANDROID_LAUNCH = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIProviderLaunch.kt"
).read_text(encoding="utf-8")
ANDROID_STORE = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessStore.kt"
).read_text(encoding="utf-8")
ANDROID_SCREEN = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt"
).read_text(encoding="utf-8")
ANDROID_MAIN = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
).read_text(encoding="utf-8")
MIGRATION_DELETE = (
    ROOT / "supabase/migrations/20261108210000_ai_access_tokens_owner_delete.sql"
).read_text(encoding="utf-8")
MIGRATION_SCOPE = (
    ROOT / "supabase/migrations/20261111190000_ai_token_delete_scope.sql"
).read_text(encoding="utf-8")
INFO_PLIST = (ROOT / "Apps/Repera/Resources/Info.plist").read_text(encoding="utf-8")
MANIFEST = (
    ROOT / "android/mobile/src/main/AndroidManifest.xml"
).read_text(encoding="utf-8")
TOKENS_EDGE = (
    ROOT / "supabase/functions/repera-ai-tokens/index.ts"
).read_text(encoding="utf-8")
MCP_INDEX = (
    ROOT / "supabase/functions/repera-mcp/index.ts"
).read_text(encoding="utf-8")


class AIProviderLaunchContractTests(unittest.TestCase):
    def test_continue_always_creates_and_never_disconnects_from_provider_row(self):
        section = IOS.split("private var connectionSection", 1)[1].split(
            "private func launch(", 1
        )[0]
        self.assertIn("Continuar con \\(provider.name)", section)
        self.assertNotIn("Configurar ChatGPT", section)
        self.assertNotIn("Configurar ChatGPT", IOS)
        self.assertNotIn("Desactivar", section)
        self.assertIn("launch(provider)", section)
        self.assertNotIn("disconnectingProvider", section)
        # Icono + título centrados (no icono pegado a la izquierda).
        self.assertIn("Spacer(minLength: 0)", section)
        self.assertLess(
            section.index("Spacer(minLength: 0)"),
            section.index('Image("AILogo"'),
        )

        self.assertNotIn("disconnectingProvider", ANDROID_SCREEN)
        self.assertNotIn("DisconnectAssistantDialog", ANDROID_SCREEN)
        self.assertNotIn('"Desactivar"', ANDROID_SCREEN)
        self.assertIn("onContinueProvider(provider)", ANDROID_SCREEN)
        self.assertIn("continueAIProvider", ANDROID_MAIN)

    def test_edit_sheet_replaces_deactivate_and_open(self):
        row = IOS.split("private func connectionRow(_ token: AIAccessTokenInfo)", 1)[1]
        row = row.split("private var canSaveEdit", 1)[0]
        self.assertIn('Text("Editar")', row)
        # Estado (Conectado) y Editar anclados a la derecha, no a media fila.
        self.assertIn("ZStack(alignment: .topTrailing)", row)
        self.assertIn(".multilineTextAlignment(.trailing)", row)
        self.assertIn(".padding(.trailing, 88)", row)
        self.assertNotIn('Text("Desactivar")', row)
        self.assertNotIn('Text("Abrir', row)
        self.assertIn("editingToken = token", row)
        self.assertIn('Section {\n                OGScrollablePageTitle("Conecta tu IA")', IOS.replace("\r\n", "\n"))
        self.assertIn("editConnectionSheet", IOS)
        sheet = IOS.split("private func editConnectionSheet", 1)[1].split(
            "private var manualAccessSheet", 1
        )[0]
        self.assertIn('Toggle("Lectura"', sheet)
        self.assertIn('Toggle("Editar"', sheet)
        self.assertIn('Toggle("Borrar"', sheet)
        self.assertIn('Text("Borrar conexión")', sheet)
        self.assertIn(".ogFittedSheet()", sheet)
        self.assertIn("await updateConnection(token)", sheet)
        self.assertIn("await deleteConnection(target)", sheet)

        self.assertIn('"Editar"', ANDROID_SCREEN)
        self.assertIn("Editar conexión", ANDROID_SCREEN)
        self.assertIn("Borrar conexión", ANDROID_SCREEN)
        self.assertIn("onUpdate(token", ANDROID_SCREEN)
        self.assertIn("fun update(", ANDROID_STORE)
        self.assertIn("updateAIToken", ANDROID_MAIN)
        self.assertIn("training:delete", MIGRATION_SCOPE)
        self.assertIn("canDelete", TOKENS_EDGE)
        self.assertIn("can_delete", MCP_INDEX)
        self.assertIn("training:delete", MCP_INDEX)

        connections = IOS.split("private var connectionsSection", 1)[1]
        connections = connections.split("private var canSaveEdit", 1)[0]
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: false)", connections)
        self.assertIn("await deleteConnection(token)", connections)
        delete_fn = IOS.split(
            "private func deleteConnection(_ token: AIAccessTokenInfo) async", 1
        )[1].split("private enum AccessError", 1)[0]
        self.assertIn("repera-ai-connect/delete", delete_fn)
        self.assertIn("hiddenConnectionIDs.insert", delete_fn)
        self.assertIn("ai_tokens_own_delete", MIGRATION_DELETE)
        self.assertIn("GRANT DELETE ON public.ai_access_tokens", MIGRATION_DELETE)

    def test_continue_opens_new_chat_with_instructions_query(self):
        self.assertIn("static func chatURL(for id: String, prompt: String)", IOS)
        self.assertIn('"https://chatgpt.com/"', IOS)
        self.assertIn('"https://claude.ai/new"', IOS)
        self.assertIn('"https://grok.com/"', IOS)
        self.assertIn('URLQueryItem(name: "q", value: prompt)', IOS)
        self.assertIn("URLComponents(string: base)", IOS)

        launch = IOS.split("private func launch(_ provider: AIConnectionProvider)", 1)[1]
        launch = launch.split("@MainActor\n    private func openProviderChat", 1)[0]
        self.assertIn("launchWithOAuth", launch)
        self.assertIn("launchWithSetupToken", launch)
        self.assertIn("oauthInstructions(for: provider, clientID:", IOS)
        self.assertIn("AIProviderLaunch.instructions(for: provider, setupUrl:", IOS)
        self.assertIn("https://repera.app/ai/", IOS)
        self.assertIn("Usa tu propio cliente OAuth", IOS)
        self.assertIn("AIProviderLaunch.chatURL(for:", IOS)
        self.assertIn("openProviderChat", IOS)
        self.assertIn("AIProviderLaunch.preferredOpenURL", IOS)
        self.assertNotIn("AIProviderLaunch.url(for:", IOS)
        # Grok se mantiene (plugins); ChatGPT/Claude preferen OAuth.
        self.assertIn('"grok"', IOS)
        self.assertIn("fun oauthInstructions(", ANDROID_LAUNCH)
        self.assertIn("clientID", ANDROID_LAUNCH)
        self.assertIn("https://repera.app/ai/", ANDROID_LAUNCH)
        self.assertIn('provider.id != "grok"', ANDROID_MAIN)

    def test_ios_queries_custom_schemes_for_installed_apps(self):
        self.assertIn("LSApplicationQueriesSchemes", INFO_PLIST)
        for scheme in ("chatgpt", "claude", "grok"):
            self.assertIn(f"<string>{scheme}</string>", INFO_PLIST)
        self.assertIn("preferredLaunchURLs", IOS)
        self.assertIn("preferredOpenURL", IOS)
        self.assertIn("canOpenURL", IOS)
        self.assertIn("claude://claude.ai/new", IOS)
        self.assertIn("@MainActor", IOS)

    def test_android_continue_opens_chat_with_prompt_preferring_package(self):
        self.assertIn("fun chatUrlFor(id: String, prompt: String)", ANDROID_LAUNCH)
        self.assertIn("https://chatgpt.com/?q=", ANDROID_LAUNCH)
        self.assertIn("https://claude.ai/new?q=", ANDROID_LAUNCH)
        self.assertIn("https://grok.com/?q=", ANDROID_LAUNCH)
        self.assertIn("fun openProvider(", ANDROID_LAUNCH)
        self.assertIn("com.openai.chatgpt", ANDROID_LAUNCH)
        self.assertIn("com.anthropic.claude", ANDROID_LAUNCH)
        self.assertIn("ai.x.grok", ANDROID_LAUNCH)
        self.assertIn("ReperaSwipeDeleteRow", ANDROID_SCREEN)
        # Mis conexiones = una sola ReperaCard agrupada (esquinas como iOS Form).
        # Sin divisor encima del título (va pegado a Elige tu asistente).
        self.assertNotIn(
            "HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))\n"
            "        Text(\n"
            '            "Mis conexiones"',
            ANDROID_SCREEN,
        )
        self.assertNotIn(
            'HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp))\n'
            '        Text("Mis conexiones"',
            ANDROID_SCREEN,
        )
        connections_android = ANDROID_SCREEN.split('"Mis conexiones"', 1)[1]
        # Card agrupada de tokens (fitted animate al borrar); no la de cambios.
        self.assertIn("animateContentSize()", connections_android)
        self.assertIn("ReperaSwipeDeleteRow(", connections_android)
        self.assertLess(
            connections_android.index("animateContentSize()"),
            connections_android.index("ReperaSwipeDeleteRow("),
        )
        components = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaComponents.kt"
        ).read_text(encoding="utf-8")
        swipe = components.split("fun ReperaSwipeDeleteRow(", 1)[1].split(
            "fun ReperaFullscreenDialog(", 1
        )[0]
        # Borrar detrás de la fila opaca; solo visible al swipe.
        self.assertIn("Surface(color = MaterialTheme.colorScheme.surface)", swipe)
        self.assertIn("backgroundContent", swipe)
        self.assertNotIn(
            "ReperaCard(modifier = Modifier.fillMaxWidth()) {\n"
            "                        Row(",
            connections_android,
        )
        # Estado a la derecha; meta en orden iOS (permisos → último uso → caducidad).
        self.assertIn("Alignment.TopEnd", connections_android)
        self.assertIn("Alignment.BottomEnd", connections_android)
        self.assertNotIn("token.tokenPrefix", connections_android)
        perm_i = connections_android.index("token.permissionSummary")
        last_i = connections_android.index("aiLastUseLabel(token)")
        exp_i = connections_android.index("aiExpiryLabel(token)")
        self.assertLess(perm_i, last_i)
        self.assertLess(last_i, exp_i)
        self.assertIn("onDelete(token)", ANDROID_SCREEN)
        self.assertIn("fun deleteConnection(", ANDROID_STORE)
        self.assertIn(".delete()", ANDROID_STORE)
        self.assertIn("com.openai.chatgpt", MANIFEST)
        self.assertIn("com.anthropic.claude", MANIFEST)
        self.assertIn("ai.x.grok", MANIFEST)

    def test_manual_connection_is_sheet_with_mcp_url_and_name_gate(self):
        self.assertNotIn('DisclosureGroup("Conexión manual"', IOS)
        section = IOS.split("private var connectionSection", 1)[1].split(
            "private func launch(", 1
        )[0]
        self.assertIn('Text("Conexión manual")', section)
        self.assertNotIn(
            "Usa tu asistente habitual para consultar tus entrenamientos",
            section,
        )
        self.assertIn("showManualAccess = true", section)
        self.assertIn("manualAccessSheet", IOS)
        self.assertIn(".sheet(isPresented: $showManualAccess)", IOS)
        sheet = IOS.split("private var manualAccessSheet", 1)[1].split(
            "@MainActor\n    private func refreshProviders", 1
        )[0]
        self.assertIn(".ogFittedHeight()", sheet)
        self.assertIn(".ogFittedSheet()", sheet)
        self.assertIn("OG.surface.opacity(0.55)", sheet)
        self.assertNotIn("OG.bg.ignoresSafeArea()", sheet)
        self.assertNotIn("Para asistentes que requieren", IOS)
        self.assertIn('static let publicServer = "https://repera.app/mcp"', IOS)
        self.assertIn("AIProviderLaunch.publicServer", IOS)
        self.assertIn("count >= 3", IOS)
        self.assertIn("canCreateManualToken", IOS)
        self.assertIn('Toggle("Lectura"', sheet)
        self.assertIn('Toggle("Editar"', sheet)
        self.assertIn('Toggle("Borrar"', sheet)

        self.assertIn("ReperaModalBottomSheet", ANDROID_SCREEN)
        self.assertNotIn(
            "Usa tu asistente habitual para consultar tus entrenamientos",
            ANDROID_SCREEN,
        )
        self.assertNotIn("Para asistentes que requieren", ANDROID_SCREEN)
        self.assertIn('"ai_manual_connection"', ANDROID_SCREEN)
        # Sheet manual/edit/token: alto = contenido (no half-expanded vacío).
        self.assertIn(
            "skipPartiallyExpanded = true",
            ANDROID_SCREEN.split("if (showManual)", 1)[1].split(
                "editingToken?.let", 1
            )[0],
        )
        self.assertIn("PUBLIC_SERVER", ANDROID_LAUNCH)
        self.assertIn('"https://repera.app/mcp"', ANDROID_LAUNCH)
        self.assertIn("AIProviderLaunch.PUBLIC_SERVER", ANDROID_SCREEN)
        self.assertIn("tokenName.trim().length >= 3", ANDROID_SCREEN)
        self.assertIn("ContentCopy", ANDROID_SCREEN)

    def test_android_swipe_delete_removes_row_optimistically(self):
        main = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
        ).read_text(encoding="utf-8")
        delete_fn = main.split("private fun deleteAIToken(", 1)[1].split(
            "private fun decideAIChange(", 1
        )[0]
        self.assertIn("aiHiddenConnectionIds = aiHiddenConnectionIds + token.id", delete_fn)
        self.assertIn("aiTokens = aiTokens?.filter { it.id != token.id }", delete_fn)
        # Antes de await de red: la lista ya no tiene la fila.
        self.assertLess(
            delete_fn.index("aiTokens = aiTokens?.filter { it.id != token.id }"),
            delete_fn.index("deleteConnection(session, token)"),
        )
        self.assertIn(
            "modifier = Modifier.fillMaxWidth().animateContentSize()",
            ANDROID_SCREEN,
        )
        self.assertIn("key(token.id)", ANDROID_SCREEN)


if __name__ == "__main__":
    unittest.main()
