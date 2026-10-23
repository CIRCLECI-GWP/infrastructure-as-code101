# Infrastructure as Code 101

Sample code for the CircleCI blog tutorial [How do I use Infrastructure as Code?](https://circleci.com/blog/how-do-i-iac/).

The tutorial provisions the same Google Cloud infrastructure twice: once with [Terraform](https://developer.hashicorp.com/terraform) and once with [Pulumi](https://www.pulumi.com/) in Python. Each tool creates a Compute Engine VM that runs a sample web app container on port 8080, plus a firewall rule that allows public traffic to it. The VM is an `e2-micro` in `us-central1` with a 10 GB standard disk, which fits the [Compute Engine Free Tier](https://docs.cloud.google.com/free/docs/free-cloud-features).

## Contents

```
Dockerfile                  # Tooling image: Terraform and the Pulumi CLI on Python
terraform/gcp/compute/      # Terraform code, startup script, and mocked tests
pulumi/gcp/compute/         # Pulumi Python program, startup script, and mocked tests
.circleci/config.yml        # Builds the image and runs both test suites
```

## Quick start

You need Docker, the [Google Cloud CLI](https://docs.cloud.google.com/sdk/docs/install-sdk), and a Google Cloud project with billing and the Compute Engine API enabled.

```shell
gcloud auth application-default login
git clone https://github.com/CIRCLECI-GWP/infrastructure-as-code101.git
cd infrastructure-as-code101
docker build -t iac101 .
docker run -it --name iac101 \
  -v "$HOME/.config/gcloud:/root/.config/gcloud:ro" \
  -e GOOGLE_CLOUD_PROJECT=<your-project-id> \
  iac101
```

Inside the container:

```shell
# Terraform
cd ~/project/terraform/gcp/compute
terraform init && terraform apply
terraform destroy

# Pulumi (local state backend, no Pulumi account needed)
cd ~/project/pulumi/gcp/compute
pulumi login --local
pulumi install
pulumi stack init dev
pulumi up
pulumi destroy
```

## Tests

Both test suites use mocked providers, so they need no credentials and create nothing in the cloud:

```shell
docker run --rm -w /root/project/terraform/gcp/compute iac101 \
  bash -c 'terraform init -backend=false && terraform test'
docker run --rm -w /root/project/pulumi/gcp/compute iac101 \
  bash -c 'pulumi install && venv/bin/python -m unittest -v'
```
