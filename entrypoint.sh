#!/bin/bash
set -e

# This script runs as root and handles UID/GID mapping before switching to coder user

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
exec setpriv --reuid=coder --regid=coder --init-groups "$@"
