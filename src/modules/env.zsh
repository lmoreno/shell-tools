# =============================================================================
# PATH ADDITIONS
# =============================================================================

# Add trash to PATH (keg-only, not symlinked by Homebrew)
if [[ -d "/opt/homebrew/opt/trash/bin" ]]; then
    export PATH="/opt/homebrew/opt/trash/bin:$PATH"
fi

# =============================================================================
# PROMPT
# =============================================================================
# Simple, clean prompt if not already set or if using default broken prompt.
if [[ -z "$PROMPT" ]] || [[ "$PROMPT" == *"\u"* ]]; then
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
fi

# =============================================================================
# FZF CONFIGURATION
# =============================================================================

# Use fd for better file finding (if available)
if command -v fd &> /dev/null; then
    # Check common locations or just use 'fd'
    if [[ -x "/opt/homebrew/bin/fd" ]]; then
        export FZF_DEFAULT_COMMAND='/opt/homebrew/bin/fd --type file --hidden --follow --exclude .git'
    else
        export FZF_DEFAULT_COMMAND='fd --type file --hidden --follow --exclude .git'
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    
    if [[ -x "/opt/homebrew/bin/fd" ]]; then
        export FZF_ALT_C_COMMAND='/opt/homebrew/bin/fd --type directory --hidden --follow --exclude .git'
    else
        export FZF_ALT_C_COMMAND='fd --type directory --hidden --follow --exclude .git'
    fi
fi

# Better FZF defaults
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --preview "bat --color=always --style=numbers --line-range=:500 {}"
  --preview-window=right:60%:wrap
  --bind="ctrl-/:toggle-preview"
'

# =============================================================================
# DOCKER / COLIMA CONFIGURATION
# =============================================================================

if command -v colima &> /dev/null; then
    export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

    # Testcontainers needs to know how to resolve the Colima host
    if command -v jq &> /dev/null; then
        export TESTCONTAINERS_HOST_OVERRIDE=$(colima ls -j 2>/dev/null | jq -r '.address // empty')
    fi
fi

# For containers to communicate with Docker
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock

# =============================================================================
# NODE.JS CONFIGURATION
# =============================================================================

# Set memory limit to 8GB (adjust based on your system)
export NODE_OPTIONS="--max-old-space-size=8192"

# NVM directory
export NVM_DIR="$HOME/.nvm"

# =============================================================================
# SDKMAN CONFIGURATION
# =============================================================================

export SDKMAN_DIR="$HOME/.sdkman"