# docker build --build-arg TERRAFORM_VERSION="1.1.8" --build-arg PACKER_VERSION="1.8.0" -t azure-tools .
ARG IMAGE_REPO=mcr.microsoft.com/azure-powershell
ARG IMAGE_VERSION=8.2.0-ubuntu-20.04
ARG TERRAFORM_VERSION=1.2.9
ARG PACKER_VERSION=1.8.3
ARG AZURE_CLI_VERSION=2.40.0


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
COPY --from=builder ["/root/.local/share/powershell/Modules", "/home/${USERNAME}/.local/share/powershell/Modules"]

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
    sudo \
    vim \
    sshpass \
    python3-pip \
    python3.8 \
    python3.8-venv \
    lsb-release \
    gnupg

# Install Azure CLI system level
RUN pip --no-cache-dir install --upgrade pip && \
    pip --no-cache-dir install wheel && \
    pip --no-cache-dir install azure-cli==${AZURE_CLI_VERSION} && \
    az extension add --name azure-devops --system

RUN useradd --uid "$USER_UID" -m "$USERNAME" && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}" && \
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.local"

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME
WORKDIR /home/$USERNAME

# Install Azure CLI user level
RUN pip --no-cache-dir --user install azure-cli==${AZURE_CLI_VERSION} && \
    az extension add --name azure-devops --system
