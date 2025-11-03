#!/bin/bash
set -e

# This script runs as root and handles UID/GID mapping before switching to coder user

# Check if we actually need Docker for this command
NEEDS_DOCKER=true
if [ "$1" = "opencode" ] && [ "$2" = "--version" ]; then
    NEEDS_DOCKER=false
elif [ "$1" = "npm" ]; then
    NEEDS_DOCKER=false
fi

# Start Docker daemon if not already running (Docker-in-Docker)
# Only if Docker socket is not available and we actually need Docker
if [ "$NEEDS_DOCKER" = "true" ]; then
    # First, check if Docker socket is available from host (mounted)
    docker_socket_ready=false
    for i in {1..5}; do
        if [ -S /var/run/docker.sock ] && docker info >/dev/null 2>&1; then
            docker_socket_ready=true
            echo "Docker socket detected and working - using host Docker daemon"
            break
        fi
        if [ $i -lt 5 ]; then
            sleep 0.5
        fi
    done

    # Only start Docker daemon if socket is not available/ready
    if ! $docker_socket_ready; then
        if [ -S /var/run/docker.sock ]; then
            # Socket exists but not responding, likely a permission issue
            echo "WARNING: Docker socket exists but is not responding. May be a permission issue."
        else
            echo "Starting Docker daemon..."
            dockerd > /tmp/dockerd.log 2>&1 &
            
            # Wait for Docker to be ready
            timeout=30
            while [ $timeout -gt 0 ] && ! docker info >/dev/null 2>&1; do
                sleep 1
                timeout=$((timeout - 1))
            done
            
            if ! docker info >/dev/null 2>&1; then
                echo "ERROR: Docker daemon failed to start. Check /tmp/dockerd.log"
                cat /tmp/dockerd.log 2>&1 || true
                exit 1
            fi
            echo "Docker daemon started successfully"
        fi
    fi
fi

# Fix Docker socket permissions if it's mounted from host
if [ -S /var/run/docker.sock ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    echo "Docker socket found with GID: $DOCKER_SOCK_GID"
    
    # Ensure the docker group in container matches the socket GID
    if ! getent group "$DOCKER_SOCK_GID" >/dev/null; then
        groupadd -g "$DOCKER_SOCK_GID" docker_host 2>/dev/null || true
    fi
    
    # Add coder user to the docker socket's group
    usermod -aG "$DOCKER_SOCK_GID" coder 2>/dev/null || true
fi

# Get target UID/GID from environment (default to 1000)
TARGET_UID=${HOST_UID:-1000}
TARGET_GID=${HOST_GID:-1000}

# Get current coder user UID/GID
CURRENT_UID=$(id -u coder)
CURRENT_GID=$(id -g coder)

# Update UID/GID if they don't match
if [ "$TARGET_UID" != "$CURRENT_UID" ] || [ "$TARGET_GID" != "$CURRENT_GID" ]; then
    echo "Adjusting coder user UID:GID from $CURRENT_UID:$CURRENT_GID to $TARGET_UID:$TARGET_GID"
    
    # Update group ID if needed
    if [ "$TARGET_GID" != "$CURRENT_GID" ]; then
        groupmod -g "$TARGET_GID" coder 2>/dev/null || true
    fi
    
    # Update user ID if needed
    if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
        usermod -u "$TARGET_UID" coder 2>/dev/null || true
    fi
    
    # Fix ownership of home directory
    chown -R "$TARGET_UID:$TARGET_GID" /home/coder 2>/dev/null || true
fi

# NOTE: We do NOT change ownership of /workspace
# The workspace is a host mount and should maintain host permissions
# OpenCode runs as the host user (via UID/GID mapping) so it already has the right permissions

# Switch to coder user and execute the command
# Set HOME explicitly to ensure it points to /home/coder
export HOME=/home/coder
export USER=coder

# Source NVM and SDKMAN to make Node.js and Java available
export NVM_DIR="/home/coder/.nvm"

# Use gosu or su-exec style execution with proper environment
exec setpriv --reuid="$TARGET_UID" --regid="$TARGET_GID" --init-groups \
    bash -c "source $NVM_DIR/nvm.sh && source /home/coder/.sdkman/bin/sdkman-init.sh 2>/dev/null || true && exec \"\$@\"" \
    -- "$@"
