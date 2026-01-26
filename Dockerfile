# Use Debian slim as lightweight Linux base
# Note: We only install Docker CLI to use host's Docker daemon via mounted socket
FROM debian:bookworm-slim

# Install base dependencies and useful CLI tools for coding agents
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    ca-certificates \
    sudo \
    zip \
    unzip \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    ripgrep \
    fd-find \
    jq \
    tree \
    less \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI only (uses host Docker daemon via mounted socket)
# We don't need docker-ce (daemon) or containerd.io since we use the host's Docker
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
# Note: Docker socket group membership is handled dynamically in entrypoint.sh
# based on the host's actual Docker socket GID
RUN useradd -m -s /bin/bash -u 1000 coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install SDKMAN as coder user
USER coder
WORKDIR /home/coder
RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source /home/coder/.sdkman/bin/sdkman-init.sh && \
    sdk install java 21.0.5-tem && \
    sdk default java 21.0.5-tem"

# Install NVM and Node.js LTS as coder user
ENV NVM_DIR="/home/coder/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    bash -c "source $NVM_DIR/nvm.sh && \
    nvm install --lts && \
    nvm alias default node && \
    nvm use default"

# Install uv (Python package manager) as coder user
# See: https://docs.astral.sh/uv/getting-started/installation/
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Add nvm, node, sdkman, and uv to PATH
# Note: Node version path will be determined at runtime by nvm
ENV PATH="$NVM_DIR/versions/node/default/bin:/home/coder/.local/bin:/home/coder/.sdkman/candidates/java/current/bin:$PATH"
ENV JAVA_HOME="/home/coder/.sdkman/candidates/java/current"

# Install OpenCode globally
# Use ARG to force cache invalidation on each build
ARG OPENCODE_BUILD_TIME
RUN bash -c "source $NVM_DIR/nvm.sh && npm install -g opencode-ai@latest"

# Switch back to root for entrypoint setup
USER root

# Create necessary directories with proper permissions
RUN mkdir -p /home/coder/.config/opencode && \
    mkdir -p /home/coder/.local/share/opencode && \
    mkdir -p /home/coder/.cache/opencode && \
    mkdir -p /home/coder/.gradle && \
    mkdir -p /home/coder/.npm && \
    mkdir -p /home/coder/.m2 && \
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
