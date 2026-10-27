#!/usr/bin/env python3
"""Get the original NASA PCoE Battery Data Set and extract B0005.mat only.

NASA's archive contains nested ZIPs in some releases; search recursively. Raw
files are deliberately .gitignored because redistribution terms are unclear.
"""
from __future__ import annotations
import hashlib
import io
from pathlib import Path
import sys
import urllib.request
import zipfile

URL = 'https://phm-datasets.s3.amazonaws.com/NASA/5.+Battery+Data+Set.zip'
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'data/raw/B0005.mat'
TEMP = ROOT / 'data/raw/nasa-battery-download.zip'


def find_mat(zip_source, target='B0005.mat', depth=0):
    if depth > 4:
        raise RuntimeError('Maximum archive nesting exceeded')
    with zipfile.ZipFile(zip_source, 'r') as z:
        for name in z.namelist():
            if name.replace('\\', '/').split('/')[-1].lower() == target.lower():
                with z.open(name) as f:
                    return f.read()
        for name in z.namelist():
            if name.lower().endswith('.zip'):
                try:
                    with z.open(name) as f:
                        content = f.read()
                    found = find_mat(io.BytesIO(content), target, depth+1)
                    if found:
                        return found
                except (zipfile.BadZipFile, RuntimeError):
                    continue
    return None


def main():
    DEST.parent.mkdir(parents=True, exist_ok=True)
    if DEST.exists():
        print(f'Already exists: {DEST}; SHA256 {hashlib.sha256(DEST.read_bytes()).hexdigest()}')
        return
    print('Downloading original NASA archive:', URL, flush=True)
    try:
        urllib.request.urlretrieve(URL, TEMP)
        raw = find_mat(TEMP)
        if raw is None:
            raise FileNotFoundError('B0005.mat not found inside NASA archive')
        if len(raw) < 50_000:
            raise ValueError('Suspiciously small MATLAB file')
        DEST.write_bytes(raw)
        print(f'Extracted {DEST} ({len(raw):,} bytes)')
        print('SHA256:', hashlib.sha256(raw).hexdigest())
    except Exception as exc:
        sys.exit(f'Download/extraction failed: {exc}\n'
                 f'Get the Battery Data Set from NASA and place B0005.mat at {DEST}')
    finally:
        TEMP.unlink(missing_ok=True)

if __name__ == '__main__':
    main()
