# Agent Guidelines for OpenCode Dockerized

## Project Overview
Shell script-based Docker wrapper for running OpenCode in secure, isolated containers with controlled project access.

## Build/Test Commands
```bash
./opencode-dockerized.sh build          # Build Docker image
./opencode-dockerized.sh auth           # Authenticate OpenCode (no local install needed)
./opencode-dockerized.sh run [DIR]      # Run OpenCode (default: current dir)
./opencode-dockerized.sh update         # Update OpenCode version
./setup.sh                              # Initialize config directories
chmod +x *.sh                           # Fix script permissions if needed
bash -n script.sh                       # Test shell script syntax
```

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` and `set -e` at start for error handling
- Quote all variables: `"$variable"` not `$variable`; use `$()` not backticks
- Use absolute paths: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Function names: `check_docker()`, `build_image()`, `print_error()` (snake_case)
- Color codes: RED, GREEN, YELLOW, BLUE with NC reset for user messages
- Check prerequisites before operations (e.g., `check_docker` before Docker commands)
- Redirect stderr for expected failures: `2>/dev/null || true`

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
