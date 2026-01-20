#!/bin/bash

# Setup script to initialize OpenCode configuration
# This helps new users get started quickly

set -e

# Source the shared config module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config-lib.sh"

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
ensure_dir "$HOME/.mcp-auth"

# Check/create OpenCode config files
ensure_file "$HOME/.config/opencode/opencode.json" '{}'

# ============================================
# Custom Configuration Setup
# ============================================

prompt_config_mode

# Handle config setup based on mode
if [ "$CONFIG_MODE" = "skip" ]; then
    echo ""
    echo "Skipping custom configuration setup."
    echo "You can run setup.sh again later to configure custom mounts and environment variables."
elif [ "$CONFIG_MODE" = "append" ] || [ "$CONFIG_MODE" = "overwrite" ]; then
    # Load existing config if appending
    [ "$CONFIG_MODE" = "append" ] && load_config
    
    # Interactive prompts
    prompt_custom_mounts
    prompt_env_vars
    
    # Save configuration
    save_config
    print_config
elif [ "$CONFIG_MODE" = "new" ]; then
    # New configuration
    read -p "Would you like to configure custom mounts and environment variables now? (y/N): " -r setup_custom
    
    if [[ "$setup_custom" =~ ^[Yy]$ ]]; then
        prompt_custom_mounts
        prompt_env_vars
        
        if [ ${#CUSTOM_MOUNTS[@]} -gt 0 ] || [ ${#CUSTOM_ENV_VARS[@]} -gt 0 ]; then
            save_config
            print_config
        else
            config_info "No custom configuration added."
        fi
    else
        # Create empty config for future use
        init_config_file
        config_info "You can run setup.sh again later to configure custom mounts and environment variables."
    fi
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
