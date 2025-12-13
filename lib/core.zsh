# shell-tools core utilities
# Provides logging helpers and utility functions

# Logging functions with colored output
_st_log() {
    print -P "%F{blue}[shell-tools]%f $1"
}

_st_warn() {
    print -P "%F{yellow}[shell-tools]%f $1"
}

_st_error() {
    print -P "%F{red}[shell-tools]%f $1"
}

_st_success() {
    print -P "%F{green}[shell-tools]%f $1"
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
