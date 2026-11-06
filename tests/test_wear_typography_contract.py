"""Wear Material3 Typography no incluye tokens headline* del phone M3."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WEAR = ROOT / "android/wear/src/main/java/dev/repera/wear"


class WearTypographyContractTests(unittest.TestCase):
    def test_live_turn_page_avoids_phone_headline_tokens(self):
        src = (WEAR / "WearLiveActivityScreen.kt").read_text(encoding="utf-8")
        self.assertNotIn("headlineMedium", src)
        self.assertNotIn("headlineLarge", src)
        self.assertNotIn("headlineSmall", src)
        # Distancia de giro: displayMedium entre flecha (displayLarge) e instrucción.
        self.assertIn("MaterialTheme.typography.displayMedium", src)

    def test_wear_sources_do_not_use_headline_typography(self):
        offenders = []
        for path in WEAR.rglob("*.kt"):
            text = path.read_text(encoding="utf-8")
            if "typography.headline" in text:
                offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual(offenders, [])


if __name__ == "__main__":
    unittest.main()
