# OpenCode Dockerized - Secure Sandbox Environment

Run OpenCode in a secure, isolated Docker container with controlled access to your projects. This setup provides OpenCode with just enough access to be useful while maintaining strong security boundaries.

## Table of Contents

- [Security Features](#-security-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Portability & Sharing](#-portability--sharing)
- [Advanced Usage](#-advanced-usage)
- [Troubleshooting](#-troubleshooting)
- [File Reference](#-file-reference)

## 🔒 Security Features

- **Isolated Environment** - OpenCode only has access to the mounted project directory
- **Read-only Configuration** - All configuration files are mounted read-only (except session storage)
- **Session Persistence** - Logs and project session data persist across container restarts
- **Non-root User** - Runs as non-root user with UID/GID matching your host user
- **Limited Blast Radius** - Commands like `rm -rf .` only affect the project directory, not your entire system

## 📋 Prerequisites

1. **Docker** installed and running
2. **OpenCode configuration** on your host machine (optional):
   - `~/.config/opencode/opencode.json` - OpenCode settings
   - `~/.local/share/opencode/` - Authentication, logs, sessions, and project data
   - `~/.config/opencode/agent/` - Custom agents
3. **Optional configuration files**:
   - `~/.gradle/gradle.properties` - Gradle configuration
   - `~/.npmrc` - NPM configuration

If you don't have OpenCode configured yet, you can run `opencode auth login` inside the container after first launch.

## 🚀 Quick Start

### First-Time Setup

```bash
# 1. Navigate to the setup directory
cd /path/to/opencode-dockerized

# 2. Run setup script (creates config directories if needed)
./setup.sh

# 3. Build the Docker image
./opencode-dockerized.sh build

# 4. Run OpenCode in your project
./opencode-dockerized.sh run
# or
./opencode-dockerized.sh run /path/to/your/project
```

### Daily Usage

```bash
# Run in current directory
./opencode-dockerized.sh run

# Run in specific project
./opencode-dockerized.sh run ~/projects/my-app

# Check version
./opencode-dockerized.sh version

# Update OpenCode
./opencode-dockerized.sh update
```

### Create an Alias (Recommended)

```bash
# For Bash users - add to ~/.bashrc
echo "alias ocd='/path/to/opencode-dockerized/opencode-dockerized.sh run'" >> ~/.bashrc
source ~/.bashrc

# For Zsh users - add to ~/.zshrc
echo "alias ocd='/path/to/opencode-dockerized/opencode-dockerized.sh run'" >> ~/.zshrc
source ~/.zshrc

# Then use it anywhere
cd ~/my-project
ocd
```

### Shell Completion (Optional)

Autocompletion support is available for both Bash and Zsh:

**For Bash:**
```bash
# Source the completion file
source /path/to/opencode-dockerized/opencode-dockerized-completion.bash

# Or add to ~/.bashrc for permanent installation
echo "source /path/to/opencode-dockerized/opencode-dockerized-completion.bash" >> ~/.bashrc
```

**For Zsh:**
```bash
# Source the completion file
source /path/to/opencode-dockerized/opencode-dockerized-completion.zsh

# Or add to ~/.zshrc for permanent installation
echo "source /path/to/opencode-dockerized/opencode-dockerized-completion.zsh" >> ~/.zshrc

# For system-wide installation (requires sudo)
sudo cp /path/to/opencode-dockerized/opencode-dockerized-completion.zsh /usr/local/share/zsh/site-functions/_opencode-dockerized
```

After installation, you'll get:
- ✓ Command completion (`run`, `build`, `update`, `version`, `help`)
- ✓ Directory completion for the `run` command
- ✓ Helpful descriptions for each command
- ✓ Works with both `opencode-dockerized.sh` and the `ocd` alias

## 📖 Usage

### Available Commands

```bash
./opencode-dockerized.sh build          # Build Docker image
./opencode-dockerized.sh run [DIR]      # Run OpenCode (default: current dir)
./opencode-dockerized.sh update         # Update OpenCode version
./opencode-dockerized.sh version        # Show version
./opencode-dockerized.sh help           # Show help
```

### Alternative Runners

**Simple Runner**:
```bash
./run-simple.sh /path/to/your/project
```

### Inside the Container

Once OpenCode starts:

```bash
# Initialize OpenCode for the project
/init

# Ask questions about your code
How is authentication handled in @src/auth.ts

# Make changes
Add error handling to the login function

# Create plans before implementing
<TAB>  # Switch to Plan mode
Let's add a new feature for user profiles
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file (copy from `.env.example`):

```bash
# Project directory to work on
PROJECT_DIR=/home/youruser/projects/myproject

# User/Group IDs (auto-detected by default)
HOST_UID=1000
HOST_GID=1000

# Terminal type
TERM=xterm-256color
```

### Volume Mounts

| Host Path | Container Path | Mode | Purpose |
|-----------|---------------|------|---------|
| `$PROJECT_DIR` | `/workspace` | read-write | Your project files |
| `~/.config/opencode/opencode.json` | `/home/coder/.config/opencode/opencode.json` | read-only | OpenCode settings |
| `~/.config/opencode/agent/` | `/home/coder/.config/opencode/agent/` | read-only | Custom agents |
| `~/.local/share/opencode/` | `/home/coder/.local/share/opencode/` | read-write | Auth, logs, sessions, storage |
| `~/.cache/opencode/` | `/home/coder/.cache/opencode/` | read-write | Provider package cache |
| `~/.gradle/gradle.properties` | `/home/coder/.gradle/gradle.properties` | read-only | Gradle config |
| `~/.npmrc` | `/home/coder/.npmrc` | read-only | NPM config |

## 🌍 Portability & Sharing

**This setup is fully portable!** It uses `$HOME` instead of hardcoded paths and works across different users and systems.

### How to Share

**Method 1: Git Repository (Recommended)**

```bash
git init
git add .
git commit -m "Initial OpenCode Docker setup"
git remote add origin <your-repo-url>
git push -u origin main
```

Users can then:
```bash
git clone <your-repo-url>
cd opencode-dockerized
./setup.sh
./opencode-dockerized.sh build
./opencode-dockerized.sh run
```

**Method 2: Archive Distribution**

```bash
tar -czf opencode-docker.tar.gz opencode-dockerized/
```

Users extract and run:
```bash
tar -xzf opencode-docker.tar.gz
cd opencode-dockerized
./setup.sh
./opencode-dockerized.sh build
```

**Method 3: Docker Hub**

```bash
docker build -t yourusername/opencode-dockerized:latest .
docker push yourusername/opencode-dockerized:latest
```

Update scripts to use `yourusername/opencode-dockerized:latest`

### Platform Compatibility

- **Linux**: Works out of the box
- **macOS**: Works with Docker Desktop
- **Windows (WSL2)**: Works in WSL2 terminal
- **Windows (Native)**: Use WSL2 instead

### What to Share

✅ Safe to share:
- Dockerfile
- Shell scripts
- Documentation
- .gitignore

❌ Never share:
- `.env` file with secrets
- Personal `auth.json`
- Personal `opencode.json` (may contain API keys)
- Personal `.gradle/gradle.properties`
- Personal `.npmrc`

## 🔍 Advanced Usage

### Adding Additional Tools

Edit `Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    ca-certificates \
    python3 \
    python3-pip \
    jq \
    && rm -rf /var/lib/apt/lists/*
```

### Using Different Base Images

```dockerfile
# For Alpine (smaller size)
FROM node:20-alpine

# For specific Node version
FROM node:22-slim

# For Ubuntu-based
FROM ubuntu:22.04
# (then install Node.js manually)
```

## 🐛 Troubleshooting

### Permission Denied on Scripts

```bash
chmod +x opencode-dockerized.sh run-simple.sh setup.sh entrypoint.sh
```

### Config Files Not Found

```bash
# Run setup script
./setup.sh

# Or manually create
mkdir -p ~/.config/opencode ~/.local/share/opencode
echo '{}' > ~/.config/opencode/opencode.json
```

### Permission Issues with Files

```bash
# Check if UID/GID match
echo "UID: $(id -u), GID: $(id -g)"

# Rebuild image
./opencode-dockerized.sh build
```

### Container Won't Start

```bash
# Check Docker is running
docker info

# View container logs
docker logs opencode-dockerized

# Remove and rebuild
docker rm -f opencode-dockerized
./opencode-dockerized.sh build
```

### OpenCode Not Updating

```bash
# Force rebuild without cache
docker build --no-cache -t opencode-dockerized:latest .

# Or use update command
./opencode-dockerized.sh update
```

## 📁 File Reference

### Core Files

- **`Dockerfile`** - Container image definition (Node.js 20 + OpenCode)
- **`entrypoint.sh`** - UID/GID mapping for file permissions

### User Scripts

- **`opencode-dockerized.sh`** - Main wrapper with all features (build, run, update, version, help)
- **`run-simple.sh`** - Simplified runner script
- **`setup.sh`** - First-time initialization (creates config directories)

### Shell Completion

- **`opencode-dockerized-completion.bash`** - Bash shell completion script
- **`opencode-dockerized-completion.zsh`** - Zsh shell completion script

### Configuration

- **`.env.example`** - Template for environment variables
- **`.gitignore`** - Excludes sensitive files from Git

### How It Works

1. **Base Image**: Uses Node.js 20 slim for minimal footprint
2. **OpenCode Installation**: Installs latest OpenCode via npm
3. **User Management**: Creates non-root `coder` user
4. **Entrypoint**: Adjusts UID/GID to match host user
5. **Volume Mounting**: Mounts only necessary directories with appropriate permissions

### The Blast Radius Concept

If OpenCode runs a dangerous command like `rm -rf .`:

- ❌ **Without Docker**: Could delete your entire home directory
- ✅ **With Docker**: Only affects `/workspace` (your project)

This significantly reduces risk while maintaining full functionality.

## 📚 Additional Resources

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode GitHub Repository](https://github.com/sst/opencode)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

## ⚠️ Important Notes

1. **Network Access**: Container uses host network mode by default for convenience.
2. **Configuration Updates**: Config files are read-only. Modify on host and restart container.
3. **Persistent Data**: Only files in mounted project directory persist.
4. **Not a Replacement for Caution**: Review OpenCode's actions, especially with `--allow-all-tools`.

---

**Made with 🔒 by developers who like AI but trust carefully**
