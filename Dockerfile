# Use Node.js 20 LTS as base image for OpenCode
FROM node:20-slim

# Install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode globally
RUN npm install -g opencode-ai

# Create a non-root user that will match the host user
# The node image already has a user with UID 1000, so we need to handle this
RUN if id -u 1000 >/dev/null 2>&1; then \
        # If UID 1000 exists (node user), rename it to coder \
        existing_user=$(id -un 1000) && \
        usermod -l coder $existing_user && \
        groupmod -n coder $(id -gn 1000) && \
        usermod -d /home/coder -m coder; \
    else \
        # If UID 1000 doesn't exist, create the user \
        useradd -m -s /bin/bash -u 1000 coder; \
    fi && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create necessary directories with proper permissions
RUN mkdir -p /home/coder/.config/opencode && \
    mkdir -p /home/coder/.local/share/opencode && \
    mkdir -p /home/coder/.cache/opencode && \
    mkdir -p /home/coder/.gradle && \
    mkdir -p /home/coder/.npm && \
    chown -R coder:coder /home/coder

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint (runs as root, then switches to coder)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command is to run opencode
CMD ["opencode"]
