import base64
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('infra2cloud', Path(__file__).with_name('cloud.py'))
cloud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cloud)

class Infra2SafetyTests(unittest.TestCase):
    def test_private_alb_even_if_reused_cluster_asks_for_public(self):
        with patch.object(cloud, 'raw_aws', return_value={}) as run:
            cloud.aws('elbv2', 'create-load-balancer', {'Scheme':'internet-facing'})
            self.assertEqual(run.call_args.args[2]['Scheme'], 'internal')

    def test_alb_ingress_restricted_to_application_sg(self):
        with patch.dict(cloud.lab.state, {'app_sg':'sg-lab'}, clear=True), patch.object(cloud, 'raw_aws', return_value={}) as run:
            cloud.aws('ec2','authorize-security-group-ingress',{'GroupId':'alb','IpPermissions':[{'FromPort':80,'IpRanges':[{'CidrIp':'0.0.0.0/0'}]}]})
            permission=run.call_args.args[2]['IpPermissions'][0]
            self.assertNotIn('IpRanges',permission)
            self.assertEqual(permission['UserIdGroupPairs'],[{'GroupId':'sg-lab'}])

    def test_no_direct_bootstrap_application_port(self):
        with patch.object(cloud, 'raw_aws') as run:
            cloud.aws('ec2','authorize-security-group-ingress',{'IpPermissions':[{'FromPort':3000,'IpRanges':[{'CidrIp':'1.2.3.4/32'}]}]})
            run.assert_not_called()

    def test_metrics_enabled_in_bootstrap_but_no_embedded_secrets(self):
        script=base64.b64decode(cloud.user_data(True)).decode()
        chunks=[line.split()[1] for line in script.splitlines() if line.startswith('echo ') and '| base64 -d' in line]
        decoded=[base64.b64decode(value).decode() for value in chunks]
        self.assertIn('METRICS_ENABLED=true',decoded[0])
        self.assertTrue(any('GC_TOKEN:gc-token' in v for v in decoded))
        self.assertNotIn('AKIA', script)
        self.assertNotIn('0.0.0.0:12345', script)

    def test_cleanup_report_does_not_write_week1(self):
        original=cloud.lab.ROOT
        def check():
            self.assertEqual(cloud.lab.ROOT,cloud.HERE)
        with patch.object(cloud.lab,'cleanup_finish',side_effect=check), patch.dict(cloud.lab.state,{},clear=True):
            cloud.cleanup_finish()
        self.assertEqual(cloud.lab.ROOT,original)

    def test_foundation_refuses_existing_parameters(self):
        with patch.dict(cloud.lab.state,{},clear=True), patch.object(cloud,'aws',return_value={'Parameters':[{'Name':'/umc/app/existing'}]}), patch.object(cloud.lab,'foundation') as create:
            with self.assertRaisesRegex(RuntimeError,'refusing overwrite'):
                cloud.foundation()
            create.assert_not_called()

if __name__=='__main__':
    unittest.main()
