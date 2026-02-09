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

# Function to ensure at least one of the files exists
# Creates the first file with default content if none exist
ensure_any_file() {
    local default_content="$1"
    shift
    local files=("$@")
    
    # Check if any file already exists
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓${NC} Config file exists: $file"
            return 0
        fi
    done
    
    # None exist, create the first one
    local first_file="${files[0]}"
    echo -e "${YELLOW}Creating file: $first_file${NC}"
    mkdir -p "$(dirname "$first_file")"
    echo "$default_content" > "$first_file"
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
ensure_any_file '{}' "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.jsonc"

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
