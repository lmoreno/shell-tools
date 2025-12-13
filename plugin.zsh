#!/usr/bin/env zsh
# =============================================================================
# shell-tools - Minimal Zsh plugin system
# =============================================================================
#
# Usage: Add this line to your ~/.zshrc:
#   source ~/path/to/shell-tools/plugin.zsh
#
# Commands:
#   st-reload    Force cache regeneration and reload
#   st-version   Show current version
#
# To apply changes after editing modules, either:
#   1. Run: st-reload
#   2. Or bump VERSION file and open a new shell
#
# =============================================================================

# Resolve plugin root directory (works even if symlinked)
SHELL_TOOLS_ROOT="${0:A:h}"

# Export for use in subshells
export SHELL_TOOLS_ROOT

# -----------------------------------------------------------------------------
# Load core utilities
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/core.zsh"

# -----------------------------------------------------------------------------
# First run detection and bootstrap
# -----------------------------------------------------------------------------
if [[ ! -d "$SHELL_TOOLS_ROOT/cache" ]] || [[ ! -f "$SHELL_TOOLS_ROOT/cache/init.zsh" ]]; then
    _st_log "First run detected, bootstrapping..."
    source "$SHELL_TOOLS_ROOT/lib/bootstrap.zsh"
    _st_bootstrap
fi

# -----------------------------------------------------------------------------
# Load the loader
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/loader.zsh"

# -----------------------------------------------------------------------------
# Check if cache regeneration is needed
# -----------------------------------------------------------------------------
if _st_needs_regenerate; then
    _st_log "Version changed, regenerating cache..."
    _st_generate_cache
fi

# -----------------------------------------------------------------------------
# Load cached static content (aliases, functions, env, completions)
# -----------------------------------------------------------------------------
if [[ -f "$SHELL_TOOLS_ROOT/cache/init.zsh" ]]; then
    source "$SHELL_TOOLS_ROOT/cache/init.zsh"
fi

# -----------------------------------------------------------------------------
# Load tools module (dynamic evals, cannot be cached)
# -----------------------------------------------------------------------------
_st_load_module "tools"

# -----------------------------------------------------------------------------
# User commands
# -----------------------------------------------------------------------------

# Force cache regeneration and reload
st-reload() {
    _st_log "Regenerating cache..."
    rm -f "$SHELL_TOOLS_ROOT/cache/init.zsh"
    rm -f "$SHELL_TOOLS_ROOT/cache/.version"
    source "$SHELL_TOOLS_ROOT/plugin.zsh"
    _st_success "Reloaded!"
}

# Show version
st-version() {
    local version="$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    echo "shell-tools v$version"
}

# -----------------------------------------------------------------------------
# Cleanup internal functions (keep only public API)
# -----------------------------------------------------------------------------
unfunction _st_bootstrap 2>/dev/null
unfunction _st_needs_regenerate 2>/dev/null
unfunction _st_generate_cache 2>/dev/null
unfunction _st_load_module 2>/dev/null
