"""Unit tests for the Pulumi program, using Pulumi mocks: no credentials or cloud costs.

Run with: venv/bin/python -m unittest -v
"""
import asyncio
import importlib.util
import unittest
from pathlib import Path

import pulumi


class Mocks(pulumi.runtime.Mocks):
    def new_resource(self, args):
        outputs = dict(args.inputs)
        if args.typ == "gcp:compute/instance:Instance":
            outputs["networkInterfaces"] = [
                {"subnetwork": "iac101-pulumi_id", "accessConfigs": [{"natIp": "203.0.113.10"}]}
            ]
        return [f"{args.name}_id", outputs]

    def call(self, args):
        return {}


# Python 3.14+ no longer creates an event loop implicitly, and Pulumi needs one
asyncio.set_event_loop(asyncio.new_event_loop())
pulumi.runtime.set_mocks(Mocks(), preview=False)

# Load __main__.py as a module so the tests can inspect its resources
spec = importlib.util.spec_from_file_location("program", Path(__file__).with_name("__main__.py"))
program = importlib.util.module_from_spec(spec)
spec.loader.exec_module(program)


class TestProgram(unittest.TestCase):
    @pulumi.runtime.test
    def test_free_tier_vm(self):
        def check(args):
            machine_type, boot_disk = args
            self.assertEqual(machine_type, "e2-micro")
            self.assertEqual(boot_disk["initialize_params"]["image"], "cos-cloud/cos-stable")

        return pulumi.Output.all(program.instance.machine_type, program.instance.boot_disk).apply(check)

    @pulumi.runtime.test
    def test_startup_script_runs_container(self):
        return program.instance.metadata_startup_script.apply(
            lambda script: self.assertIn("docker run", script)
        )

    @pulumi.runtime.test
    def test_firewall_targets_only_the_vm(self):
        def check(args):
            target_tags, vm_tags, allows = args
            self.assertEqual(target_tags, vm_tags)
            self.assertEqual(allows[0]["ports"], ["8080"])

        return pulumi.Output.all(
            program.firewall.target_tags, program.instance.tags, program.firewall.allows
        ).apply(check)

    @pulumi.runtime.test
    def test_public_ip(self):
        return program.public_ip.apply(lambda ip: self.assertEqual(ip, "203.0.113.10"))


if __name__ == "__main__":
    unittest.main()
