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
            *)           _st_error "'$1' cannot be extracted" ;;
        esac
    else
        _st_error "'$1' is not a valid file"
    fi
}

# Kill process by port number
killport() {
    if ! command -v lsof &>/dev/null; then
        _st_error "'lsof' is required"
        return 1
    fi
    lsof -ti:$1 | xargs kill -9
}

# Create timestamped backup of file
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Open directory in VS Code and cd into it
c() {
    if ! command -v code &>/dev/null; then
        _st_error "'code' (VS Code) is required"
        return 1
    fi
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
    if ! command -v fzf &>/dev/null; then
        _st_error "'fzf' is required for this command"
        echo "  Install via: brew install fzf"
        return 1
    fi

    local selection

    # AWK script to format aliases with colors: bold cyan alias → command
    local awk_script='BEGIN {FS="="} {
        alias_name = $1;
        command = substr($0, index($0, "=") + 1);
        # Remove surrounding quotes from command
        gsub(/^'\''|'\''$/, "", command);
        # Print with bold cyan alias name, arrow symbol, and command
        printf "\033[1;36m%-20s\033[0m → %s\n", alias_name, command;
    }'

    if [ -n "$1" ]; then
        # Pre-filtered query with color rendering
        selection=$(alias | awk "$awk_script" | fzf --query="$1" --ansi --preview "echo {}" --preview-window=up:3:wrap --print-query | tail -1)
    else
        # Interactive mode with color rendering
        selection=$(alias | awk "$awk_script" | fzf --ansi --preview "echo {}" --preview-window=up:3:wrap)
    fi

    if [ -n "$selection" ]; then
        # Extract alias name, stripping ANSI codes
        local alias_name=$(echo "$selection" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
        print -z "$alias_name"
    fi
}

# =============================================================================
# ALIAS MANAGEMENT FUNCTIONS
# =============================================================================

# Add alias to shell-tools
add-alias() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: add-alias <name> <command>"
        echo "Example: add-alias ll 'ls -la'"
        return 1
    fi

    local alias_name="$1"
    shift
    local alias_cmd="$*"
    local aliases_file="$SHELL_TOOLS_ROOT/modules/aliases.zsh"

    # Check if alias already exists
    if grep -q "^alias $alias_name=" "$aliases_file" 2>/dev/null;
 then
        _st_warn "Alias '$alias_name' already exists"
        _st_log "Current: $(grep "^alias $alias_name=" "$aliases_file")"
        read "overwrite?Overwrite? (y/n): "
        [[ "$overwrite" != "y" ]] && { _st_log "Cancelled."; return 1; }
        sed -i.bak "/^alias $alias_name=/d" "$aliases_file"
    fi

    echo "alias $alias_name='$alias_cmd'" >> "$aliases_file"
    _st_success "Added: alias $alias_name='$alias_cmd'"
    st-reload
    _st_success "Alias loaded and ready to use"
}

# Remove alias from shell-tools
remove-alias() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: remove-alias <name>"
        return 1
    fi

    local alias_name="$1"
    local aliases_file="$SHELL_TOOLS_ROOT/modules/aliases.zsh"

    if ! grep -q "^alias $alias_name=" "$aliases_file" 2>/dev/null;
 then
        _st_error "Alias '$alias_name' not found"
        return 1
    fi

    _st_log "Current: $(grep "^alias $alias_name=" "$aliases_file")"
    read "confirm?Remove? (y/n): "

    if [[ "$confirm" == "y" ]]; then
        sed -i.bak "/^alias $alias_name=/d" "$aliases_file"
        _st_success "Removed alias '$alias_name'"
        st-reload
        _st_success "Alias unloaded and removed"
    else
        _st_log "Cancelled."
    fi
}

# Intelligent git wrapper with fuzzy alias search
unalias g 2>/dev/null
g() {
    # If arguments are passed, execute git with them
    if [[ $# -gt 0 ]]; then
        git "$@"
        return
    fi

    # If no arguments, start interactive alias search
    if ! command -v fzf &>/dev/null; then
        _st_error "'fzf' is required for interactive mode"
        return 1
    fi

    # Get git aliases, format for fzf, and let user select one
    local selection
    selection=$(git config --get-regexp '^alias\.' |
        sed 's/^alias\.//' |
        sort -u |
        awk '{
            name=$1;
            $1="";
            # Reconstruct command, removing leading space
            cmd=substr($0, 2);
            printf "\033[1;36m%-20s\033[0m → %s\n", name, cmd;
        }' |
        fzf --ansi --preview="echo {}" --preview-window=up:3:wrap
    )

    # If a selection was made, place "g <alias>" in the prompt
    if [[ -n "$selection" ]]; then
        local alias_name=$(echo "$selection" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
        print -z "g $alias_name"
    fi
}