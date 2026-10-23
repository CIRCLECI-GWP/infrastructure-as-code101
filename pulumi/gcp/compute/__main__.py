"""Deploys a sample web app to a Compute Engine VM.

The project comes from the GOOGLE_CLOUD_PROJECT environment variable, and
credentials come from Application Default Credentials (ADC).
"""
from pathlib import Path

import pulumi
import pulumi_gcp as gcp

APP_PORT = 8080
VM_TAG = "iac101-pulumi"

startup_script = Path(__file__).with_name("startup.sh").read_text()

# A dedicated VPC network, so the program doesn't depend on the project's default network
network = gcp.compute.Network("iac101-pulumi", auto_create_subnetworks=False)
subnet = gcp.compute.Subnetwork(
    "iac101-pulumi",
    network=network.id,
    ip_cidr_range="10.20.0.0/24",
)

# Allow public traffic to the app port, but only on VMs with this tag
firewall = gcp.compute.Firewall(
    "allow-8080",
    network=network.name,
    allows=[{"protocol": "tcp", "ports": [str(APP_PORT)]}],
    source_ranges=["0.0.0.0/0"],
    target_tags=[VM_TAG],
)

# An e2-micro VM in us-central1 with a 10 GB standard disk fits the Compute Engine Free Tier
instance = gcp.compute.Instance(
    "iac101-pulumi",
    machine_type="e2-micro",
    tags=[VM_TAG],
    boot_disk={
        "initialize_params": {
            "image": "cos-cloud/cos-stable",
            "size": 10,
            "type": "pd-standard",
        },
    },
    network_interfaces=[
        {
            "subnetwork": subnet.id,
            "access_configs": [{}],  # Ephemeral public IP
        }
    ],
    metadata_startup_script=startup_script,
)

public_ip = instance.network_interfaces.apply(lambda nics: nics[0].access_configs[0].nat_ip)

pulumi.export("public_ip", public_ip)
pulumi.export("app_url", pulumi.Output.concat("http://", public_ip, f":{APP_PORT}"))
