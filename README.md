# MgmtShell - Management Shell Container

A comprehensive Ubuntu 24.04 LTS development container with pre-installed tools for DevOps, Kubernetes, and system administration.

**Repository**: https://github.com/EricZarnosky/MgmtShell

## Features

### Installed Tools
- **System Tools**: openssh, git, nano, vim, neovim, tmux, screen, mc, rsync, fzf, ripgrep
- **Shells**: bash (with completion), zsh (with Oh My Zsh and completions)
- **DevOps Tools**: opentofu, kubectl, helm, kustomize, k9s, ansible, packer, pulumi
- **Kubernetes**: talosctl, kubectx, kubens, flux, argocd, skaffold
- **Container Tools**: docker-cli, nerdctl, crictl, containerd
- **Programming Languages**: Python 3 (with pip), Go, Node.js (with npm, for JavaScript)
- **Cloud CLI Tools**: 
  - **AWS**: aws-cli v2
  - **Azure**: az-cli  
  - **Google Cloud**: gcloud
  - **DigitalOcean**: doctl
  - **Multi-cloud**: PowerShell
- **Data Processing**: jq, yq, xq, hcl2json, htmlq, dasel, httpie, xmlstarlet, pandoc
- **Database CLI Tools**: 
  - **SQL**: postgresql-client, mysql-client, sqlite3
  - **NoSQL**: mongosh, mongodb-database-tools, redis-tools, cqlsh (Cassandra), etcdctl
  - **Search**: elasticsearch-cli
- **Security & Secrets**: sops, openbao, pass, gpg
- **Monitoring**: promtool (Prometheus)
- **CI/CD**: jenkins-cli, flux, argocd, skaffold
- **File Systems**: NFS and SMB/CIFS support
- **Package Management**: nix
- **Utilities**: 7zip, openssl, curl, wget, huh (version info tool)
- **Networking**: tailscale for VPN connectivity

### Persistent Storage
- Root home directory (`/root`) mapped to `./config` for persistence
- Configuration files automatically symlinked from persistent storage
- SSH host keys preserved across container restarts
- Kubernetes configurations, Git settings, and shell customizations persist

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/EricZarnosky/MgmtShell.git
   cd MgmtShell
   ```

2. **Create the config directory**:
   ```bash
   mkdir -p config secrets
   ```

3. **Set up environment** (optional):
   ```bash
   cp .env.example .env
   # Edit .env with your preferences
   ```

4. **Build and run**:
   ```bash
   docker-compose up -d
   ```

5. **Connect via SSH**:
   ```bash
   ssh root@localhost -p 2222
   # Default password: "password" (change this!)
   ```

## Using Pre-built Image

Instead of building locally, you can use the pre-built image:

```bash
# Pull the latest image
docker pull ghcr.io/ericzarnosky/mgmtshell:latest

# Update docker-compose.yml to use pre-built image
# Comment out 'build: .' and use:
# image: ghcr.io/ericzarnosky/mgmtshell:latest
```

## Docker Run Command

For quick CLI usage without docker-compose:

```bash
# Basic usage (bash shell, default password)
docker run -d --name mgmtshell --privileged --network host -p 2222:22 -e PASSWORD=mypassword -v ./config:/root/config ghcr.io/ericzarnosky/mgmtshell:latest

# With custom shell
docker run -d --name mgmtshell --privileged --network host -p 2222:22 -e PASSWORD=mypassword -e SHELL=zsh -v ./config:/root/config ghcr.io/ericzarnosky/mgmtshell:latest

# Full command with all options
docker run -d \
  --name mgmtshell \
  --hostname mgmtshell \
  --restart unless-stopped \
  --privileged \
  --network host \
  -p 2222:22 \
  -e PASSWORD=your_secure_password \
  -e SHELL=bash \
  -e TZ=UTC \
  -e ENABLE_TAILSCALE=false \
  -v $(pwd)/config:/root/config \
  -v $(pwd)/config/fstab:/etc/fstab:ro \
  --cap-add SYS_ADMIN \
  --cap-add NET_ADMIN \
  --cap-add DAC_READ_SEARCH \
  --device /dev/fuse \
  ghcr.io/ericzarnosky/mgmtshell:latest
```

## Configuration

### Password Management

You can set the root password in two ways:

**Method 1: Environment Variable**
```yaml
environment:
  - PASSWORD=your_secure_password
  - SHELL=bash  # Options: bash, zsh, sh
  - PUID=1000   # User ID for file permissions
  - PGID=1000   # Group ID for file permissions
```

**Method 2: Password File (Recommended for production)**
```yaml
environment:
  - PASSWORD_FILE=/run/secrets/root_password
  - SHELL=zsh  # Set your preferred shell
secrets:
  - root_password

secrets:
  root_password:
    file: ./secrets/root_password.txt
```

### Shell Configuration

You can set the default shell for the root user using the `SHELL` environment variable:

- `SHELL=bash` (default) - Use Bash shell
- `SHELL=zsh` - Use Zsh with Oh My Zsh
- `SHELL=sh` - Use basic sh shell

### User Permissions

You can set the user and group IDs for file ownership using the `PUID` and `PGID` environment variables:

- `PUID=1000` - User ID (default: 0 for root)
- `PGID=1000` - Group ID (default: 0 for root)

This is useful when mounting volumes to ensure files have the correct ownership on the host system:

```bash
# Get your user ID and group ID
id
# uid=1000(username) gid=1000(username)

# Set in docker-compose.yml
environment:
  - PUID=1000
  - PGID=1000
```

The shell setting affects:
- Default login shell for SSH connections
- Shell used in `docker exec` when not specified
- Shell completions and configurations loaded

### Persistent Configuration Files

The following files/directories are automatically managed in persistent storage:

- `.bashrc` - Bash configuration
- `.zshrc` - Zsh configuration  
- `.vimrc` - Vim configuration
- `.tmux.conf` - Tmux configuration
- `.kube/` - Kubernetes configurations
- `.ssh/` - SSH keys and configuration
- `.gitconfig` - Git configuration
- `.terraformrc` - Terraform configuration
- `.helm/` - Helm configuration
- `tailscale-state/` - Tailscale authentication state

### File System Mounts

Place your fstab configuration in `./config/fstab` to automatically mount NFS/SMB shares:

```bash
# Example fstab entries
192.168.1.100:/mnt/nfs /mnt/nfs nfs defaults 0 0
//192.168.1.100/share /mnt/smb cifs username=user,password=pass 0 0
```

### Tailscale Integration

To enable Tailscale:

1. Set `ENABLE_TAILSCALE=true` in your environment
2. After first run, authenticate: `docker exec -it mgmtshell tailscale up`
3. Authentication state persists in `./config/tailscale-state/`

## Usage Examples

### SSH Access
```bash
ssh root@localhost -p 2222
```

### Execute Commands
```bash
docker exec -it mgmtshell bash
docker exec -it mgmtshell zsh
```

### Tool Version Information
```bash
# Show all installed tool versions
docker exec -it mgmtshell huh

# Show detailed information about a specific tool
docker exec -it mgmtshell huh --app kubectl
docker exec -it mgmtshell huh --app terraform
docker exec -it mgmtshell huh -a python3

# Show help for huh command
docker exec -it mgmtshell huh --help
```

### Programming and Scripting
```bash
# Python development
docker exec -it mgmtshell python3 --version
docker exec -it mgmtshell pip3 list

# Go development  
docker exec -it mgmtshell go version
docker exec -it mgmtshell go env

# Node.js development
docker exec -it mgmtshell node --version
docker exec -it mgmtshell npm --version

# PowerShell
docker exec -it mgmtshell pwsh
```

### Cloud Operations
```bash
# AWS CLI
docker exec -it mgmtshell aws configure
docker exec -it mgmtshell aws s3 ls

# Azure CLI
docker exec -it mgmtshell az login
docker exec -it mgmtshell az account list

# Google Cloud CLI
docker exec -it mgmtshell gcloud auth login
docker exec -it mgmtshell gcloud projects list

# DigitalOcean CLI
docker exec -it mgmtshell doctl auth init
docker exec -it mgmtshell doctl compute droplet list

# Ansible
docker exec -it mgmtshell ansible --version
docker exec -it mgmtshell ansible-playbook playbook.yml
```

### Container & Kubernetes Operations
```bash
# Docker (remote)
docker exec -it mgmtshell docker -H tcp://remote-host:2376 ps

# Kubernetes context switching
docker exec -it mgmtshell kubectx production
docker exec -it mgmtshell kubens kube-system

# Kubernetes tools
docker exec -it mgmtshell kubectl get nodes
docker exec -it mgmtshell k9s
docker exec -it mgmtshell flux get sources git

# Container runtime tools
docker exec -it mgmtshell crictl ps
docker exec -it mgmtshell nerdctl ps

# Helm operations
docker exec -it mgmtshell helm list
docker exec -it mgmtshell helm install myapp ./chart

# Talos Linux
docker exec -it mgmtshell talosctl config endpoint 10.0.0.1
```

### Infrastructure as Code
```bash
# OpenTofu (Terraform alternative)
docker exec -it mgmtshell tofu plan
docker exec -it mgmtshell tofu apply

# Pulumi
docker exec -it mgmtshell pulumi up

# Packer
docker exec -it mgmtshell packer build template.json
```

### Security & Secrets Management
```bash
# OpenBao (Vault alternative)
docker exec -it mgmtshell bao login
docker exec -it mgmtshell bao kv get secret/myapp

# SOPS (encrypted files)
docker exec -it mgmtshell sops -e secrets.yaml

# Password manager
docker exec -it mgmtshell pass show myservice/password

# GPG operations
docker exec -it mgmtshell gpg --gen-key
```

### Database Operations
```bash
# PostgreSQL
docker exec -it mgmtshell psql -h hostname -U username -d database

# MySQL
docker exec -it mgmtshell mysql -h hostname -u username -p

# MongoDB
docker exec -it mgmtshell mongosh mongodb://hostname:27017

# Redis
docker exec -it mgmtshell redis-cli -h hostname

# Cassandra
docker exec -it mgmtshell cqlsh hostname

# SQLite
docker exec -it mgmtshell sqlite3 database.db
```

### Data Processing & APIs
```bash
# JSON processing
docker exec -it mgmtshell echo '{"name":"test"}' | jq '.name'

# YAML processing  
docker exec -it mgmtshell yq '.spec.containers[0].name' pod.yaml

# XML processing
docker exec -it mgmtshell echo '<root><name>test</name></root>' | xq '.root.name'
docker exec -it mgmtshell xmlstarlet sel -t -v "//name" file.xml

# HCL processing (Terraform files)
docker exec -it mgmtshell hcl2json main.tf | jq '.resource'

# HTML processing
docker exec -it mgmtshell htmlq 'title' index.html

# Universal data processing (JSON, YAML, TOML, XML, CSV)
docker exec -it mgmtshell dasel -f data.yaml '.items.[0].name'

# Markdown processing
docker exec -it mgmtshell pandoc README.md -o README.html

# HTTP requests
docker exec -it mgmtshell http GET api.example.com/users
docker exec -it mgmtshell curl -X POST api.example.com/data

# File searching
docker exec -it mgmtshell rg "pattern" /path/to/search
docker exec -it mgmtshell fzf
```

### File Operations
```bash
# Access Midnight Commander
docker exec -it mgmtshell mc

# File compression/extraction
docker exec -it mgmtshell 7z x archive.7z
```

## Directory Structure

```
MgmtShell/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── huh
├── .dockerignore
├── .env.example
├── README.md
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── config/              # Persistent home directory
│   ├── .bashrc
│   ├── .zshrc
│   ├── .kube/
│   ├── .ssh/
│   ├── fstab
│   └── tailscale-state/
└── secrets/            # Password files (if using)
    └── root_password.txt
```

## Automated Builds

The container is automatically built and published to GitHub Container Registry on every push to main:

- **Latest builds**: `ghcr.io/ericzarnosky/mgmtshell:latest`
- **Date-tagged builds**: `ghcr.io/ericzarnosky/mgmtshell:YYYY.MM.DD-<commit>`
- **Version tags**: `ghcr.io/ericzarnosky/mgmtshell:v1.0.0` (when you tag releases)

### Available Tags
- `:latest` - Latest build from main branch
- `:main` - Latest main branch build
- `:YYYY.MM.DD-<commit>` - Date and commit specific builds
- `:v<version>` - Semantic version tags (when you create releases)

## Security Considerations

1. **Change the default password** immediately
2. **Use password files** instead of environment variables for production
3. **Secure SSH keys** in the persistent `.ssh` directory
4. **Network access** - Container runs in host network mode for Tailscale compatibility
5. **Privileged mode** - Required for NFS/SMB mounting and Tailscale

## Latest Versions

All tools are automatically installed with their latest versions at build time:

- **Go**: Latest stable from https://go.dev/VERSION?m=text
- **Node.js**: Latest LTS from nodejs.org API
- **Kubernetes tools**: Latest from GitHub releases API
- **Cloud tools**: Latest from official repositories
- **Security tools**: Latest from GitHub releases API

This ensures you always have the most current versions with latest features and security updates.

## Troubleshooting

### SSH Connection Issues
- Verify port mapping: `docker-compose ps`
- Check SSH service: `docker exec -it mgmtshell systemctl status ssh`
- Review logs: `docker-compose logs mgmtshell`

### Mount Issues
- Ensure proper privileges and capabilities are set
- Check fstab syntax in `./config/fstab`
- Verify network connectivity to NFS/SMB servers

### Tailscale Issues
- Check daemon status: `docker exec -it mgmtshell tailscale status`
- Re-authenticate: `docker exec -it mgmtshell tailscale up`
- Check logs: `docker exec -it mgmtshell journalctl -u tailscaled`

### Tool Version Issues
- Run `docker exec -it mgmtshell huh` to see all installed versions
- Use `docker exec -it mgmtshell huh --app <tool>` for detailed tool information
- Check if tool is in PATH: `docker exec -it mgmtshell which <tool>`

### Shell Issues
- Check current shell: `docker exec -it mgmtshell echo $SHELL`
- Verify shell setting: `docker exec -it mgmtshell getent passwd root`
- Override temporarily: `docker exec -it mgmtshell zsh` or `docker exec -it mgmtshell bash`

## Customization

### Adding More Tools
Edit the Dockerfile to install additional packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-additional-package \
    && rm -rf /var/lib/apt/lists/*
```

### Shell Customization
- Bash: Edit `./config/.bashrc`
- Zsh: Edit `./config/.zshrc`
- Oh My Zsh themes and plugins can be configured in `.zshrc`

### Port Changes
Modify the ports section in docker-compose.yml:

```yaml
ports:
  - "your_port:22"
```

## Advanced Usage

### Docker-in-Docker
Uncomment the Docker socket mount in docker-compose.yml:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### Multiple Environments
Create separate docker-compose files:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Shell Selection Examples

**Default Bash:**
```bash
docker run -d --name mgmtshell-bash -e SHELL=bash -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/mgmtshell:latest
```

**Zsh with Oh My Zsh:**
```bash
docker run -d --name mgmtshell-zsh -e SHELL=zsh -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/mgmtshell:latest
```

**Minimal sh:**
```bash
docker run -d --name mgmtshell-sh -e SHELL=sh -e PASSWORD=test123 -v ./config:/root/config ghcr.io/ericzarnosky/mgmtshell:latest
```

### Using with CI/CD
The container can be used in CI/CD pipelines:

```yaml
# GitHub Actions example
jobs:
  deploy:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/ericzarnosky/mgmtshell:latest
      env:
        SHELL: bash
    steps:
      - uses: actions/checkout@v4
      - name: Deploy with kubectl
        run: kubectl apply -f manifests/
```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PASSWORD` | `password` | Root user password |
| `PASSWORD_FILE` | - | Path to file containing password |
| `SHELL` | `bash` | Default shell (bash, zsh, sh) |
| `PUID` | `0` | User ID for file permissions |
| `PGID` | `0` | Group ID for file permissions |
| `TZ` | `UTC` | Timezone |
| `ENABLE_TAILSCALE` | `false` | Enable Tailscale daemon |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build locally: `docker-compose build`
5. Submit a pull request

## License

This project is open source. See the repository for license details.

## Support

For issues and questions:
- Create an issue on GitHub: https://github.com/EricZarnosky/MgmtShell/issues
- Check existing discussions and documentation

---

**MgmtShell** - Your complete infrastructure management toolkit in a container! 🚀