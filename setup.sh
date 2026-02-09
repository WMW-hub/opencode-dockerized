#!/bin/bash

# Setup script to initialize OpenCode configuration
# This helps new users get started quickly

set -e

# Source the shared config module (provides colors, logging, and config functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-lib.sh"

# Define colors before use (config-lib.sh provides defaults via : "${VAR:=...}")
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

interactive_config_setup

# Shell completions setup
echo ""
echo -e "${BLUE}Shell Completions Setup${NC}"
echo "Would you like to install shell completions? (enables tab completion for commands)"
read -r -p "Install completions? (y/n): " install_completions

if [[ "$install_completions" =~ ^[Yy]$ ]]; then
    # Detect shell
    detected_shell=""
    if [ -n "$BASH_VERSION" ]; then
        detected_shell="bash"
    elif [ -n "$ZSH_VERSION" ]; then
        detected_shell="zsh"
    fi

    echo ""
    echo "Detected shell: ${detected_shell:-unknown}"
    echo "Available completions:"
    echo "  1) bash"
    echo "  2) zsh"
    echo "  3) both"
    echo "  4) skip"
    read -r -p "Select option (1-4): " shell_choice

    install_bash_completion() {
        local bash_rc="$HOME/.bashrc"
        local completion_line="[ -f \"$SCRIPT_DIR/completions/bash.sh\" ] && source \"$SCRIPT_DIR/completions/bash.sh\""
        
        if grep -qF "$completion_line" "$bash_rc" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Bash completion already configured in ~/.bashrc"
        else
            echo "" >> "$bash_rc"
            echo "# OpenCode Dockerized completion" >> "$bash_rc"
            echo "$completion_line" >> "$bash_rc"
            echo -e "${GREEN}✓${NC} Added bash completion to ~/.bashrc"
            echo -e "${YELLOW}  Run: source ~/.bashrc${NC}"
        fi
    }

    install_zsh_completion() {
        local zsh_rc="$HOME/.zshrc"
        local completion_line="[ -f \"$SCRIPT_DIR/completions/zsh.sh\" ] && source \"$SCRIPT_DIR/completions/zsh.sh\""
        
        if grep -qF "$completion_line" "$zsh_rc" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Zsh completion already configured in ~/.zshrc"
        else
            echo "" >> "$zsh_rc"
            echo "# OpenCode Dockerized completion" >> "$zsh_rc"
            echo "$completion_line" >> "$zsh_rc"
            echo -e "${GREEN}✓${NC} Added zsh completion to ~/.zshrc"
            echo -e "${YELLOW}  Run: source ~/.zshrc${NC}"
        fi
    }

    case "$shell_choice" in
        1)
            install_bash_completion
            ;;
        2)
            install_zsh_completion
            ;;
        3)
            install_bash_completion
            install_zsh_completion
            ;;
        4)
            echo "Skipping completions installation."
            ;;
        *)
            echo -e "${YELLOW}Invalid choice, skipping completions.${NC}"
            ;;
    esac
else
    echo "Skipping completions installation."
fi

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
