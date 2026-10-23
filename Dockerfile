# Builds the tooling image for the Infrastructure as Code 101 tutorial.
# Build it locally (works on amd64 and arm64):
#   docker build -t iac101 .

FROM python:3.15-slim

ARG TERRAFORM_VERSION=1.17.0
ARG PULUMI_VERSION=3.272.0
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip nano \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

# Install the Terraform CLI and verify its checksum
RUN ARCH="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && ZIP="terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
    && curl -fsSLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${ZIP}" \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
       | grep " ${ZIP}$" | sha256sum -c - \
    && unzip -q "${ZIP}" terraform -d /usr/local/bin/ \
    && rm "${ZIP}" \
    && terraform version

# Install the Pulumi CLI
RUN curl -fsSL https://get.pulumi.com | sh -s -- --version "${PULUMI_VERSION}"
ENV PATH="/root/.pulumi/bin:${PATH}"
RUN pulumi version

# Copy the Terraform and Pulumi code
COPY terraform/ project/terraform/
COPY pulumi/ project/pulumi/

WORKDIR /root/project

CMD [ "/bin/bash" ]
