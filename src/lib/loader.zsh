# shell-tools loader
# Cache generation and version checking

# Generate git aliases file from modules/git.gitconfig
_st_generate_git_aliases() {
    local source_file="$SHELL_TOOLS_ROOT/modules/git.gitconfig"
    local output_file="$SHELL_TOOLS_ROOT/cache/git-aliases"
    local version="$1"

    # Skip if no git config source file
    [[ ! -f "$source_file" ]] && return 0

    {
        echo "# shell-tools generated git aliases"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Version: $version"
        echo "# DO NOT EDIT - This file is auto-generated"
        echo "# Source: modules/git.gitconfig"
        echo ""
        cat "$source_file"
    } > "$output_file"

    _st_log "Git aliases generated"
}

# Ensure git config includes shell-tools aliases
_st_ensure_git_include() {
    local gitconfig="$HOME/.gitconfig"
    local git_aliases_path="$SHELL_TOOLS_ROOT/cache/git-aliases"

    # Create .gitconfig if it doesn't exist
    [[ ! -f "$gitconfig" ]] && touch "$gitconfig"

    # Check if include already exists using git config command
    local current_include=$(git config --global --get-all include.path 2>/dev/null | grep -F "$git_aliases_path")

    if [[ -z "$current_include" ]]; then
        git config --global --add include.path "$git_aliases_path" 2>/dev/null
        _st_success "Added git aliases include to ~/.gitconfig"
    fi
}

# Check if cache needs to be regenerated
_st_needs_regenerate() {
    local cache_file="$SHELL_TOOLS_ROOT/cache/init.zsh"
    local cached_version="$SHELL_TOOLS_ROOT/cache/.version"
    local current_version="$SHELL_TOOLS_ROOT/VERSION"

    # No cache exists
    [[ ! -f "$cache_file" ]] && return 0

    # No cached version file
    [[ ! -f "$cached_version" ]] && return 0

    # Version mismatch
    [[ "$(cat "$cached_version" 2>/dev/null)" != "$(cat "$current_version" 2>/dev/null)" ]] && return 0

    return 1
}

# Generate static cache from modules
_st_generate_cache() {
    local cache_file="$SHELL_TOOLS_ROOT/cache/init.zsh"
    local version_file="$SHELL_TOOLS_ROOT/VERSION"
    local version="$(cat "$version_file" 2>/dev/null || echo "unknown")"

    _st_log "Generating cache (v$version)..."

    # Create cache directory if needed
    mkdir -p "$SHELL_TOOLS_ROOT/cache"

    # Generate the static cache file
    {
        echo "# shell-tools static cache"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Version: $version"
        echo "# DO NOT EDIT - This file is auto-generated"
        echo ""

        # Static modules that can be cached (no evals)
        local static_modules=(aliases functions env completions local)

        for module in "${static_modules[@]}"; do
            local file="$SHELL_TOOLS_ROOT/modules/${module}.zsh"
            if [[ -f "$file" ]]; then
                echo ""
                echo "# ============================================================================="
                echo "# MODULE: $module"
                echo "# ============================================================================="
                echo ""
                cat "$file"
            fi
        done
    } > "$cache_file"

    # Save current version
    echo "$version" > "$SHELL_TOOLS_ROOT/cache/.version"

    # Generate git aliases file
    _st_generate_git_aliases "$version"

    # Ensure git config includes shell-tools aliases
    _st_ensure_git_include

    _st_success "Cache generated successfully"
}

# Load modules directly (used when cache is disabled or for dynamic modules)
_st_load_module() {
    local module="$1"
    local file="$SHELL_TOOLS_ROOT/modules/${module}.zsh"

    if [[ -f "$file" ]]; then
        source "$file"
    fi
}
