#!/bin/bash

# Setup script to initialize OpenCode configuration
# This helps new users get started quickly

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}OpenCode Docker Setup${NC}"
echo "================================"
echo ""

# Function to create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        echo -e "${YELLOW}Creating directory: $1${NC}"
        mkdir -p "$1"
    else
        echo -e "${GREEN}✓${NC} Directory exists: $1"
    fi
}

# Function to create file if it doesn't exist
ensure_file() {
    if [ ! -f "$1" ]; then
        echo -e "${YELLOW}Creating file: $1${NC}"
        mkdir -p "$(dirname "$1")"
        echo "$2" > "$1"
    else
        echo -e "${GREEN}✓${NC} File exists: $1"
    fi
}

echo "Checking OpenCode configuration..."
echo ""

# Check/create OpenCode directories
ensure_dir "$HOME/.config/opencode"
ensure_dir "$HOME/.config/opencode/agent"
ensure_dir "$HOME/.config/opencode/plugin"
ensure_dir "$HOME/.config/opencode/command"
ensure_dir "$HOME/.local/share/opencode"
ensure_dir "$HOME/.cache/opencode"
ensure_dir "$HOME/.cache/oh-my-opencode"
ensure_dir "$HOME/.mcp-auth"

# Check/create OpenCode config files
ensure_file "$HOME/.config/opencode/opencode.json" '{}'

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Build the Docker image:"
echo "     ./opencode-dockerized.sh build"
echo ""
echo "  2. Authenticate with your LLM provider (no local OpenCode needed!):"
echo "     ./opencode-dockerized.sh auth"
echo ""
echo "  3. Run OpenCode in your project:"
echo "     ./opencode-dockerized.sh run /path/to/your/project"
echo ""
echo "Note: If you already have OpenCode configured locally, your"
echo "      existing authentication will be automatically available."
echo ""
