#!/bin/bash

# Function to set password from file or environment variable
set_password() {
    local password=""
    
    if [[ -n "$PASSWORD_FILE" && -f "$PASSWORD_FILE" ]]; then
        password=$(cat "$PASSWORD_FILE" | tr -d '\n\r')
        echo "Using password from file: $PASSWORD_FILE"
    elif [[ -n "$PASSWORD" ]]; then
        password="$PASSWORD"
        echo "Using password from environment variable"
    else
        password="password"
        echo "Using default password"
    fi
    
    echo "root:$password" | chpasswd
}

# Function to setup home directory symlinks
setup_home_directory() {
    # Create config directory if it doesn't exist
    mkdir -p /root/config
    
    # List of files/directories to symlink from mounted config
    declare -a config_files=(
        ".bashrc"
        ".zshrc" 
        ".vimrc"
        ".tmux.conf"
        ".kube"
        ".ssh"
        ".gitconfig"
        ".terraformrc"
        ".helm"
        "tailscale-state"
    )
    
    # Create symlinks for configuration files
    for file in "${config_files[@]}"; do
        if [[ -f "/root/config/$file" || -d "/root/config/$file" ]]; then
            # Remove existing file/directory if it exists and isn't already a symlink
            if [[ -e "/root/$file" && ! -L "/root/$file" ]]; then
                rm -rf "/root/$file"
            fi
            # Create symlink if it doesn't exist
            if [[ ! -L "/root/$file" ]]; then
                ln -sf "/root/config/$file" "/root/$file"
                echo "Created symlink for $file"
            fi
        fi
    done
    
    # Ensure .kube directory exists with proper permissions
    mkdir -p /root/config/.kube /root/.kube
    chmod 700 /root/config/.kube 2>/dev/null || true
    
    # Ensure .ssh directory exists with proper permissions
    mkdir -p /root/config/.ssh /root/.ssh
    chmod 700 /root/config/.ssh 2>/dev/null || true
}

# Function to setup fstab
setup_fstab() {
    if [[ -f "/root/config/fstab" ]]; then
        echo "Setting up fstab from mounted config"
        cp /root/config/fstab /etc/fstab
        chmod 644 /etc/fstab
    fi
}

# Function to start Tailscale daemon
start_tailscale() {
    echo "Starting Tailscale daemon..."
    
    # Create tailscale state directory
    mkdir -p /var/lib/tailscale
    
    # If we have persistent tailscale state, restore it
    if [[ -d "/root/config/tailscale-state" ]]; then
        cp -r /root/config/tailscale-state/* /var/lib/tailscale/ 2>/dev/null || true
    fi
    
    # Start tailscaled in the background
    /usr/sbin/tailscaled --state-dir=/var/lib/tailscale --socket=/var/run/tailscale/tailscaled.sock &
    
    # Wait a moment for daemon to start
    sleep 2
    
    # Ensure state is saved back to persistent storage
    mkdir -p /root/config/tailscale-state
    
    # Setup a background job to periodically sync tailscale state
    (
        while true; do
            sleep 60
            if [[ -d "/var/lib/tailscale" ]]; then
                cp -r /var/lib/tailscale/* /root/config/tailscale-state/ 2>/dev/null || true
            fi
        done
    ) &
}

# Function to setup shell defaults
setup_shells() {
    # Determine which shell to use based on SHELL environment variable
    local target_shell="bash"  # default
    
    case "${SHELL,,}" in  # Convert to lowercase
        "sh"|"bash")
            target_shell="bash"
            ;;
        "zsh")
            target_shell="zsh"
            ;;
        *)
            echo "Warning: Unknown shell '$SHELL', defaulting to bash"
            target_shell="bash"
            ;;
    esac
    
    echo "Setting default shell to: $target_shell"
    
    # Set the shell for root user
    if [ "$target_shell" = "zsh" ]; then
        chsh -s /usr/bin/zsh root
    else
        chsh -s /usr/bin/bash root
    fi
    
    # Ensure shell completion directories exist
    mkdir -p /etc/bash_completion.d
    
    # Add kubectl completion to bash
    kubectl completion bash > /etc/bash_completion.d/kubectl 2>/dev/null || true
    helm completion bash > /etc/bash_completion.d/helm 2>/dev/null || true
}

# Function to generate SSH host keys if they don't exist
setup_ssh() {
    if [[ ! -f /root/config/.ssh/ssh_host_rsa_key ]]; then
        echo "Generating SSH host keys..."
        mkdir -p /root/config/.ssh
        ssh-keygen -A
        # Move host keys to persistent storage
        mv /etc/ssh/ssh_host_* /root/config/.ssh/
    fi
    
    # Restore host keys from persistent storage
    cp /root/config/.ssh/ssh_host_* /etc/ssh/ 2>/dev/null || true
    
    # Set proper permissions
    chmod 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
}

echo "=== Container Starting ==="
echo "Timestamp: $(date)"

# Set root password
set_password

# Setup home directory and configuration
setup_home_directory

# Setup fstab
setup_fstab

# Setup SSH
setup_ssh

# Setup shells
setup_shells

# Start Tailscale (optional, only if needed)
if [[ "$ENABLE_TAILSCALE" == "true" ]]; then
    start_tailscale
fi

echo "=== Container Initialization Complete ==="

# Execute the passed command
exec "$@"