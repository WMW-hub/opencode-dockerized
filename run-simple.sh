#!/bin/bash

# Alternative simple runner without docker-compose
# This provides a more portable option

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="opencode-dockerized:latest"

# Source the shared config module
source "$SCRIPT_DIR/config-lib.sh"

# Get project directory (default to current directory)
PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Build image if it doesn't exist
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Parse custom config
parse_config
build_mount_args
build_env_args

# Build volume mount arguments - only mount files that exist
VOLUME_ARGS="-v $PROJECT_DIR:/workspace"

# OpenCode configuration directory (read-only)
# Includes: opencode.json, AGENTS.md, .env, agent/, command/, plugin/, node_modules/, etc.
[ -d "$HOME/.config/opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.config/opencode:/home/coder/.config/opencode:ro"

# OpenCode data directory (read-write for auth, logs, sessions, storage)
# Mount entire .local/share/opencode directory
[ -d "$HOME/.local/share/opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.local/share/opencode:/home/coder/.local/share/opencode"

# OpenCode provider package cache (improves startup time and prevents API errors)
# See: https://opencode.ai/docs/troubleshooting/#ai_apicallerror-and-provider-package-issues
[ -d "$HOME/.cache/opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.cache/opencode:/home/coder/.cache/opencode"

# Oh My OpenCode cache (for oh-my-opencode plugin)
[ -d "$HOME/.cache/oh-my-opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.cache/oh-my-opencode:/home/coder/.cache/oh-my-opencode"

# MCP authentication directory (optional)
[ -d "$HOME/.mcp-auth" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.mcp-auth:/home/coder/.mcp-auth:ro"

# Gradle properties (optional)
[ -f "$HOME/.gradle/gradle.properties" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.gradle/gradle.properties:/home/coder/.gradle/gradle.properties:ro"

# NPM configuration (optional)
[ -f "$HOME/.npmrc" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.npmrc:/home/coder/.npmrc:ro"

# Custom mounts and env vars from config
# (Already built by build_mount_args and build_env_args above)

# Run OpenCode in Docker
docker run -it --rm \
    --name opencode-dockerized \
    --network host \
    --security-opt no-new-privileges:true \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e TERM="${TERM:-xterm-256color}" \
    $VOLUME_ARGS \
    "${DOCKER_MOUNT_ARGS[@]}" \
    "${DOCKER_ENV_ARGS[@]}" \
    "$IMAGE_NAME" \
    opencode
