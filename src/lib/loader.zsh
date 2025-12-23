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

# Ensure git config includes shell-tools aliases (replace on switch)
_st_ensure_git_include() {
    local gitconfig="$HOME/.gitconfig"
    local git_aliases_path="$SHELL_TOOLS_ROOT/cache/git-aliases"

    # Create .gitconfig if it doesn't exist
    [[ ! -f "$gitconfig" ]] && touch "$gitconfig"

    # Remove any existing shell-tools git-aliases includes (from dev or installed versions)
    # This ensures only one shell-tools include is active at a time
    # Match any path ending with cache/git-aliases (shell-tools signature)
    local existing_includes
    existing_includes=$(git config --global --get-all include.path 2>/dev/null | grep "cache/git-aliases$")

    if [[ -n "$existing_includes" ]]; then
        while IFS= read -r old_include; do
            git config --global --unset include.path "$old_include" 2>/dev/null
        done <<< "$existing_includes"
    fi

    # Add the current shell-tools include
    git config --global --add include.path "$git_aliases_path" 2>/dev/null
    _st_success "Git aliases configured for current shell-tools"
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

# Check if minimal cache needs regeneration
_st_needs_minimal_regenerate() {
    local cache_file="$SHELL_TOOLS_ROOT/cache/init-minimal.zsh"
    local version_file="$SHELL_TOOLS_ROOT/cache/.version-minimal"
    local current_version=$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null)
    local cached_version=$(cat "$version_file" 2>/dev/null)

    [[ ! -f "$cache_file" ]] || [[ "$current_version" != "$cached_version" ]]
}

# Generate minimal cache (for minimal mode - aliases + functions only)
_st_generate_minimal_cache() {
    local cache_dir="$SHELL_TOOLS_ROOT/cache"
    local cache_file="$cache_dir/init-minimal.zsh"
    local version="$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"

    mkdir -p "$cache_dir"

    # Generate minimal cache with only aliases and functions
    {
        echo "# shell-tools minimal cache"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Version: $version"
        echo "# Modules: aliases, functions"
        echo "# DO NOT EDIT - This file is auto-generated"
        echo ""
        echo "# ============================================================================="
        echo "# MODULE: aliases"
        echo "# ============================================================================="
        echo ""
        cat "$SHELL_TOOLS_ROOT/modules/aliases.zsh"
        echo ""
        echo "# ============================================================================="
        echo "# MODULE: functions"
        echo "# ============================================================================="
        echo ""
        cat "$SHELL_TOOLS_ROOT/modules/functions.zsh"
    } > "$cache_file"

    # Store version for cache invalidation
    echo "$version" > "$cache_dir/.version-minimal"
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
