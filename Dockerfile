FROM ubuntu:24.04

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
    bash-completion \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    nfs-common \
    cifs-utils \
    p7zip-full \
    openssl \
    jq \
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

# Install Talosctl
RUN curl -sL https://talos.dev/install | sh

# Install k9s
RUN K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name) \
    && curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar xz -C /tmp \
    && mv /tmp/k9s /usr/local/bin/

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
    && echo 'source <(terraform -install-autocomplete)' >> /root/.bashrc 2>/dev/null || true

# Setup zsh completions
RUN echo 'autoload -U compinit && compinit' >> /root/.zshrc \
    && echo 'source <(kubectl completion zsh)' >> /root/.zshrc \
    && echo 'source <(helm completion zsh)' >> /root/.zshrc \
    && echo 'source <(talosctl completion zsh)' >> /root/.zshrc

# Create directories for mounted volumes
RUN mkdir -p /root/config /etc/fstab.d

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose SSH port
EXPOSE 22

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]