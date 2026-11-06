"""Source guards for explicit-empty alternatives. Native merge tests own behavior."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CatalogAlternativesClearContract(unittest.TestCase):
    def test_ios_preserves_nil_but_not_explicit_empty(self):
        source = (ROOT / 'Packages/ReperaDomain/Sources/ReperaDomain/RemoteExerciseCatalogMerge.swift').read_text()
        self.assertIn('let alternatives = remote.alternatives ?? old?.catalogAlternatives ?? []', source)
        self.assertNotIn('remote.alternatives?.isEmpty', source)
        self.assertIn('catalogAlternatives: alternatives', source)
        # Do not widen the changed semantics to art or instructions.
        self.assertIn('remote.artKeys?.isEmpty == false', source)
        self.assertIn('remote.instructions?.isEmpty == false', source)

    def test_android_copies_even_an_empty_json_array(self):
        source = (ROOT / 'android/mobile/src/main/java/dev/repera/mobile/RemoteExerciseCatalogWorker.kt').read_text()
        self.assertIn('val alternatives = remote.optJSONArray("alternatives")', source)
        self.assertIn('if (alternatives != null)\n                exercise.put("catalogAlternatives", JSONArray(alternatives.toString()))', source)
        self.assertNotIn('alternatives.length() > 0', source)
        self.assertIn('if (artKeys != null && artKeys.length() > 0)', source)
        self.assertIn('if (steps != null && steps.length() > 0)', source)

    def test_both_native_regressions_cover_presence_and_identity(self):
        paths = [
            'Packages/ReperaDomain/Tests/ReperaDomainTests/RemoteExerciseCatalogTests.swift',
            'android/mobile/src/androidTest/java/dev/repera/mobile/RemoteExerciseCatalogInstrumentedTest.kt'
        ]
        for path in paths:
            with self.subTest(path=path):
                source = (ROOT / path).read_text()
                for case in ['"absent"', '"null"', '"empty"', '"replacement"']:
                    self.assertIn(case, source)
                for field in ['isFavorite', 'catalogAlternatives', 'artKeys', 'instructions']:
                    self.assertIn(field, source)


if __name__ == '__main__':
    unittest.main()
