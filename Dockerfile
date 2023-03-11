# docker build --build-arg TERRAFORM_VERSION="1.4.0" --build-arg PACKER_VERSION="1.8.6" -t azure-tools .
ARG IMAGE_REPO=mcr.microsoft.com/azure-powershell
ARG IMAGE_VERSION=8.2.0-ubuntu-20.04
ARG TERRAFORM_VERSION=1.4.0
ARG PACKER_VERSION=1.8.6
ARG AZURE_CLI_VERSION=2.46.0


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
ARG USERNAME=azureuser
ARG USER_UID=1000

# Copy files from builder
COPY --from=builder ["/usr/bin/terraform", "/usr/bin/terraform"]
COPY --from=builder ["/usr/bin/packer", "/usr/bin/packer"]
COPY --from=builder ["/root/.local/share/powershell/Modules", "/opt/microsoft/powershell/7/Modules"]

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
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
    sudo \
    vim \
    sshpass \
    python3-pip \
    python3.8 \
    python3.8-venv \
    lsb-release \
    gnupg

# Install Azure CLI system level
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

RUN AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y "azure-cli=${AZURE_CLI_VERSION}-1~focal" && \
    az extension add --name azure-devops --system

RUN useradd --uid "$USER_UID" -ms /bin/bash "$USERNAME" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}" && \
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME
WORKDIR /home/$USERNAME

