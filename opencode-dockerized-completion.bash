#!/bin/bash

# Bash completion for opencode-dockerized.sh
# Source this file in your ~/.bashrc or install system-wide

_opencode_dockerized() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="run auth build update version help --help -h"

    case "${prev}" in
        run)
            # Complete directory paths for run command
            COMPREPLY=( $(compgen -d -- "${cur}") )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
}

complete -F _opencode_dockerized opencode-dockerized.sh
complete -F _opencode_dockerized ./opencode-dockerized.sh