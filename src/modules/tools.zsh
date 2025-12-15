# =============================================================================
# TOOL INITIALIZATIONS
# =============================================================================
# These contain dynamic evals and cannot be cached

# -----------------------------------------------------------------------------
# zoxide (smart cd replacement)
# -----------------------------------------------------------------------------
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# -----------------------------------------------------------------------------
# fzf keybindings
# -----------------------------------------------------------------------------
# Homebrew location (macOS)
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh

# Alternative location (Linux or manual install)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -----------------------------------------------------------------------------
# thefuck (command correction)
# -----------------------------------------------------------------------------
if command -v thefuck &> /dev/null; then
    eval $(thefuck --alias)
fi

# -----------------------------------------------------------------------------
# iTerm2 shell integration
# -----------------------------------------------------------------------------
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# -----------------------------------------------------------------------------
# NVM (Node Version Manager)
# -----------------------------------------------------------------------------
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# -----------------------------------------------------------------------------
# SDKMAN (must be near the end)
# -----------------------------------------------------------------------------
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# -----------------------------------------------------------------------------
# Local environment (if exists)
# -----------------------------------------------------------------------------
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
