import hashlib
from pathlib import Path
import tempfile
import unittest
from update_inventory import checked_append

class InventoryWriterTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / 'inventory.md'
        self.original = b'# Inventario de trabajo restante\n\n## Estado vigente\n735/70\n'
        self.path.write_bytes(self.original)
        self.digest = hashlib.sha256(self.original).hexdigest()
    def test_appends_without_changing_existing_text(self):
        checked_append(self.path, self.digest, '## Checkpoint\nStill partial.')
        self.assertTrue(self.path.read_bytes().startswith(self.original))
        self.assertIn('Still partial.', self.path.read_text())
    def test_rejects_reused_matrix_variable_without_writing(self):
        for note in ['commit|date|subject', '## Checkpoint\nab123456|date|subject|partial', 'replacement']:
            with self.assertRaises(ValueError):
                checked_append(self.path, self.digest, note)
            self.assertEqual(self.original, self.path.read_bytes())
    def test_rejects_stale_digest(self):
        with self.assertRaises(ValueError):
            checked_append(self.path, 'stale', '## Checkpoint\nNote')
        self.assertEqual(self.original, self.path.read_bytes())
    def test_rejects_wrong_target(self):
        self.path.write_text('commit|date|subject\n')
        digest = hashlib.sha256(self.path.read_bytes()).hexdigest()
        with self.assertRaises(ValueError):
            checked_append(self.path, digest, '## Checkpoint\nNote')
        self.assertEqual('commit|date|subject\n', self.path.read_text())

if __name__ == '__main__':
    unittest.main()
