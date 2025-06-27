FROM ubuntu:24.04

# Set build-time arguments for build info
ARG BUILD_DATE
ARG VCS_REF
ENV BUILD_DATE=${BUILD_DATE}
ENV VCS_REF=${VCS_REF}

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PASSWORD=password \
    PASSWORD_FILE=""

# Install base packages and dependencies
RUN apt-get update && apt-get install -y \
    openssh-server \
    git \
    curl \
    wget \
    unzip \
    gnupg \
    lsb-release \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    nano \
    vim \
    neovim \
    tmux \
    screen \
    bash-completion \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    nfs-common \
    cifs-utils \
    p7zip-full \
    openssl \
    jq \
    postgresql-client \
    mysql-client \
    sqlite3 \
    python3 \
    python3-pip \
    python3-venv \
    rsync \
    openssh-client \
    gpg \
    ripgrep \
    fzf \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update && apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update && apt-get install -y helm \
    && rm -rf /var/lib/apt/lists/*

# Install Kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/

# Install Go (latest stable)
RUN GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1) \
    && wget https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz \
    && rm ${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js and npm (latest LTS)
RUN NODE_VERSION=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version') \
    && curl -fsSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1

# Install MongoDB CLI tools
RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update && apt-get install -y mongodb-mongosh mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Redis CLI
RUN apt-get update && apt-get install -y redis-tools && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN python3 -m pip install --upgrade pip \
    && pip3 install ansible ansible-core httpie

# Install yq (YAML processor) - latest version
RUN YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name) \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Install DigitalOcean CLI (doctl) - latest version
RUN DOCTL_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz \
    && tar xf doctl-${DOCTL_VERSION}-linux-amd64.tar.gz \
    && mv doctl /usr/local/bin \
    && rm doctl-${DOCTL_VERSION}-linux-amd64.tar.gz

# Install PowerShell
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm packages-microsoft-prod.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for managing remote Docker hosts)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install containerd CLI tools - latest version
RUN CONTAINERD_VERSION=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
    && tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
    && rm containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Install nerdctl (Docker-compatible CLI for containerd) - latest version
RUN NERDCTL_VERSION=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz \
    && tar Cxzvf /usr/local/bin nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz \
    && rm nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz

# Install crictl (CRI CLI) - latest version
RUN CRICTL_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | jq -r .tag_name) \
    && wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz \
    && tar zxvf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin \
    && rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz

# Install kubectx and kubens
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx \
    && ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Pulumi
RUN curl -fsSL https://get.pulumi.com | sh \
    && mv /root/.pulumi/bin/pulumi /usr/local/bin/

# Install Packer - latest version
RUN PACKER_VERSION=$(curl -s https://api.github.com/repos/hashicorp/packer/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
    && mv packer /usr/local/bin/ \
    && rm packer_${PACKER_VERSION}_linux_amd64.zip

# Install Flux CLI - latest version
RUN curl -s https://fluxcd.io/install.sh | bash \
    && mv /root/.local/bin/flux /usr/local/bin/

# Install ArgoCD CLI - latest version
RUN ARGO_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name) \
    && wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-amd64 \
    && mv argocd-linux-amd64 /usr/local/bin/argocd \
    && chmod +x /usr/local/bin/argocd

# Install Jenkins CLI (using latest stable war to get CLI)
RUN wget https://get.jenkins.io/war-stable/latest/jenkins.war -O /tmp/jenkins.war \
    && java -jar /tmp/jenkins.war --help || true \
    && rm /tmp/jenkins.war \
    && wget https://repo.jenkins-ci.org/public/org/jenkins-ci/main/cli/2.426/cli-2.426.jar -O /usr/local/bin/jenkins-cli.jar

# Install Skaffold - latest version
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 \
    && install skaffold /usr/local/bin/ \
    && rm skaffold

# Install SOPS (Secrets OPerationS) - latest version
RUN SOPS_VERSION=$(curl -s https://api.github.com/repos/mozilla/sops/releases/latest | jq -r .tag_name) \
    && wget https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 \
    && mv sops-${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Install HashiCorp Vault CLI - latest version
RUN VAULT_VERSION=$(curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && unzip vault_${VAULT_VERSION}_linux_amd64.zip \
    && mv vault /usr/local/bin/ \
    && rm vault_${VAULT_VERSION}_linux_amd64.zip

# Install pass (password manager)
RUN apt-get update && apt-get install -y pass && rm -rf /var/lib/apt/lists/*

# Install Prometheus promtool - latest version
RUN PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r .tag_name | sed 's/v//') \
    && wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && tar xvfz prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/ \
    && rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64*

# Install Nix package manager
RUN sh <(curl -L https://nixos.org/nix/install) --daemon \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc \
    && echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.zshrc

# Install Talosctl
RUN curl -sL https://talos.dev/install | sh

# Install k9s
RUN K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name) \
    && curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar xz -C /tmp \
    && mv /tmp/k9s /usr/local/bin/

# Install additional NoSQL CLI tools
# Install DynamoDB Local (optional - for local development)
RUN mkdir -p /opt/dynamodb \
    && curl -L https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz | tar xz -C /opt/dynamodb

# Install Cassandra CLI (cqlsh) via pip
RUN pip3 install cqlsh

# Install Elasticsearch CLI tools
RUN pip3 install elasticsearch-cli

# Install etcd client (etcdctl) - latest version
RUN ETCD_VER=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | jq -r .tag_name) \
    && curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    && tar xzf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp \
    && mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd-${ETCD_VER}-linux-amd64*

# Install mc (Midnight Commander)
RUN apt-get update && apt-get install -y mc && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Configure SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Oh My Zsh for root
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Setup shell completions
RUN echo 'source /etc/bash_completion' >> /root/.bashrc \
    && echo 'source <(kubectl completion bash)' >> /root/.bashrc \
    && echo 'source <(helm completion bash)' >> /root/.bashrc \
    && echo 'source <(terraform -install-autocomplete)' >> /root/.bashrc 2>/dev/null || true \
    && echo 'source <(aws_completer)' >> /root/.bashrc \
    && echo 'source <(az completion bash)' >> /root/.bashrc \
    && echo 'source <(doctl completion bash)' >> /root/.bashrc \
    && echo 'source <(flux completion bash)' >> /root/.bashrc \
    && echo 'source <(argocd completion bash)' >> /root/.bashrc \
    && echo 'source <(vault -autocomplete-install)' >> /root/.bashrc 2>/dev/null || true

# Setup zsh completions
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'source <(talosctl completion zsh)' >> /root/.zshrc \
    && echo 'source <(aws_completer)' >> /root/.zshrc \
    && echo 'source <(az completion zsh)' >> /root/.zshrc \
    && echo 'source <(doctl completion zsh)' >> /root/.zshrc \
    && echo 'source <(flux completion zsh)' >> /root/.zshrc \
    && echo 'source <(argocd completion zsh)' >> /root/.zshrc \
    && echo 'source <(vault -autocomplete-install)' >> /root/.zshrc 2>/dev/null || true

# Create directories for mounted volumes
RUN mkdir -p /root/config /etc/fstab.d

# Copy entrypoint script and huh command
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY huh /usr/local/bin/huh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/huh

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]