"""Contrato: código de setup IA 15 min + MCP público + canje en /ai/?code=."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOKENS = (ROOT / "supabase/functions/repera-ai-tokens/index.ts").read_text(encoding="utf-8")
CONNECT = (ROOT / "supabase/functions/repera-ai-connect/index.ts").read_text(encoding="utf-8")
MIGRATION = (
    ROOT / "supabase/migrations/20261111180000_ai_setup_code.sql"
).read_text(encoding="utf-8")
WEB_JS = (ROOT / "web/ai/connect.js").read_text(encoding="utf-8")
WEB_HTML = (ROOT / "web/ai/index.html").read_text(encoding="utf-8")
IOS = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
ANDROID_LAUNCH = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIProviderLaunch.kt"
).read_text(encoding="utf-8")
ANDROID_SCREEN = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt"
).read_text(encoding="utf-8")
ANDROID_MAIN = (
    ROOT / "android/mobile/src/main/java/dev/repera/mobile/MainActivity.kt"
).read_text(encoding="utf-8")


class AISetupCodeContractTests(unittest.TestCase):
    def test_migration_stores_hashed_setup_without_client_grants(self):
        self.assertIn("setup_code_hash", MIGRATION)
        self.assertIn("setup_reveal_ciphertext", MIGRATION)
        self.assertIn("setup_code_expires_at", MIGRATION)
        # No SQL GRANTs (comment may mention GRANT).
        sql_body = "\n".join(
            line for line in MIGRATION.splitlines() if not line.lstrip().startswith("--")
        )
        self.assertNotIn("GRANT ", sql_body)
        self.assertIn("service_role", MIGRATION)

    def test_tokens_emit_15min_setup_url(self):
        self.assertIn("15 * 60 * 1000", TOKENS)
        self.assertIn("setupUrl", TOKENS)
        self.assertIn("https://repera.app/ai/?code=", TOKENS)
        self.assertIn("mcpUrl", TOKENS)
        self.assertIn('"https://repera.app/mcp"', TOKENS)
        self.assertIn("setup_reveal_ciphertext", TOKENS)
        self.assertIn("repera-setup-v1:", TOKENS)

    def test_connect_redeems_setup_once(self):
        self.assertIn("redeem-setup", CONNECT)
        self.assertIn("setup_code_used_at", CONNECT)
        self.assertIn("Este código ha caducado (válido 15 minutos)", CONNECT)
        self.assertIn("decryptReveal", CONNECT)

    def test_web_ai_supports_code_and_current_brand(self):
        self.assertIn("redeem-setup", WEB_JS)
        self.assertIn("params.get('code')", WEB_JS)
        self.assertIn("/assets/icon.png", WEB_HTML)
        self.assertNotIn("repera<span>●</span>", WEB_HTML)

    def test_created_token_sheet_is_compact_countdown_mcp_and_token(self):
        sheet = IOS.split("private var createdTokenSheet: some View", 1)[1].split(
            "private static let createdTokenWindow", 1
        )[0]
        self.assertIn('OGPageHeader(title: "Nuevo token")', sheet)
        self.assertIn("formatCountdown", sheet)
        self.assertIn('Text("Enlace del MCP")', sheet)
        self.assertIn("AIProviderLaunch.publicServer", sheet)
        self.assertNotIn('Text("/mcp")', sheet)
        self.assertNotIn("Este token permite", sheet)
        self.assertNotIn("Enlace de setup", sheet)
        self.assertNotIn("Servidor MCP", sheet)
        android = (
            ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt"
        ).read_text(encoding="utf-8")
        created = android.split("if (createdToken != null)", 1)[1]
        self.assertIn("ReperaModalBottomSheet(", created)
        self.assertIn("onDismissRequest = onDismissCreated", created)
        self.assertIn("skipPartiallyExpanded = true", created)
        self.assertNotIn("Dialog(onDismissRequest = onDismissCreated)", created)
        self.assertIn('"Enlace del MCP"', created)
        self.assertIn("AIProviderLaunch.PUBLIC_SERVER", created)
        self.assertNotIn('"/mcp"', created)
        self.assertIn("Icons.Outlined.Close", created)
        self.assertNotIn("Este token permite", created)
        self.assertNotIn("Enlace de setup", created)
        self.assertNotIn("Servidor MCP", created)

    def test_apps_continue_prefers_oauth_and_keeps_bearer_setup(self):
        # OAuth (ChatGPT/Claude con client): no abre /ai en la app; el asistente
        # manda al usuario a /ai/. Bearer (Grok/manual/fallback): setupUrl + PAT.
        self.assertIn("launchWithOAuth", IOS)
        self.assertIn("launchWithSetupToken", IOS)
        self.assertIn("oauthInstructions(for:", IOS)
        self.assertIn("instructions(for: provider, setupUrl:", IOS)
        self.assertIn("https://repera.app/mcp", IOS)
        self.assertIn("https://repera.app/ai/", IOS)
        self.assertNotIn('openURL(URL(string: "https://repera.app/ai/', IOS)
        self.assertIn("continueAIProvider", ANDROID_MAIN)
        self.assertIn("onContinueProvider", ANDROID_SCREEN)
        self.assertIn("fun oauthInstructions(", ANDROID_LAUNCH)
        self.assertIn("fun instructions(provider: AIAccessStore.AIProvider, setupUrl: String)", ANDROID_LAUNCH)
        self.assertIn("PUBLIC_SERVER", ANDROID_LAUNCH)


if __name__ == "__main__":
    unittest.main()
