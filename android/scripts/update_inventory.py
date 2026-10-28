#!/usr/bin/env python3
"""Guarded append-only inventory writer. Rewrites require a separate reviewed diff."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import sys
import tempfile

HEADER = '# Inventario de trabajo restante'

def checked_append(path, expected_sha256, note):
    path = Path(path)
    old = path.read_bytes()
    if hashlib.sha256(old).hexdigest() != expected_sha256:
        raise ValueError('Inventory changed since inspection; inspect the new state first')
    text = old.decode('utf-8')
    if not text.startswith(HEADER) or '## Estado vigente' not in text:
        raise ValueError('Target is not the inventory')
    if not note.strip().startswith('## ') or re.search(r'(?m)^(?:commit\|date\||[0-9a-f]{8}\|)', note):
        raise ValueError('Expected a prose checkpoint, not a matrix or arbitrary replacement')
    content = text.rstrip() + '\n\n' + note.strip() + '\n'
    fd, tmp = tempfile.mkstemp(prefix='.inventory-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        # Refuse stale replacement, including another change during preparation.
        if path.read_bytes() != old:
            raise ValueError('Inventory changed during preparation')
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--path', required=True)
    parser.add_argument('--expected-sha256', required=True)
    args = parser.parse_args()
    checked_append(args.path, args.expected_sha256, sys.stdin.read())
