"""Contratos de prioridad Supabase y caché OTA en Android.

Son comprobaciones estáticas, no sustituyen el dispositivo o tests Android.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class AndroidCatalogRemoteAuthorityTest(unittest.TestCase):
    def test_published_cache_overrides_stale_art_in_every_android_surface(self):
        catalog = read("android/mobile/src/main/java/dev/repera/mobile/RemoteExerciseCatalogWorker.kt")
        art = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseArtImages.kt")
        detail = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseDetailScreen.kt")
        thumb = read("android/mobile/src/main/java/dev/repera/mobile/ReperaComponents.kt")
        wod = read("android/mobile/src/main/java/dev/repera/mobile/WodExerciseArt.kt")
        data = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseArtData.kt")
        resolver = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseArtResolver.kt")
        self.assertIn("fun cachedPublishedArtKeys(name: String)", catalog)
        self.assertIn('item.optJSONArray("art_keys")', catalog)
        self.assertIn('normalize(entry.optString("name")) == normalized', catalog)
        self.assertIn("RemoteExerciseCatalog(context).cachedPublishedArtKeys(name)", art)
        self.assertIn("cached != null -> PublishedArtSelection(cached, true)", art)
        self.assertIn("remoteKeysKnown && artKeys.isEmpty()", art)
        self.assertIn("publishedSelection(entry.name, entry.artKeys)", detail)
        self.assertIn("publishedSelection(name, artKeys)", thumb)
        self.assertIn("publishedSelection(exercise.name, exercise.artKeys)", wod)
        self.assertNotIn('"Pallof Press" to "art_press_militar"', data)
        self.assertIn('if (normalizedName == "pallof press") return null', resolver)

    def test_event_cursor_atomic_cache_and_per_exercise_merge(self):
        catalog = read("android/mobile/src/main/java/dev/repera/mobile/RemoteExerciseCatalogWorker.kt")
        self.assertIn("if (cursor == head) return false", catalog)
        self.assertIn("entries.put(key, JSONObject(item.toString()))", catalog)
        self.assertIn("commitCache(working)", catalog)
        foreground = catalog.split("fun refresh(accessToken: String)", 1)[1].split(
            "fun applyToAccount(", 1
        )[0]
        self.assertNotIn("prefetchFromCatalogCache(context)", foreground)
        worker = catalog.split("internal class RemoteExerciseCatalogWorker(", 1)[1]
        self.assertIn("RemoteExerciseArtCache.prefetchFromCatalogCache(applicationContext)", worker)
        self.assertIn("original != exercise.toString()", catalog)
        self.assertIn("replaceIfUnchanged(bytes", catalog)
        self.assertIn('exercise.put("artKeys", JSONArray(artKeys.toString()))', catalog)
        self.assertIn('if (current == null) {', catalog)

    def test_remote_art_keys_never_fall_back_to_seed_while_pending(self):
        art = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseArtImages.kt")
        remote = art.split("if (artKeys.isNotEmpty()) {", 1)[1].split("val hero =", 1)[0]
        self.assertIn("return artKeys.filter", remote)
        self.assertNotIn("if (available.isNotEmpty())", remote)
        self.assertIn("RemoteExerciseArtCache.ensureAvailable(context, stem)", art)
        self.assertIn("if (preferRemote) return null", art)
        self.assertIn('val key = "$stem@$targetPx@$preferRemote@$revision"', art)

    def test_all_three_android_art_surfaces_use_remote_preference(self):
        components = read("android/mobile/src/main/java/dev/repera/mobile/ReperaComponents.kt")
        wod = read("android/mobile/src/main/java/dev/repera/mobile/WodExerciseArt.kt")
        detail = read("android/mobile/src/main/java/dev/repera/mobile/ExerciseDetailScreen.kt")
        self.assertIn("preferRemote = published", components)
        self.assertIn("preferRemote=published", wod)
        self.assertIn("remoteStems = entry.artKeys", detail)
        self.assertIn("preferRemote = published", detail)
        self.assertIn("entry.instructions, aliases", detail)

    def test_media_cache_deduplicates_and_retries_without_touching_workouts(self):
        cache = read("android/mobile/src/main/java/dev/repera/mobile/RemoteExerciseArtCache.kt")
        self.assertIn("synchronized(downloadGate)", cache)
        self.assertIn("FAILED_RETRY_MS = 60_000L", cache)
        self.assertIn("ensureAvailable(context, stem)", cache)
        self.assertNotIn("WorkoutRepository", cache)
        self.assertNotIn("LocalSnapshotStore", cache)


if __name__ == "__main__":
    unittest.main()
