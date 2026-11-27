import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('infra2load',Path(__file__).with_name('load.py'))
load=importlib.util.module_from_spec(spec);spec.loader.exec_module(load)

class SecretTests(unittest.TestCase):
    def test_recursive_export_redacts_headers_and_login(self):
        raw={'scenario':{'headers':{'Authorization':'Bearer abc'}},'result':{'accessToken':'abc'},'message':'Bearer abc'}
        safe=load.redact(raw,['abc'])
        self.assertEqual(safe['scenario']['headers']['Authorization'],'[REDACTED]')
        self.assertNotIn('abc',str(safe))
    def test_only_declared_disposable_load_stages(self):
        with self.assertRaises(ValueError):load.prepare(100000)
    def test_no_public_plaintext_target(self):
        self.assertEqual(load.TARGET,'http://127.0.0.1:9377')

if __name__=='__main__':unittest.main()
