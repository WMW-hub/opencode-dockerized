# Agent Guidelines for OpenCode Dockerized

## Project Overview

Shell script-based Docker wrapper for running OpenCode (AI coding assistant) in secure, isolated containers. Provides a sandboxed environment limiting OpenCode's blast radius to only the mounted project directory. Includes full support for [Oh My OpenCode](https://github.com/code-yeongyu/oh-my-opencode) plugin.

**Key Components:**
- `opencode-dockerized.sh` - Main wrapper script with build, run, auth, update commands
- `Dockerfile` - Container image (Debian + Node.js/NVM + Java/SDKMAN + Bun + ast-grep + OpenCode)
- `entrypoint.sh` - UID/GID mapping for host file permissions
- `setup.sh` - First-time initialization for config directories
- `run-simple.sh` - Simplified alternative runner script
- Shell completion scripts for Bash and Zsh

**Container Tools:**
- Node.js (via NVM), Java 21 (via SDKMAN), Python tooling (via uv)
- Bun, ast-grep, tmux, lsof (for oh-my-opencode)
- Docker CLI, ripgrep, fd-find, jq, git

## Build/Test/Lint Commands

```bash
# Core Operations
./opencode-dockerized.sh build          # Build Docker image
./opencode-dockerized.sh auth           # Authenticate OpenCode
./opencode-dockerized.sh run [DIR]      # Run OpenCode (default: current dir)
./opencode-dockerized.sh update         # Update OpenCode to latest version
./opencode-dockerized.sh version        # Show OpenCode version in container
./opencode-dockerized.sh help           # Show help message

# Setup
./setup.sh                              # Initialize config directories
chmod +x *.sh                           # Fix script permissions if needed

# Alternative Runner
./run-simple.sh [DIR]                   # Simpler runner without all features

# Testing & Validation
bash -n script.sh                       # Syntax check a shell script
bash -n *.sh                            # Syntax check all shell scripts
shellcheck script.sh                    # Lint shell script (if installed)

# Docker Operations
docker build -t opencode-dockerized:latest .                    # Manual build
docker build --no-cache -t opencode-dockerized:latest .         # Force rebuild
docker run --rm opencode-dockerized:latest opencode --version   # Check version
```

## Code Style Guidelines

### Shell Scripts (Bash)

**File Header:**
```bash
#!/bin/bash
set -e  # Exit on first error
```

**Variable Handling:**
- Always quote variables: `"$variable"` not `$variable`
- Use `$()` for command substitution, not backticks
- Use absolute paths: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Convert relative to absolute: `project_dir="$(cd "$project_dir" && pwd)"`

**Function & Variable Naming:**
- Functions: snake_case - `check_docker()`, `build_image()`, `print_error()`
- Constants: UPPER_SNAKE - `IMAGE_NAME`, `SCRIPT_DIR`
- Local variables: lower_snake - `project_dir`, `volume_args`

**Color Output Pattern:**
```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_error() { echo -e "${RED}✗${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
```

**Error Handling:**
- Redirect stderr for expected failures: `2>/dev/null || true`
- Check prerequisites before operations (e.g., `check_docker` before Docker commands)
- Use explicit error messages with `print_error()` before `exit 1`

**Conditionals:**
```bash
[ -f "$file" ] && volume_args="$volume_args -v $file:/path:ro"  # File check
[ -d "$dir" ] && volume_args="$volume_args -v $dir:/path"       # Directory check
[ -S "$socket" ] && echo "Socket exists"                         # Socket check

if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi
```

**Here-doc for Multi-line Output:**
```bash
show_help() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]
Commands:
    run [DIR]    Run OpenCode (default: current directory)
    build        Build the Docker image
EOF
}
```

### Dockerfile Best Practices

- Base image: `debian:bookworm-slim` (specific version, not latest)
- Clean apt cache in same RUN layer: `&& rm -rf /var/lib/apt/lists/*`
- Docker CLI only (not daemon): install `docker-ce-cli` not `docker-ce`
- Install dev tools as non-root user (coder): NVM, SDKMAN, uv, Bun, ast-grep
- Create non-root user: `useradd -m -s /bin/bash -u 1000 coder`
- Use official installers from trusted sources (get.sdkman.io, bun.sh, etc.)
- Document architecture decisions in comments

### Security Conventionshttps://github.com/glennvdv/opencode-dockerized/pull/2/changes

**Volume Mounts:**
- Config files: read-only (`:ro`) - `~/.config/opencode/`
- Data directories: read-write - `~/.local/share/opencode/`, `~/.cache/`
- Only mount what's necessary

**Sensitive Files (never commit):**
- `.env`, `auth.json`, `*.pem`, `*.key`, credentials

**Docker Socket:**
- Mount host socket: `-v /var/run/docker.sock:/var/run/docker.sock`
- No privileged mode needed
- Handle socket GID dynamically in entrypoint

**Container Execution:**
- Run as non-root user (coder) inside container
- Map UID/GID to match host user via entrypoint
- Use `--rm` flag for automatic cleanup
- Use `--network host` for simplicity

## Volume Mounts Reference

| Host Path | Container Path | Mode | Purpose |
|-----------|---------------|------|---------|
| `$PROJECT_DIR` | `/workspace` | rw | Project files |
| `~/.config/opencode/` | `/home/coder/.config/opencode/` | ro | Config, skills, commands, agents |
| `~/.local/share/opencode/` | `/home/coder/.local/share/opencode/` | rw | Auth, sessions, storage |
| `~/.cache/opencode/` | `/home/coder/.cache/opencode/` | rw | Provider cache |
| `~/.cache/oh-my-opencode/` | `/home/coder/.cache/oh-my-opencode/` | rw | Oh My OpenCode cache |
| `/var/run/docker.sock` | `/var/run/docker.sock` | rw | Docker socket |

## File Organization

```
project/
├── AGENTS.md                           # Agent guidelines (this file)
├── README.md                           # User documentation
├── Dockerfile                          # Container image definition
├── entrypoint.sh                       # Container entrypoint (UID/GID mapping)
├── opencode-dockerized.sh              # Main wrapper script
├── run-simple.sh                       # Simplified alternative runner
├── setup.sh                            # First-time setup script
├── opencode-dockerized-completion.bash # Bash completion
├── opencode-dockerized-completion.zsh  # Zsh completion
├── .env.example                        # Environment variable template
└── .gitignore                          # Git ignore patterns
```

## Naming Conventions

### Shared Module (config-lib.sh)
- Provides reusable functions sourced by multiple scripts
- Define color codes with defaults: `: "${RED:='\033[0;31m'}"`
- Check if caller has logging functions before using them: `type print_info >/dev/null 2>&1`
- Use module logging functions with fallbacks for standalone use
- Global arrays for state: `declare -a CUSTOM_MOUNTS=()`
- Document all exported functions with comments
- INI-style config format: `key.name=value` (not YAML or JSON to avoid dependencies)

### Dockerfile
- Use specific versions: `debian:bookworm-slim` not `latest`
- Install Docker CLI only (not daemon): `docker-ce-cli` not `docker-ce`
- Clean up in same RUN layer: `&& rm -rf /var/lib/apt/lists/*`
- Non-root user with UID/GID mapping via entrypoint
- Document security/architecture in comments

### Security
- Mount configs read-only (`:ro`), never commit `.env` or `auth.json`
- Use host Docker socket (no privileged mode or Docker-in-Docker)
- Container uses non-root user with host UID/GID matching
- Allow users to mount custom paths read-only by default
- Only pass environment variables explicitly listed in config

| Type | Convention | Example |
|------|------------|---------|
| Shell scripts | kebab-case.sh | `opencode-dockerized.sh` |
| Functions | snake_case | `check_docker()`, `build_image()` |
| Constants | UPPER_SNAKE | `IMAGE_NAME`, `SCRIPT_DIR` |
| Local variables | lower_snake | `project_dir`, `volume_args` |
| Docker images | kebab-case:tag | `opencode-dockerized:latest` |
| Container names | kebab-case-suffix | `opencode-myproject-abc123` |
