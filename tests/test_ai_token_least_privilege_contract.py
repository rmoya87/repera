"""Regression contract: personal AI access tokens must be read-only by default."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class AITokenLeastPrivilegeTests(unittest.TestCase):
    def test_server_requires_explicit_write_opt_in(self):
        source = (ROOT / "supabase/functions/repera-ai-tokens/index.ts").read_text(encoding="utf-8")
        self.assertIn('body.canWrite === true ? ["training:read", "training:write"] : ["training:read"]', source)
        self.assertNotIn('body.canWrite === false ? ["training:read"]', source)

    def test_native_clients_default_to_read_only(self):
        ios = (ROOT / "Apps/Repera/Sources/AIAccessView.swift").read_text(encoding="utf-8")
        android = (ROOT / "android/mobile/src/main/java/dev/repera/mobile/AIAccessScreen.kt").read_text(encoding="utf-8")
        self.assertIn("@State private var canWrite = false", ios)
        self.assertIn("var canWrite by remember { mutableStateOf(false) }", android)

if __name__ == "__main__":
    unittest.main()
