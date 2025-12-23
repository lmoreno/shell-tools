#!/usr/bin/env bash
# =============================================================================
# shell-tools bash initialization
# =============================================================================
# This file is sourced from ~/.bashrc to auto-switch to zsh
# Keep logic here (not in .bashrc) so updates are automatic
#
# Usage: Add this line to your ~/.bashrc:
#   [[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh
# =============================================================================

# Only switch to zsh in interactive shells
# This prevents breaking non-interactive SSH commands like: ssh server "command"
case $- in
    *i*)
        # Interactive shell - switch to zsh if available
        if command -v zsh >/dev/null 2>&1; then
            export SHELL=$(command -v zsh)
            exec zsh
        fi
        ;;
esac
