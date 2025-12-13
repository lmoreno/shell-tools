# shell-tools loader
# Cache generation and version checking

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
        local static_modules=(aliases functions env completions)

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
