# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Create directory and cd into it
take() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive type
ex() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Kill process by port number
killport() {
    lsof -ti:$1 | xargs kill -9
}

# Create timestamped backup of file
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Open directory in VS Code and cd into it
c() {
    code "$1" && cd "$1"
}

# =============================================================================
# ALIAS DISCOVERY FUNCTIONS
# =============================================================================

# Search aliases by keyword
alias-search() {
    alias | grep -i "$1"
}

# Interactive alias finder with fzf
# Usage: use          (opens interactive finder)
#        use git      (opens finder filtered to "git")
# When you select an alias, it's inserted into your command line ready to execute!
unalias use 2>/dev/null
use() {
    local selection
    if [ -n "$1" ]; then
        selection=$(alias | fzf --query="$1" --preview "echo {}" --preview-window=up:3:wrap --print-query | tail -1)
    else
        selection=$(alias | fzf --preview "echo {}" --preview-window=up:3:wrap)
    fi

    if [ -n "$selection" ]; then
        local alias_name=$(echo "$selection" | cut -d'=' -f1)
        print -z "$alias_name"
    fi
}
