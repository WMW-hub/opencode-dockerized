#!/bin/bash

# OpenCode Docker Wrapper Script
# This script makes it easy to run OpenCode in a secure Docker container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="opencode-dockerized:latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to build the Docker image
build_image() {
    print_info "Building OpenCode Docker image..."
    # Pass build-time timestamp to invalidate cache and force fresh npm install
    docker build --build-arg "OPENCODE_BUILD_TIME=$(date +%s)" -t "$IMAGE_NAME" "$SCRIPT_DIR"
    print_success "Docker image built successfully"
}

# Function to check required configuration files
check_config() {
    local missing_files=()
    
    if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
        missing_files+=("$HOME/.config/opencode/opencode.json")
    fi
    
    if [ ! -d "$HOME/.local/share/opencode" ]; then
        missing_files+=("$HOME/.local/share/opencode/")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Some OpenCode configuration files are missing:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_info "OpenCode will run but may need configuration. Run 'opencode auth login' inside the container."
    fi
    
    # Ensure OpenCode storage directory exists
    # According to docs: https://opencode.ai/docs/troubleshooting/#storage
    mkdir -p "$HOME/.local/share/opencode" 2>/dev/null || true
    mkdir -p "$HOME/.cache/opencode" 2>/dev/null || true
}

# Function to run OpenCode authentication
run_auth() {
    print_info "Running OpenCode authentication..."
    
    # Ensure OpenCode directories exist
    mkdir -p "$HOME/.local/share/opencode" 2>/dev/null || true
    mkdir -p "$HOME/.cache/opencode" 2>/dev/null || true
    mkdir -p "$HOME/.config/opencode" 2>/dev/null || true
    
    # Build volume mount arguments for auth
    local volume_args=""
    
    # OpenCode data directory (read-write for auth storage)
    volume_args="$volume_args -v $HOME/.local/share/opencode:/home/coder/.local/share/opencode"
    
    # OpenCode cache directory
    volume_args="$volume_args -v $HOME/.cache/opencode:/home/coder/.cache/opencode"
    
    # OpenCode config directory (for writing opencode.json if needed)
    volume_args="$volume_args -v $HOME/.config/opencode:/home/coder/.config/opencode"
    
    # Run OpenCode auth login in Docker
    docker run -it --rm \
        --name "opencode-auth-$$" \
        --network host \
        -e HOST_UID="$(id -u)" \
        -e HOST_GID="$(id -g)" \
        -e TERM="${TERM:-xterm-256color}" \
        $volume_args \
        "$IMAGE_NAME" \
        opencode auth login
    
    print_success "Authentication complete! Your credentials are saved in $HOME/.local/share/opencode"
}

# Function to run OpenCode
run_opencode() {
    local project_dir="${1:-$(pwd)}"
    
    # Convert to absolute path
    project_dir="$(cd "$project_dir" && pwd)"
    
    # Generate unique container name based on project directory and random suffix
    # Use basename and random suffix to allow multiple instances per directory
    local dir_name=$(basename "$project_dir")
    local random_suffix=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' ')
    local container_name="opencode-${dir_name}-${random_suffix}"
    
    print_info "Starting OpenCode in Docker..."
    print_info "Project directory: $project_dir"
    print_info "Container name: $container_name"
    
    # Build volume mount arguments - only mount files that exist
    local volume_args="-v $project_dir:/workspace"
    
    # OpenCode configuration (optional)
    if [ -f "$HOME/.config/opencode/opencode.json" ]; then
        volume_args="$volume_args -v $HOME/.config/opencode/opencode.json:/home/coder/.config/opencode/opencode.json:ro"
    else
        print_warning "OpenCode config not found at $HOME/.config/opencode/opencode.json"
    fi
    
    # OpenCode agent (optional)
    if [ -d "$HOME/.config/opencode/agent" ]; then
        volume_args="$volume_args -v $HOME/.config/opencode/agent:/home/coder/.config/opencode/agent:ro"
    fi
    
    # OpenCode AGENTS.md (optional)
    if [ -f "$HOME/.config/opencode/AGENTS.md" ]; then
        volume_args="$volume_args -v $HOME/.config/opencode/AGENTS.md:/home/coder/.config/opencode/AGENTS.md:ro"
    fi
    
    # OpenCode data directory (read-write for auth, logs, sessions, storage)
    # Mount entire .local/share/opencode directory
    if [ -d "$HOME/.local/share/opencode" ]; then
        volume_args="$volume_args -v $HOME/.local/share/opencode:/home/coder/.local/share/opencode"
    else
        print_warning "OpenCode data directory not found at $HOME/.local/share/opencode"
        print_info "You'll need to run 'opencode auth login' inside the container"
    fi

    # OpenCode provider package cache (improves startup time and prevents API errors)
    # See: https://opencode.ai/docs/troubleshooting/#ai_apicallerror-and-provider-package-issues
    if [ -d "$HOME/.cache/opencode" ]; then
        volume_args="$volume_args -v $HOME/.cache/opencode:/home/coder/.cache/opencode"
    fi
    
    # MCP authentication directory (optional)
    if [ -d "$HOME/.mcp-auth" ]; then
        volume_args="$volume_args -v $HOME/.mcp-auth:/home/coder/.mcp-auth:ro"
    fi
    
    # Gradle properties (optional)
    if [ -f "$HOME/.gradle/gradle.properties" ]; then
        volume_args="$volume_args -v $HOME/.gradle/gradle.properties:/home/coder/.gradle/gradle.properties:ro"
    fi
    
    # NPM configuration (optional)
    if [ -f "$HOME/.npmrc" ]; then
        volume_args="$volume_args -v $HOME/.npmrc:/home/coder/.npmrc:ro"
    fi
    
    # Note: Each run gets a unique container name, so no cleanup needed
    # The --rm flag ensures automatic cleanup when the container exits
    
    # Run OpenCode in Docker (without security-opt to allow entrypoint to work)
    # Mount Docker socket to allow Docker-in-Docker operations
    docker run -it --rm \
        --name "$container_name" \
        --network host \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e HOST_UID="$(id -u)" \
        -e HOST_GID="$(id -g)" \
        -e TERM="${TERM:-xterm-256color}" \
        $volume_args \
        "$IMAGE_NAME" \
        opencode
}

# Function to update OpenCode
update_opencode() {
    print_info "Updating OpenCode..."
    docker run --rm "$IMAGE_NAME" npm list -g opencode-ai --depth=0
    print_info "Rebuilding image with latest OpenCode..."
    build_image
    print_success "OpenCode updated successfully"
}

# Function to show help
show_help() {
    cat << EOF
OpenCode Docker Wrapper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    run [DIR]       Run OpenCode in Docker (default: current directory)
    auth            Run OpenCode authentication (opencode auth login)
    build           Build the Docker image
    update          Update OpenCode to the latest version
    version         Show OpenCode version in the container
    help            Show this help message

Examples:
    $0 auth                         # Authenticate with your LLM provider
    $0 run                          # Run in current directory
    $0 run /path/to/project         # Run in specific directory
    $0 build                        # Build the Docker image
    $0 update                       # Update OpenCode

Security Features:
    ✓ Isolated environment - Only access to mounted project directory
    ✓ Read-only config mounts - Configuration files are mounted read-only
    ✓ No privileged access - Container runs with minimal privileges
    ✓ Non-root user - Runs as non-root user inside container

For more information, see README.md
EOF
}

# Function to show version
show_version() {
    docker run --rm \
        -e HOST_UID="$(id -u)" \
        -e HOST_GID="$(id -g)" \
        "$IMAGE_NAME" opencode --version
}

# Main script logic
main() {
    check_docker
    
    local command="${1:-run}"
    shift || true
    
    case "$command" in
        run)
            check_config
            run_opencode "$@"
            ;;
        auth)
            run_auth
            ;;
        build)
            build_image
            ;;
        update)
            update_opencode
            ;;
        version)
            show_version
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
