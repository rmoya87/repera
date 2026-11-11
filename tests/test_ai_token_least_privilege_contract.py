"""Regression contract: personal AI access tokens must be read-only by default."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class AITokenLeastPrivilegeTests(unittest.TestCase):
    def test_server_requires_explicit_write_and_delete_opt_in(self):
        source = (ROOT / "supabase/functions/repera-ai-tokens/index.ts").read_text(encoding="utf-8")
        self.assertIn("scopesFromFlags", source)
        self.assertIn("body.canWrite === true", source)
        self.assertIn("body.canDelete === true", source)
        self.assertIn('"training:delete"', source)
        # Default create path must not force write/delete on.
        self.assertIn(
            "scopesFromFlags(body.canRead !== false, body.canWrite === true, body.canDelete === true)",
            source,
        )
        migration = (
            ROOT / "supabase/migrations/20261111190000_ai_token_delete_scope.sql"
        ).read_text(encoding="utf-8")
        self.assertIn("training:delete", migration)

    def test_native_clients_default_to_read_only(self):
        ios = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
        android = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt").read_text(encoding="utf-8")
        self.assertIn("@State private var canWrite = false", ios)
        self.assertIn("@State private var canDelete = false", ios)
        self.assertIn('\"canWrite\": false', ios)  # Continuar path
        self.assertIn("var canWrite by remember { mutableStateOf(false) }", android)
        self.assertIn("var canDelete by remember { mutableStateOf(false) }", android)

    def test_mcp_gates_write_and_delete_separately(self):
        index = (ROOT / "supabase/functions/repera-mcp/index.ts").read_text(encoding="utf-8")
        mutations = (ROOT / "supabase/functions/repera-mcp/mutations.ts").read_text(encoding="utf-8")
        changes = (ROOT / "supabase/functions/repera-mcp/athlete-changes.ts").read_text(encoding="utf-8")
        self.assertIn('scopes.includes("training:delete")', index)
        self.assertIn("registerMutationTools(server, db, ownerId, canWrite, canDelete)", index)
        self.assertIn("if (canWrite)", mutations)
        self.assertIn("if (canDelete)", mutations)
        self.assertIn("if(canWrite)", changes)
        self.assertIn("if(canDelete)", changes)

if __name__ == "__main__":
    unittest.main()
