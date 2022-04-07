# docker build --build-arg TERRAFORM_VERSION="1.1.7" --build-arg PACKER_VERSION="1.8.0" -t azure-tools .
ARG IMAGE_REPO=mcr.microsoft.com/azure-powershell
ARG IMAGE_VERSION=ubuntu-20.04
ARG TERRAFORM_VERSION=1.1.7
ARG PACKER_VERSION=1.8.0
ARG AZURE_CLI_VERSION=2.35.0

FROM ${IMAGE_REPO}:${IMAGE_VERSION} AS builder
ARG TERRAFORM_VERSION
ARG PACKER_VERSION

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip

# Terraform
RUN wget --quiet https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/bin

# Packer
RUN wget --quiet https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    mv packer /usr/bin

FROM ${IMAGE_REPO}:${IMAGE_VERSION}
ARG AZURE_CLI_VERSION

# Copy files from builder
COPY --from=builder ["/usr/bin/terraform", "/usr/bin/terraform"]
COPY --from=builder ["/usr/bin/packer", "/usr/bin/packer"]

# Copy terraform modules
RUN mkdir terraform/modules
COPY terraform/modules terraform/modules

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libicu66 \
    libunwind8 \
    netcat \
    openssl \
    libssl1.0 \
    unzip \
    wget \
    tree \
    sshpass \
    python3-pip \
    python3.8 \
    python3.8-venv \
    lsb-release \
    gnupg

# Install Azure CLI
RUN pip --no-cache-dir install --upgrade pip && \
    pip --no-cache-dir install wheel && \
    pip --no-cache-dir install azure-cli==${AZURE_CLI_VERSION}

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
