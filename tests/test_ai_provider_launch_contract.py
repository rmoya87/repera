"""Contrato: Conecta tu IA — desconectar in-place y abrir chat con instrucciones.

- Desconectar no debe abrir ChatGPT/Claude/Grok.
- Continuar debe abrir un chat nuevo con las instrucciones en la query
  (Universal Links / App Links abren la app si está instalada).
"""
from __future__ import annotations

import re
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
MIGRATION_DELETE = (
    ROOT / "supabase/migrations/20261108210000_ai_access_tokens_owner_delete.sql"
).read_text(encoding="utf-8")
INFO_PLIST = (ROOT / "Apps/Repera/Resources/Info.plist").read_text(encoding="utf-8")
MANIFEST = (
    ROOT / "android/mobile/src/main/AndroidManifest.xml"
).read_text(encoding="utf-8")


class AIProviderLaunchContractTests(unittest.TestCase):
    def test_disconnect_never_opens_provider_url(self):
        revoke = IOS.split("private func revoke(_ token: AIAccessTokenInfo) async", 1)[1]
        revoke = revoke.split("private enum AccessError", 1)[0]
        self.assertNotIn("openURL", revoke)
        self.assertNotIn("AIProviderLaunch", revoke)

        connections = IOS.split("private var connectionsSection", 1)[1]
        connections = connections.split("private var manualAccessFields", 1)[0]
        row = IOS.split("private func connectionRow(_ token: AIAccessTokenInfo)", 1)[1]
        row = row.split("private var manualAccessFields", 1)[0]
        # Misma línea: Desactivar izq., Abrir der. — Text+tap (no Button) para
        # que Form no promocione filas sueltas ni el swipe se coma el pie.
        self.assertIn('Text("Desactivar")', row)
        self.assertIn('Text("Abrir \\(provider.name)")', row)
        self.assertLess(row.index('Text("Desactivar")'), row.index('Text("Abrir'))
        self.assertIn("Spacer(minLength: 8)", row)
        self.assertIn("onTapGesture", row)
        self.assertNotIn('Button("Desactivar"', row)
        # Swipe sin full-swipe (evita borrar «Solo instrucciones» / pie del Form).
        self.assertIn(".swipeActions(edge: .trailing, allowsFullSwipe: false)", connections)
        self.assertIn("await deleteConnection(token)", connections)
        self.assertIn("hiddenConnectionIDs", IOS)
        delete_fn = IOS.split(
            "private func deleteConnection(_ token: AIAccessTokenInfo) async", 1
        )[1].split("private enum AccessError", 1)[0]
        self.assertIn("repera-ai-connect/delete", delete_fn)
        self.assertIn("hiddenConnectionIDs.insert", delete_fn)
        self.assertNotIn("openURL", delete_fn)
        section = IOS.split("private var connectionSection", 1)[1].split(
            "private func connectionVerified", 1
        )[0]
        self.assertNotIn("Solo instrucciones", section)
        self.assertNotIn("La conexión se configura dentro de cada asistente", section)

        dialog = IOS.split('.confirmationDialog("Desactivar asistente"', 1)[1]
        dialog = dialog.split(".sheet(isPresented:", 1)[0]
        self.assertIn("await revoke(token)", dialog)
        self.assertNotIn("openURL", dialog)
        self.assertNotIn("launch(", dialog)

    def test_continue_opens_new_chat_with_instructions_query(self):
        self.assertIn("static func chatURL(for id: String, prompt: String)", IOS)
        self.assertIn('"https://chatgpt.com/"', IOS)
        self.assertIn('"https://claude.ai/new"', IOS)
        self.assertIn('"https://grok.com/"', IOS)
        self.assertIn('URLQueryItem(name: "q", value: prompt)', IOS)
        self.assertIn("URLComponents(string: base)", IOS)

        launch = IOS.split("private func launch(_ provider: AIConnectionProvider)", 1)[1]
        launch = launch.split("private var connectionsSection", 1)[0]
        self.assertIn("AIProviderLaunch.instructions(for: provider)", launch)
        self.assertIn("AIProviderLaunch.chatURL(for:", launch)
        self.assertIn("openProviderChat", launch)
        self.assertIn("AIProviderLaunch.preferredOpenURL", IOS)
        self.assertNotIn("AIProviderLaunch.url(for:", launch)

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

        # Continuar debe lanzar el chat; el sheet solo si falla la apertura.
        continue_click = ANDROID_SCREEN.split("if (verified) disconnectingProvider = provider", 1)[1]
        continue_click = continue_click.split("enabled = connected,", 1)[0]
        self.assertIn("AIProviderLaunch.openProvider", continue_click)
        self.assertLess(
            continue_click.index("AIProviderLaunch.openProvider"),
            continue_click.index("instructionsFor = provider"),
        )

        disconnect_dialog = ANDROID_SCREEN.split("DisconnectAssistantDialog(", 1)[1]
        disconnect_dialog = disconnect_dialog.split("instructionsFor?", 1)[0]
        self.assertIn("onRevoke(token.id)", disconnect_dialog)
        self.assertNotIn("startActivity", disconnect_dialog)
        self.assertNotIn("openProvider", disconnect_dialog)

        self.assertIn("ReperaSwipeDeleteRow", ANDROID_SCREEN)
        self.assertIn("onDelete(token)", ANDROID_SCREEN)
        self.assertIn('"Desactivar"', ANDROID_SCREEN)
        row_actions = ANDROID_SCREEN.split("if (token.isActive)", 1)[1].split(
            "changes.isNotEmpty()", 1
        )[0]
        self.assertLess(row_actions.index('"Desactivar"'), row_actions.index('"Abrir "'))
        self.assertIn("fun deleteConnection(", ANDROID_STORE)
        self.assertIn(".delete()", ANDROID_STORE)
        self.assertIn("ai_tokens_own_delete", MIGRATION_DELETE)
        self.assertIn("GRANT DELETE ON public.ai_access_tokens", MIGRATION_DELETE)

        self.assertIn("com.openai.chatgpt", MANIFEST)
        self.assertIn("com.anthropic.claude", MANIFEST)
        self.assertIn("ai.x.grok", MANIFEST)


if __name__ == "__main__":
    unittest.main()
