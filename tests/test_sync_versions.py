"""Portable regression tests for the Xcode version synchronization helper."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'sync_versions.py'
spec = importlib.util.spec_from_file_location('sync_versions', SCRIPT)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class VersionSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cfg = Path(self.temp.name) / 'Version.xcconfig'
        self.cfg.write_text('REPERA_MARKETING_VERSION = 1.0.0\nREPERA_BUILD_NUMBER = 5\n')
        self.original_config = sync.CONFIG
        sync.CONFIG = self.cfg
        self.addCleanup(setattr, sync, 'CONFIG', self.original_config)

    def test_version_update_and_idempotency(self):
        self.assertTrue(sync.write_config('2.4.1', '62'))
        self.assertEqual(sync.read_config(), ('2.4.1', '62'))
        self.assertFalse(sync.write_config('2.4.1', '62'))

    def test_invalid_version_and_build_do_not_change_source(self):
        for marketing, build in [('oops', '8'), ('1.2.3.4', '8'), ('1.2.3', '8; rm -rf /')]:
            with self.assertRaises(ValueError):
                sync.write_config(marketing, build)
        self.assertEqual(sync.read_config(), ('1.0.0', '5'))

    def test_read_target_settings_before_xcodegen_regenerates(self):
        fake_output = '    MARKETING_VERSION = 2.0.3\n    CURRENT_PROJECT_VERSION = 117\n'
        original_project = sync.PROJECT
        sync.PROJECT = Path(self.temp.name)
        self.addCleanup(setattr, sync, 'PROJECT', original_project)
        with patch.object(sync.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, fake_output)) as command:
            self.assertEqual(sync.from_project(), ('2.0.3', '117'))
            self.assertEqual(command.call_args.args[0][-1], '-showBuildSettings')

    def test_regeneration_never_downgrades_new_build_from_git(self):
        self.assertEqual(sync.prefer_newer_config(('1.0.0','4')),('1.0.0','5'))
        self.assertEqual(sync.prefer_newer_config(('1.0.0','6')),('1.0.0','6'))
        self.assertEqual(sync.prefer_newer_config(('1.1.0','1')),('1.1.0','1'))

    def test_archive_preaction_rejects_stale_local_xcode_build(self):
        sync.write_config('1.0', '39')
        with patch.dict('os.environ', {'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '38'}):
            with patch('sys.argv', ['sync_versions.py', '--from-env']):
                self.assertEqual(sync.main(), 1)
        self.assertEqual(sync.read_config(), ('1.0', '39'))

    def test_archive_preaction_keeps_newer_xcode_build(self):
        sync.write_config('1.0', '39')
        with patch.dict('os.environ', {'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '40'}):
            with patch('sys.argv', ['sync_versions.py', '--from-env']):
                self.assertEqual(sync.main(), 0)
        self.assertEqual(sync.read_config(), ('1.0', '40'))

    def test_skip_missing_generated_project(self):
        original_project = sync.PROJECT
        sync.PROJECT = Path(self.temp.name) / 'absent.xcodeproj'
        self.addCleanup(setattr, sync, 'PROJECT', original_project)
        self.assertIsNone(sync.from_project())


if __name__ == '__main__':
    unittest.main()
