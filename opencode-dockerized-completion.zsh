#compdef opencode-dockerized.sh

# Zsh completion for opencode-dockerized.sh
# Source this file in your ~/.zshrc or place in /usr/local/share/zsh/site-functions/

_opencode_dockerized() {
    local -a commands
    commands=(
        'run:Run OpenCode in Docker (default: current directory)'
        'auth:Run OpenCode authentication (opencode auth login)'
        'build:Build the Docker image'
        'update:Update OpenCode to the latest version'
        'version:Show OpenCode version in the container'
        'help:Show help message'
    )

    _arguments -C \
        '1: :->cmds' \
        '*:: :->args'

    case $state in
        cmds)
            _describe -t commands 'opencode-dockerized command' commands
            ;;
        args)
            case $words[2] in
                run)
                    _files -/
                    ;;
            esac
            ;;
    esac
}

compdef _opencode_dockerized opencode-dockerized.sh
compdef _opencode_dockerized ocd