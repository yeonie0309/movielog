"""Safety contracts for rolling deployment; no AWS calls or real state writes."""
import unittest
from unittest.mock import patch
import manage


class RollingSafetyTests(unittest.TestCase):
    def test_cleanup_refuses_a_different_account(self):
        with patch.dict(manage.state, {'account': 'expected', 'region': manage.REGION}, clear=True), \
             patch.object(manage, 'aws', return_value={'Account': 'other'}) as aws:
            with self.assertRaisesRegex(RuntimeError, 'different account or region'):
                manage.cleanup_start()
            self.assertEqual(aws.call_args_list, [unittest.mock.call('sts', 'get-caller-identity')])

    def test_cleanup_refuses_a_different_region(self):
        with patch.dict(manage.state, {'account': 'expected', 'region': 'different-region'}, clear=True), \
             patch.object(manage, 'aws', return_value={'Account': 'expected'}) as aws:
            with self.assertRaisesRegex(RuntimeError, 'different account or region'):
                manage.cleanup_finish()
            self.assertEqual(aws.call_args_list, [unittest.mock.call('sts', 'get-caller-identity')])

    def run_deploy(self, healthy, fail=False, instances=('i-a', 'i-b')):
        events = []
        healthy = set(healthy)

        def aws(service, operation, data=None):
            if operation == 'get-parameter':
                return {'Parameter': {'Value': 'lab/repo:old'}}
            if operation == 'describe-auto-scaling-groups':
                return {'AutoScalingGroups': [{'Instances': [
                    {'InstanceId': i, 'LifecycleState': 'InService'} for i in instances]}]}
            if operation == 'describe-target-health':
                return {'TargetHealthDescriptions': [
                    {'Target': {'Id': i}, 'TargetHealth': {'State': 'healthy'}} for i in healthy]}
            if operation == 'deregister-targets':
                instance = data['Targets'][0]['Id']
                events.append(('drain', instance))
                healthy.discard(instance)
            elif operation == 'register-targets':
                instance = data['Targets'][0]['Id']
                events.append(('register', instance))
                healthy.add(instance)
            else:
                raise AssertionError((service, operation))
            return {}

        def remote(instance, commands):
            events.append(('swap', instance))
            if fail:
                raise RuntimeError('readiness failed')

        def parameter(name, value):
            events.append(('parameter', value))

        with patch.dict(manage.state, {'repo': 'lab/repo', 'good_image': 'lab/repo:new', 'asg': 'lab', 'tg': 'tg'}, clear=True), \
             patch.dict(manage.os.environ, {}, clear=True), \
             patch.object(manage, 'aws', aws), patch.object(manage, 'save'), \
             patch.object(manage, 'remote', remote), patch.object(manage, 'wait_target'), \
             patch.object(manage, 'parameter', parameter):
            try:
                manage.deploy()
            except RuntimeError as error:
                return events, str(error)
        return events, None

    def test_failed_readiness_stops_before_second_node_and_restores_launch_pointer(self):
        events, error = self.run_deploy({'i-a', 'i-b'}, fail=True)
        self.assertEqual(error, 'readiness failed')
        self.assertEqual([x for x in events if x[0] == 'swap'], [('swap', 'i-a')])
        self.assertNotIn(('drain', 'i-b'), events)
        self.assertEqual(events[-1], ('parameter', 'lab/repo:old'))

    def test_no_healthy_peer_is_never_drained(self):
        events, error = self.run_deploy(set())
        self.assertIn('No healthy peer', error)
        self.assertFalse(any(x[0] in ('drain', 'swap') for x in events))

    def test_rollback_recovers_failed_node_before_touching_healthy_peer(self):
        events, error = self.run_deploy({'i-a'})
        self.assertIsNone(error)
        self.assertEqual([x for x in events if x[0] == 'swap'], [('swap', 'i-b'), ('swap', 'i-a')])

    def test_single_instance_cannot_run_rolling_deploy(self):
        events, error = self.run_deploy({'i-a'}, instances=('i-a',))
        self.assertIn('at least two', error)
        self.assertEqual(events, [])


if __name__ == '__main__':
    unittest.main()
