# MgmtShell - Management Shell Container

A comprehensive Ubuntu 24.04 LTS development container with pre-installed tools for DevOps, Kubernetes, and system administration.

**Repository**: https://github.com/EricZarnosky/MgmtShell

## Features

### Installed Tools
- **System Tools**: openssh, git, nano, vim, neovim, tmux, mc (Midnight Commander)
- **Shells**: bash (with completion), zsh (with Oh My Zsh and completions)
- **DevOps Tools**: terraform, kubectl, helm, kustomize, k9s
- **Kubernetes**: talosctl for Talos Linux clusters
- **File Systems**: NFS and SMB/CIFS support
- **Utilities**: 7zip, openssl, jq, curl, wget
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

## Configuration

### Password Management

You can set the root password in two ways:

**Method 1: Environment Variable**
```yaml
environment:
  - PASSWORD=your_secure_password
```

**Method 2: Password File (Recommended for production)**
```yaml
environment:
  - PASSWORD_FILE=/run/secrets/root_password
secrets:
  - root_password

secrets:
  root_password:
    file: ./secrets/root_password.txt
```

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
2. After first run, authenticate: `docker exec -it ubuntu-devcontainer tailscale up`
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

### Kubernetes Operations
```bash
# All kubectl configurations persist
docker exec -it mgmtshell kubectl get nodes
docker exec -it mgmtshell k9s
```

### File Operations
```bash
# Access Midnight Commander
docker exec -it mgmtshell mc
```

## Directory Structure

```
MgmtShell/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .dockerignore
├── .env.example
├── README.md
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

## Security Considerations

1. **Change the default password** immediately
2. **Use password files** instead of environment variables for production
3. **Secure SSH keys** in the persistent `.ssh` directory
4. **Network access** - Container runs in host network mode for Tailscale compatibility
5. **Privileged mode** - Required for NFS/SMB mounting and Tailscale

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