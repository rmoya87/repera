"""Unit tests for the Play release metadata generator (no Play credentials required)."""
import unittest
from datetime import datetime, timezone

from play_release_metadata import (
    baseline_date, production_release, release_notes, version_code, version_for_month, prepare, testing_tracks,
)

NOW = datetime(2026, 11, 10, 11, 0, tzinfo=timezone.utc)


class PlayReleaseMetadataTest(unittest.TestCase):
    def test_publish_internal_and_default_closed_track(self):
        snapshot = {"tracks": [
            {"track": "internal"}, {"track": "alpha"},
            {"track": "production"}, {"track": "beta"}]}
        self.assertEqual("internal,alpha", testing_tracks(snapshot))

    def test_closed_custom_track_is_supported(self):
        snapshot = {"tracks": [{"track": "internal"}, {"track": "repera-testers"}]}
        self.assertEqual("internal,repera-testers", testing_tracks(snapshot))

    def test_ambiguous_closed_tracks_need_explicit_choice(self):
        snapshot = {"tracks": [{"track": "internal"}, {"track": "grupo-a"}, {"track": "grupo-b"}]}
        with self.assertRaisesRegex(ValueError, "REPERA_PLAY_CLOSED_TRACK"):
            testing_tracks(snapshot)
        self.assertEqual("internal,grupo-b", testing_tracks(snapshot, "grupo-b"))

    def test_production_and_open_tracks_cannot_be_selected_as_closed(self):
        snapshot = {"tracks": [{"track": "internal"}, {"track": "alpha"},
                               {"track": "production"}, {"track": "beta"}]}
        for invalid in ("production", "beta", "internal", "qa", "unknown"):
            with self.subTest(track=invalid):
                with self.assertRaises(ValueError):
                    testing_tracks(snapshot, invalid)

    def test_missing_closed_track_blocks_publication(self):
        snapshot = {"tracks": [{"track": "internal"}, {"track": "production"}]}
        with self.assertRaisesRegex(ValueError, "pista cerrada"):
            testing_tracks(snapshot)

    def test_first_monthly_version_starts_at_zero(self):
        self.assertEqual("2026.11.0", version_for_month({"tracks": []}, NOW))

    def test_same_month_increments_from_all_tracks(self):
        snapshot = {"tracks": [
            {"track": "internal", "releases": [{"name": "2026.11.0", "versionCodes": ["101"]}]},
            {"track": "production", "releases": [{"name": "2026.11.2", "versionCodes": ["104"]}]},
        ]}
        self.assertEqual("2026.11.3", version_for_month(snapshot, NOW))

    def test_new_month_resets_to_zero(self):
        snapshot = {"tracks": [{"track": "internal",
                                 "releases": [{"name": "2026.10.19", "versionCodes": ["900"]}]}]}
        self.assertEqual("2026.11.0", version_for_month(snapshot, NOW))

    def test_integer_code_exceeds_all_play_versions(self):
        snapshot = {"tracks": [{"track": "internal",
                                 "releases": [{"name": "legacy", "versionCodes": ["999999"]}]}],
                    "bundles": [{"versionCode": 1000000}]}
        self.assertGreater(version_code(snapshot, NOW), 1000000)
        self.assertIsInstance(version_code(snapshot, NOW), int)

    def test_production_date_requires_verified_reference(self):
        snapshot = {"tracks": [{"track": "production", "releases": [
            {"name": "2026.10.5", "versionCodes": ["100"], "status": "completed"}]}]}
        with self.assertRaisesRegex(ValueError, "REPERA_LAST_PRODUCTION"):
            baseline_date(snapshot, NOW, {})
        with self.assertRaisesRegex(ValueError, "REPERA_LAST_PRODUCTION"):
            baseline_date(snapshot, NOW, {"REPERA_LAST_PRODUCTION_VERSION": "2026.10.4",
                                         "REPERA_LAST_PRODUCTION_DATE": "2026-10-31T12:00:00Z"})
        date, source = baseline_date(snapshot, NOW, {
            "REPERA_LAST_PRODUCTION_VERSION": "2026.10.5",
            "REPERA_LAST_PRODUCTION_DATE": "2026-10-31T12:00:00Z"})
        self.assertEqual("production", source)
        self.assertEqual("2026-10-31T12:00:00+00:00", date)

    def test_without_production_uses_month_start_not_fake_production_date(self):
        date, source = baseline_date({"tracks": []}, NOW, {})
        self.assertEqual("first-release-month", source)
        self.assertEqual("2026-10-31T23:00:00+00:00", date)

    def test_release_notes_market_benefits_but_only_supported_topics(self):
        notes = release_notes([
            "fix(android): notification visibility on lock screen",
            "android: contextual foreground WOD timer",
        ])
        self.assertIn("notificaciones", notes)
        self.assertIn("entrenamientos de fuerza", notes)
        self.assertNotIn("Billing", notes)
        self.assertLessEqual(len(notes), 500)

    def test_vague_internal_commits_do_not_invent_features(self):
        notes = release_notes(["refactor internal persistence"])
        self.assertIn("Mejoras internas", notes)
        self.assertNotIn("rutas", notes)

    def test_test_only_changes_do_not_claim_user_features(self):
        notes = release_notes(["test(android): verify new GPS map",
                               "ci(android): add timer job",
                               "fix(test): notification fixture"])
        self.assertIn("Mejoras internas", notes)
        self.assertNotIn("rutas", notes)
        self.assertNotIn("notificaciones", notes)

    def test_real_shipping_changes_produce_marketing_benefits(self):
        notes = release_notes([
            "android: port contextual notification and manual strength clock helpers from beta",
            "fix(android): remove transitive AdServices advertising permissions",
            "test(android): describe new GPS route",
        ])
        self.assertIn("notificaciones", notes)
        self.assertIn("fuerza", notes)
        self.assertNotIn("rutas", notes)
        self.assertLessEqual(len(notes), 500)

    def test_real_changes_are_recorded_in_metadata(self):
        snapshot = {"tracks": []}
        details = prepare(snapshot, NOW, {}, [
            "test(android): fake GPS features",
            "fix(android): foreground WOD timer"
        ])
        self.assertEqual(["fix(android): foreground WOD timer"], details["evidence"])

    def test_zero_android_commits_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "cambios Android"):
            release_notes([])


if __name__ == "__main__":
    unittest.main()
