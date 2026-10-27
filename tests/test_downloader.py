import io
from pathlib import Path
import sys
import unittest
import zipfile
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from download_nasa import find_mat

class NASAArchiveTests(unittest.TestCase):
    def test_extract_mat_through_nested_zip(self):
        inn=io.BytesIO()
        with zipfile.ZipFile(inn,'w') as z:
            z.writestr('BatteryAgingARC-FY08Q4/B0005.mat',b'MATLAB-file')
        out=io.BytesIO()
        with zipfile.ZipFile(out,'w') as z:
            z.writestr('some-other-file.txt','metadata')
            z.writestr('FY08Q4.zip',inn.getvalue())
        self.assertEqual(find_mat(io.BytesIO(out.getvalue())),b'MATLAB-file')

if __name__=='__main__': unittest.main()
