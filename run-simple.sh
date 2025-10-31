#!/bin/bash

# Alternative simple runner without docker-compose
# This provides a more portable option

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="opencode-dockerized:latest"

# Get project directory (default to current directory)
PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Build image if it doesn't exist
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Build volume mount arguments - only mount files that exist
VOLUME_ARGS="-v $PROJECT_DIR:/workspace"

# OpenCode configuration (optional)
[ -f "$HOME/.config/opencode/opencode.json" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.config/opencode/opencode.json:/home/coder/.config/opencode/opencode.json:ro"

# OpenCode agent (optional)
[ -d "$HOME/.config/opencode/agent" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.config/opencode/agent:/home/coder/.config/opencode/agent:ro"

# OpenCode data directory (read-write for auth, logs, sessions, storage)
[ -d "$HOME/.local/share/opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.local/share/opencode:/home/coder/.local/share/opencode"

# OpenCode provider package cache (optional)
[ -d "$HOME/.cache/opencode" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.cache/opencode:/home/coder/.cache/opencode"

# Gradle properties (optional)
[ -f "$HOME/.gradle/gradle.properties" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.gradle/gradle.properties:/home/coder/.gradle/gradle.properties:ro"

# NPM configuration (optional)
[ -f "$HOME/.npmrc" ] && \
    VOLUME_ARGS="$VOLUME_ARGS -v $HOME/.npmrc:/home/coder/.npmrc:ro"

# Run OpenCode in Docker
docker run -it --rm \
    --name opencode-dockerized \
    --network host \
    --security-opt no-new-privileges:true \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -e TERM="${TERM:-xterm-256color}" \
    $VOLUME_ARGS \
    "$IMAGE_NAME" \
    opencode
