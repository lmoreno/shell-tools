# shell-tools core utilities
# Provides logging helpers and utility functions

# Logging functions with colored output
_st_log() {
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        print -P "%F{blue}[shell-tools] [DEV]%f $1"
    else
        print -P "%F{blue}[shell-tools]%f $1"
    fi
}

_st_warn() {
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        print -P "%F{yellow}[shell-tools] [DEV]%f $1"
    else
        print -P "%F{yellow}[shell-tools]%f $1"
    fi
}

_st_error() {
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        print -P "%F{red}[shell-tools] [DEV]%f $1"
    else
        print -P "%F{red}[shell-tools]%f $1"
    fi
}

_st_success() {
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        print -P "%F{green}[shell-tools] [DEV]%f $1"
    else
        print -P "%F{green}[shell-tools]%f $1"
    fi
}

# Check if a command exists
_st_has() {
    command -v "$1" &>/dev/null
}

# Check if running on macOS
_st_is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

# Check if running on Linux
_st_is_linux() {
    [[ "$OSTYPE" == linux* ]]
}

# Cross-platform sed in-place edit (macOS vs Linux compatibility)
_st_sed_i() {
    if _st_is_macos; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Format Unix timestamp to human readable date
_st_format_timestamp() {
    local ts="$1"
    [[ -z "$ts" || "$ts" == "0" ]] && echo "never" && return
    # macOS
    if _st_is_macos; then
        date -r "$ts" "+%Y-%m-%d %H:%M" 2>/dev/null && return
    else
        # Linux
        date -d "@$ts" "+%Y-%m-%d %H:%M" 2>/dev/null && return
    fi
    echo "unknown"
}

# Shorten path by replacing $HOME with ~
_st_shorten_path() {
    echo "${1/#$HOME/~}"
}
