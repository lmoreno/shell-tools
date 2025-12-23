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

# Auto-switch to zsh if running in bash (interactive shells only)
# IMPORTANT: Must use POSIX-compatible syntax (no [[ ]] or zsh expansions)
if [ -n "$BASH_VERSION" ]; then
    # Only switch in interactive shells to avoid breaking SSH commands
    case $- in
        *i*)
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
            ;;
    esac
fi

# Resolve plugin root directory (works even if symlinked)
SHELL_TOOLS_ROOT="${0:A:h}"

# Load core utilities early (needed for _st_log in dev mode message)
source "$SHELL_TOOLS_ROOT/lib/core.zsh"

# -----------------------------------------------------------------------------
# Minimal mode (root user or SHELL_TOOLS_MINIMAL=1)
# -----------------------------------------------------------------------------
# Only loads aliases and functions - no oh-my-zsh, tools, completions, or auto-updates
if _st_is_minimal_mode; then
    # Show message only in interactive shells
    if _st_is_interactive; then
        if [[ $EUID -eq 0 ]]; then
            _st_log "Minimal mode (root user)"
        else
            _st_log "Minimal mode"
        fi
    fi

    # Export early for subshells
    export SHELL_TOOLS_ROOT
    export SHELL_TOOLS_MINIMAL=1

    # Load minimal loader functions
    source "$SHELL_TOOLS_ROOT/lib/loader.zsh"

    # Generate minimal cache if needed
    if _st_needs_minimal_regenerate; then
        _st_log "Generating minimal cache..."
        _st_generate_minimal_cache
    fi

    # Load minimal cached content
    if [[ -f "$SHELL_TOOLS_ROOT/cache/init-minimal.zsh" ]]; then
        source "$SHELL_TOOLS_ROOT/cache/init-minimal.zsh"
    fi

    # Load updater and uninstaller for manual use (skip auto-update check)
    source "$SHELL_TOOLS_ROOT/lib/updater.zsh"
    source "$SHELL_TOOLS_ROOT/lib/uninstaller.zsh"

    # Minimal st-version
    st-version() {
        local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
        _st_log "v$version (minimal)"
    }

    # Minimal st-reload
    st-reload() {
        _st_log "Reloading..."
        rm -f "$SHELL_TOOLS_ROOT/cache/.version-minimal"
        source "$SHELL_TOOLS_ROOT/plugin.zsh"
        _st_success "Reloaded!"
    }

    # Minimal st-info (adapted - shows cache status)
    st-info() {
        local bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m'
        local green=$'\e[32m' yellow=$'\e[33m'
        local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
        local cached_version="$(command cat "$SHELL_TOOLS_ROOT/cache/.version-minimal" 2>/dev/null || echo "none")"

        echo ""
        printf "%s %s\n" "${bold}shell-tools${reset}" "${yellow}[MINIMAL]${reset}"
        echo "═══════════════════════════════════════════════════"
        echo ""
        printf "  ${bold}${dim}%-14s${reset} %s\n" "Mode" "Minimal"
        printf "  ${bold}${dim}%-14s${reset} %s\n" "Version" "$version"
        [[ $EUID -eq 0 ]] && printf "  ${bold}${dim}%-14s${reset} %s\n" "User" "root"
        printf "  ${bold}${dim}%-14s${reset} %s\n" "Root" "$(_st_shorten_path "$SHELL_TOOLS_ROOT")"
        echo ""
        echo "${bold}Cache${reset}"
        echo "───────────────────────────────────────────────────"
        if [[ "$cached_version" == "$version" ]]; then
            printf "  ${bold}${dim}%-14s${reset} %s ${green}(current)${reset}\n" "Version" "$cached_version"
        else
            printf "  ${bold}${dim}%-14s${reset} %s ${yellow}(stale)${reset}\n" "Version" "$cached_version"
        fi
        echo ""
        echo "${bold}Loaded Modules${reset}"
        echo "───────────────────────────────────────────────────"
        echo "  ${green}✓${reset} aliases.zsh"
        echo "  ${green}✓${reset} functions.zsh"
        echo ""
    }

    return 0
fi

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
# Run migrations (fix old configurations)
# -----------------------------------------------------------------------------
source "$SHELL_TOOLS_ROOT/lib/migrate.zsh"
_st_run_migrations

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
    # Only delete .version to trigger regeneration - keep init.zsh
    # This prevents "First run detected" if update happens mid-reload
    rm -f "$SHELL_TOOLS_ROOT/cache/.version"

    # Check for updates before reloading
    _st_check_for_updates

    # Detect if we should reload dev or installed version
    # This ensures reload works correctly even if SHELL_TOOLS_ROOT got set wrong
    local reload_plugin="$SHELL_TOOLS_ROOT/plugin.zsh"
    local check_dir="$PWD"
    while [[ "$check_dir" != "/" ]]; do
        if [[ -f "$check_dir/src/.dev" ]]; then
            reload_plugin="$check_dir/src/plugin.zsh"
            break
        fi
        check_dir="${check_dir:h}"
    done

    source "$reload_plugin"
    _st_success "Reloaded!"
}

# Show version
st-version() {
    local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    _st_log "v$version"
}

# Show system information for debugging
st-info() {
    # ANSI codes
    local bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m'
    local green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m'

    # Collect data
    local version="$(command cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    local mode="Installed"
    [[ -n "$SHELL_TOOLS_DEV" ]] && mode="Development"

    # Collect health issues
    local issues=()
    local cached_version="$(command cat "$SHELL_TOOLS_ROOT/cache/.version" 2>/dev/null || echo "none")"
    [[ "$cached_version" != "$version" ]] && issues+=("stale cache")

    local git_aliases="$SHELL_TOOLS_ROOT/cache/git-aliases"
    ! command grep -q "path.*$git_aliases" "$HOME/.gitconfig" 2>/dev/null && issues+=("git include")

    local latest_version latest_clean version_status
    latest_version=$(_st_get_latest_version 2>/dev/null)
    latest_clean="${latest_version#v}"
    if [[ -n "$latest_clean" ]]; then
        if [[ "$latest_clean" == "$version" ]]; then
            version_status="${green}(up to date)${reset}"
        else
            version_status="${yellow}(update: $latest_clean)${reset}"
            issues+=("update available")
        fi
    else
        version_status="${dim}(unable to check)${reset}"
    fi

    # Read timestamps
    local installed_at last_updated last_check
    installed_at=$(command cat "$SHELL_TOOLS_ROOT/cache/.installed_at" 2>/dev/null)
    last_updated=$(command cat "$SHELL_TOOLS_ROOT/cache/.last_updated" 2>/dev/null)
    last_check=$(command cat "$SHELL_TOOLS_ROOT/cache/.last_update_check" 2>/dev/null)

    # Header
    echo ""
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        printf "%s                                    %s\n" "${bold}shell-tools${reset}" "${bold}${yellow}[DEV]${reset}"
    else
        printf "%s\n" "${bold}shell-tools${reset}"
    fi
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Main section
    if [[ ${#issues[@]} -eq 0 ]]; then
        printf "  ${bold}${dim}%-14s${reset} ${green}✓ Healthy${reset}\n" "Status"
    else
        printf "  ${bold}${dim}%-14s${reset} ${yellow}⚠ ${#issues[@]} issue(s): ${(j:, :)issues}${reset}\n" "Status"
    fi
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Mode" "$mode"
    printf "  ${bold}${dim}%-14s${reset} %s %s\n" "Version" "$version" "$version_status"
    # Only show timestamps if we have them (avoids misleading "never" for old installs)
    [[ -n "$installed_at" ]] && printf "  ${bold}${dim}%-14s${reset} %s\n" "Install Date" "$(_st_format_timestamp "$installed_at")"
    [[ -n "$last_updated" ]] && printf "  ${bold}${dim}%-14s${reset} %s\n" "Last Update" "$(_st_format_timestamp "$last_updated")"
    [[ -n "$last_check" ]] && printf "  ${bold}${dim}%-14s${reset} %s\n" "Last Check" "$(_st_format_timestamp "$last_check")"

    # Cache section
    echo ""
    echo "${bold}Cache${reset}"
    echo "───────────────────────────────────────────────────"
    if [[ "$cached_version" == "$version" ]]; then
        printf "  ${bold}${dim}%-14s${reset} %s ${green}(current)${reset}\n" "Version" "$cached_version"
    else
        printf "  ${bold}${dim}%-14s${reset} %s ${yellow}(stale, run st-reload)${reset}\n" "Version" "$cached_version"
    fi
    if [[ -f "$SHELL_TOOLS_ROOT/cache/init.zsh" ]]; then
        local cache_date
        cache_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$SHELL_TOOLS_ROOT/cache/init.zsh" 2>/dev/null || \
                     stat -c "%y" "$SHELL_TOOLS_ROOT/cache/init.zsh" 2>/dev/null | cut -d. -f1 || \
                     echo "unknown")
        printf "  ${bold}${dim}%-14s${reset} %s\n" "Generated" "$cache_date"
    else
        printf "  ${bold}${dim}%-14s${reset} %s\n" "Generated" "(cache missing)"
    fi

    # Configuration section
    echo ""
    echo "${bold}Configuration${reset}"
    echo "───────────────────────────────────────────────────"
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Update Check" "${SHELL_TOOLS_UPDATE_CHECK:-always}"
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Repository" "${SHELL_TOOLS_REPO:-lmoreno/shell-tools}"

    # Modules section (3-column grid)
    echo ""
    echo "${bold}Modules${reset}"
    echo "───────────────────────────────────────────────────"
    local modules=(aliases functions env tools completions local)
    local col=0
    local line="  "
    for module in "${modules[@]}"; do
        local module_file="$SHELL_TOOLS_ROOT/modules/${module}.zsh"
        if [[ -f "$module_file" ]]; then
            line+="${green}✓${reset} ${module}.zsh"
        else
            line+="${red}✗${reset} ${module}.zsh"
        fi
        ((col++))
        if [[ $col -eq 3 ]]; then
            echo "$line"
            line="  "
            col=0
        else
            # Pad to column width (18 chars)
            local pad=$((18 - ${#module} - 6))
            line+=$(printf "%${pad}s" "")
        fi
    done
    [[ $col -ne 0 ]] && echo "$line"

    # Paths section
    echo ""
    echo "${bold}Paths${reset}"
    echo "───────────────────────────────────────────────────"
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Root" "$(_st_shorten_path "$SHELL_TOOLS_ROOT")"
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Cache" "$(_st_shorten_path "$SHELL_TOOLS_ROOT/cache")"
    printf "  ${bold}${dim}%-14s${reset} %s\n" "Modules" "$(_st_shorten_path "$SHELL_TOOLS_ROOT/modules")"

    # Git Integration section
    echo ""
    echo "${bold}Git Integration${reset}"
    echo "───────────────────────────────────────────────────"
    local gitconfig="$HOME/.gitconfig"
    if [[ -f "$gitconfig" ]] && command grep -q "path.*$git_aliases" "$gitconfig" 2>/dev/null; then
        printf "  ${bold}${dim}%-14s${reset} ${green}✓ configured${reset}\n" "Include"
    elif [[ -f "$git_aliases" ]]; then
        printf "  ${bold}${dim}%-14s${reset} ${yellow}⚠ not configured (run st-reload)${reset}\n" "Include"
    else
        printf "  ${bold}${dim}%-14s${reset} ${red}✗ not configured${reset}\n" "Include"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Cleanup internal functions (keep only public API)
# -----------------------------------------------------------------------------
unfunction _st_bootstrap 2>/dev/null
unfunction _st_needs_regenerate 2>/dev/null
unfunction _st_generate_cache 2>/dev/null
unfunction _st_load_module 2>/dev/null
