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

# -----------------------------------------------------------------------------
# Auto Dev Mode Detection
# -----------------------------------------------------------------------------
# If we're in a directory with src/.dev marker, use the dev version instead
if [[ -z "$SHELL_TOOLS_ROOT" ]] || [[ "$SHELL_TOOLS_ROOT" != */src ]]; then
    # Look for dev marker in current directory tree
    local check_dir="$PWD"
    while [[ "$check_dir" != "/" ]]; do
        if [[ -f "$check_dir/src/.dev" ]]; then
            # Found dev marker - redirect to dev version
            local dev_plugin="$check_dir/src/plugin.zsh"
            if [[ -f "$dev_plugin" ]] && [[ "$dev_plugin" != "${(%):-%x}" ]]; then
                source "$dev_plugin"
                return 0
            fi
            break
        fi
        check_dir="${check_dir:h}"  # Go up one directory
    done
fi

# Auto-switch to zsh if running in bash
# IMPORTANT: Must use POSIX-compatible syntax (no [[ ]] or zsh expansions)
if [ -n "$BASH_VERSION" ]; then
    if command -v zsh >/dev/null 2>&1; then
        export SHELL=$(command -v zsh)
        exec zsh
    else
        echo "[shell-tools] ERROR: shell-tools requires zsh, but zsh is not installed."
        echo "[shell-tools] Install zsh:"
        echo "  macOS:  brew install zsh"
        echo "  Linux:  sudo apt install zsh  # or: sudo yum install zsh"
        return 1 2>/dev/null || exit 1
    fi
fi

# Resolve plugin root directory (works even if symlinked)
SHELL_TOOLS_ROOT="${0:A:h}"

# Load core utilities early (needed for _st_log in dev mode message)
source "$SHELL_TOOLS_ROOT/lib/core.zsh"

# Detect development mode (.dev marker file indicates dev environment)
if [[ -f "$SHELL_TOOLS_ROOT/.dev" ]]; then
    export SHELL_TOOLS_DEV=1
    _st_log "🔧 Development mode active"

    # Register hook to maintain dev mode when changing directories
    _shell_tools_maintain_dev() {
        # If we leave and re-enter project, reload to ensure dev mode
        local check_dir="$PWD"
        local found_dev=0

        while [[ "$check_dir" != "/" ]]; do
            if [[ -f "$check_dir/src/.dev" ]]; then
                found_dev=1
                break
            fi
            check_dir="${check_dir:h}"
        done

        if [[ $found_dev -eq 1 ]] && [[ "$SHELL_TOOLS_ROOT" != "$check_dir/src" ]]; then
            source "$check_dir/src/plugin.zsh"
        fi
    }

    autoload -U add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _shell_tools_maintain_dev 2>/dev/null
else
    # Normal mode: watch for entering dev directories
    _shell_tools_detect_dev() {
        local check_dir="$PWD"
        while [[ "$check_dir" != "/" ]]; do
            if [[ -f "$check_dir/src/.dev" ]]; then
                source "$check_dir/src/plugin.zsh"
                return
            fi
            check_dir="${check_dir:h}"
        done
    }
    autoload -U add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _shell_tools_detect_dev 2>/dev/null
fi

# Export for use in subshells
export SHELL_TOOLS_ROOT

# -----------------------------------------------------------------------------
# Load bootstrap utilities
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/bootstrap.zsh"

# -----------------------------------------------------------------------------
# First run detection and bootstrap
# -----------------------------------------------------------------------------
if [[ ! -d "$SHELL_TOOLS_ROOT/cache" ]] || [[ ! -f "$SHELL_TOOLS_ROOT/cache/init.zsh" ]]; then
    _st_log "First run detected, bootstrapping..."
    _st_bootstrap
fi

# Always check and install Oh-My-Zsh if missing (even on updates)
_st_bootstrap_omz

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
# Load auto-updater
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/updater.zsh"

# Check for updates on shell initialization (respects frequency setting)
_st_check_for_updates

# -----------------------------------------------------------------------------
# Load uninstaller
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/uninstaller.zsh"

# -----------------------------------------------------------------------------
# User commands
# -----------------------------------------------------------------------------

# Force cache regeneration and reload
st-reload() {
    _st_log "Regenerating cache..."
    rm -f "$SHELL_TOOLS_ROOT/cache/init.zsh"
    rm -f "$SHELL_TOOLS_ROOT/cache/.version"

    # Check for updates before reloading
    _st_check_for_updates

    source "$SHELL_TOOLS_ROOT/plugin.zsh"
    _st_success "Reloaded!"
}

# Show version
st-version() {
    local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    _st_log "v$version"
}

# Show system information for debugging
st-info() {
    local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    local mode="Installed"
    [[ -n "$SHELL_TOOLS_DEV" ]] && mode="Development"

    _st_log "System Information"
    echo ""
    echo "Mode:           $mode"
    echo "Version:        $version"

    # Check for latest version (non-blocking, silent on error)
    local latest_version
    latest_version=$(_st_get_latest_version 2>/dev/null)
    if [[ -n "$latest_version" ]]; then
        local latest_clean="${latest_version#v}"
        if [[ "$latest_clean" == "$version" ]]; then
            echo "Latest:         $latest_clean (up to date)"
        else
            echo "Latest:         $latest_clean (update available)"
        fi
    else
        echo "Latest:         (unable to check)"
    fi

    echo ""
    echo "Paths:"
    echo "  Root:         $SHELL_TOOLS_ROOT"
    echo "  Cache:        $SHELL_TOOLS_ROOT/cache"
    echo "  Modules:      $SHELL_TOOLS_ROOT/modules"

    echo ""
    echo "Configuration:"
    echo "  Update Check: ${SHELL_TOOLS_UPDATE_CHECK:-always}"
    echo "  Repository:   ${SHELL_TOOLS_REPO:-lmoreno/shell-tools}"

    echo ""
    echo "Modules:"
    local module
    for module in aliases functions env tools completions local; do
        local module_file="$SHELL_TOOLS_ROOT/modules/${module}.zsh"
        if [[ -f "$module_file" ]]; then
            echo "  ✓ ${module}.zsh"
        else
            echo "  ✗ ${module}.zsh (not found)"
        fi
    done

    echo ""
    echo "Cache Status:"
    local cached_version="$(command cat "$SHELL_TOOLS_ROOT/cache/.version" 2>/dev/null || echo "none")"
    if [[ "$cached_version" == "$version" ]]; then
        echo "  Version:      $cached_version (current)"
    else
        echo "  Version:      $cached_version (stale, run st-reload)"
    fi

    if [[ -f "$SHELL_TOOLS_ROOT/cache/init.zsh" ]]; then
        local cache_date
        cache_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$SHELL_TOOLS_ROOT/cache/init.zsh" 2>/dev/null || \
                     stat -c "%y" "$SHELL_TOOLS_ROOT/cache/init.zsh" 2>/dev/null | cut -d. -f1 || \
                     echo "unknown")
        echo "  Generated:    $cache_date"
    else
        echo "  Generated:    (cache missing)"
    fi

    echo ""
    echo "Git Integration:"
    local gitconfig="$HOME/.gitconfig"
    local git_aliases="$SHELL_TOOLS_ROOT/cache/git-aliases"
    if [[ -f "$gitconfig" ]] && grep -q "path.*$git_aliases" "$gitconfig" 2>/dev/null; then
        echo "  Include:      ~/.gitconfig includes cache/git-aliases"
    elif [[ -f "$git_aliases" ]]; then
        echo "  Include:      cache/git-aliases exists (not in gitconfig)"
    else
        echo "  Include:      not configured"
    fi
}

# -----------------------------------------------------------------------------
# Cleanup internal functions (keep only public API)
# -----------------------------------------------------------------------------
unfunction _st_bootstrap 2>/dev/null
unfunction _st_needs_regenerate 2>/dev/null
unfunction _st_generate_cache 2>/dev/null
unfunction _st_load_module 2>/dev/null
