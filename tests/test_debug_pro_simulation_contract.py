"""Debug Pro simulation must force Free/Pro after StoreKit verified-Pro cache merge.

Regression: simulating Gratis left the picker on Free while isPro stayed true
because refresh() rehydrated verifiedPro from UserDefaults (visible on Mac with
local StoreKit history). Android already applies the override after the merge.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


def source(path: str) -> str:
    return (SRC / path).read_text(encoding="utf-8")


class DebugProSimulationContractTests(unittest.TestCase):
    def test_apply_debug_provider_restores_storekit_when_override_off(self):
        manager = source("Monetization/SubscriptionManager.swift")
        block = manager.split("func applyDebugProvider()", 1)[1].split("#endif", 1)[0]
        self.assertIn("overrideEnabled", block)
        self.assertIn("StoreKitEntitlementProvider()", block)
        self.assertIn("DebugEntitlementController.shared.provider", block)

    def test_refresh_skips_verified_pro_hold_while_debug_override_forces_status(self):
        manager = source("Monetization/SubscriptionManager.swift")
        free_hold = manager.split("else if next.status == .free", 1)[1]
        free_hold = free_hold.split("applySnapshot(next)", 1)[0]
        self.assertIn("overrideEnabled", free_hold)
        self.assertIn("verifiedProCacheKey", free_hold)
        self.assertIn("#if DEBUG", free_hold)
        # A Release `false` constant makes the else unreachable
        # ("will never be executed" / condition always true).
        self.assertNotIn("debugForcesCommercialStatus", free_hold)
        override = free_hold.split("overrideEnabled", 1)[1].split("} else {", 1)[0]
        self.assertIn("removeObject", override)
        self.assertNotIn("applyingVerifiedProHold", override)
        hold = manager.split("func applyingVerifiedProHold", 1)[1]
        hold = hold.split("private struct PersistedVerifiedPro", 1)[0]
        self.assertIn("grantsProAccess", hold)

    def test_debug_section_shows_effective_access(self):
        settings = source("SettingsView.swift")
        section = settings.split("private struct SettingsDebugProSection", 1)[1]
        section = section.split("#endif", 1)[0]
        self.assertIn("subscriptions.isPro", section)
        self.assertIn("Efectivo", section)


if __name__ == "__main__":
    unittest.main()
