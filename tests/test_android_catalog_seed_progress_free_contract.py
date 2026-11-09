"""Android: base seed de ejercicios + teasers Free en Progreso Entreno/Fuerza."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "android/mobile/src/main/java/dev/repera/mobile"


def read(name: str) -> str:
    return (MOBILE / name).read_text(encoding="utf-8")


class AndroidCatalogSeedProgressFreeContract(unittest.TestCase):
    def test_bootstrap_hydrates_empty_or_missing_local_state(self):
        bootstrap = read("CatalogBootstrap.kt")
        migration = read("CatalogRefreshMigration.kt")
        main = read("MainActivity.kt")
        self.assertIn("fun ensureHydrated", bootstrap)
        self.assertIn("CatalogRefreshMigration.ensure", bootstrap)
        self.assertIn("ensureVisibleBase", migration)
        self.assertIn("restoreVisibleCatalog", migration)
        self.assertIn("ensureCatalogHydrated", main)
        self.assertIn("ensureVisibleBase", main)
        self.assertIn("profile?.uniqueId != accountId", main)

    def test_remote_apply_never_leaves_empty_visible_catalog(self):
        remote = read("RemoteExerciseCatalogWorker.kt")
        self.assertIn("visible == 0 && catalog.length() > 0", remote)
        self.assertIn('item.put("isCatalogArchived", false)', remote)

    def test_progress_free_training_strength_always_have_teaser_snapshot(self):
        tab = read("ProgressTab.kt")
        preview = read("ProgressPreview.kt")
        self.assertIn("fun teaserSnapshot", preview)
        self.assertIn("ProgressPreview.teaserSnapshot", tab)
        self.assertIn("!pro ->", tab)
        self.assertIn("enrichSnapshotWithDemo", tab)
        training = tab.split("ProgressCategory.TRAINING -> {", 1)[1].split(
            "ProgressCategory.STRENGTH -> {", 1
        )[0]
        strength = tab.split("ProgressCategory.STRENGTH -> {", 1)[1].split(
            "ProgressCategory.FITNESS -> {", 1
        )[0]
        self.assertIn("ProTeaserCard", training)
        self.assertIn("ProTeaserCard", strength)
        self.assertIn("ProgressPreview.sessionScores", training)


if __name__ == "__main__":
    unittest.main()
