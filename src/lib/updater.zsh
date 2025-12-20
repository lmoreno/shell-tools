# shell-tools auto-update system

# Configuration (can be modified by user)
SHELL_TOOLS_UPDATE_CHECK="${SHELL_TOOLS_UPDATE_CHECK:-always}"  # always, daily, weekly, never
SHELL_TOOLS_REPO="${SHELL_TOOLS_REPO:-lmoreno/shell-tools}"

# Cache file for last update check
UPDATE_CHECK_CACHE="$SHELL_TOOLS_ROOT/cache/.last_update_check"

# Check if we should check for updates based on frequency setting
_st_should_check_updates() {
    [[ "$SHELL_TOOLS_UPDATE_CHECK" == "never" ]] && return 1
    [[ "$SHELL_TOOLS_UPDATE_CHECK" == "always" ]] && return 0

    # Check cache for daily/weekly settings
    if [[ -f "$UPDATE_CHECK_CACHE" ]]; then
        local last_check=$(cat "$UPDATE_CHECK_CACHE")
        local now=$(date +%s)
        local diff=$((now - last_check))

        case "$SHELL_TOOLS_UPDATE_CHECK" in
            daily)
                [[ $diff -gt 86400 ]] && return 0 || return 1
                ;;
            weekly)
                [[ $diff -gt 604800 ]] && return 0 || return 1
                ;;
        esac
    fi

    return 0
}

# Get latest version from GitHub
_st_get_latest_version() {
    local response
    local http_code

    # Fetch with HTTP status code
    response=$(curl -sS -w "\n%{http_code}" "https://api.github.com/repos/$SHELL_TOOLS_REPO/releases/latest" 2>&1)
    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    # Check for specific error codes
    case "$http_code" in
        200)
            # Success - extract tag_name
            echo "$body" | grep '"tag_name"' | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' 2>/dev/null
            ;;
        403)
            # Rate limit or forbidden
            if echo "$body" | grep -q "rate limit"; then
                echo "RATE_LIMIT_ERROR" >&2
            else
                echo "FORBIDDEN_ERROR" >&2
            fi
            return 1
            ;;
        404)
            echo "NOT_FOUND_ERROR" >&2
            return 1
            ;;
        *)
            # Network error or other issues
            echo "NETWORK_ERROR:$http_code" >&2
            return 1
            ;;
    esac
}

# Compare semantic versions
_st_version_gt() {
    local ver1="$1"
    local ver2="$2"

    # Remove 'v' prefix if present
    ver1="${ver1#v}"
    ver2="${ver2#v}"

    # Simple semantic version comparison
    [[ "$ver1" != "$ver2" ]] && [[ "$ver1" == "$(echo -e "$ver1\n$ver2" | sort -V | tail -n1)" ]]
}

# Perform update
_st_perform_update() {
    local new_version="$1"

    echo ""
    _st_log "Downloading shell-tools $new_version..."

    # Create temp directory
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/shell-tools.zip"

    # Download latest release asset (shell-tools.zip)
    local download_url="https://api.github.com/repos/$SHELL_TOOLS_REPO/releases/latest"
    local latest_release_json=$(curl -fsSL "$download_url")

    # Extract asset download URL using awk (matches install.sh)
    local asset_url=$(
        echo "$latest_release_json" |
        awk '
            /"name": *"shell-tools.zip"/ {
                asset_block = 1;
                next;
            }
            asset_block == 1 {
                if (/"browser_download_url":/) {
                    sub(/.*"browser_download_url": "/, "");
                    sub(/".*/, "");
                    print;
                    asset_block = 0;
                }
            }
        '
    )

    if [[ -z "$asset_url" ]]; then
        _st_error "Failed to fetch download URL"
        return 1
    fi

    curl -fsSL "$asset_url" -o "$zip_file" || {
        _st_error "Download failed"
        rm -rf "$temp_dir"
        return 1
    }

    # Backup current modules (preserve user customizations)
    _st_log "Backing up your customizations..."
    cp -r "$SHELL_TOOLS_ROOT/modules" "$temp_dir/modules.backup" 2>/dev/null || true

    # Extract new version (release asset always has flat structure)
    unzip -q "$zip_file" -d "$temp_dir"
    local extracted_dir="$temp_dir"

    # Validate extraction
    if [[ ! -d "$extracted_dir/lib" ]] || [[ ! -f "$extracted_dir/VERSION" ]]; then
        _st_error "Failed to extract release"
        rm -rf "$temp_dir"
        return 1
    fi

    # Replace installation (keep cache) - use explicit paths
    rm -rf "$SHELL_TOOLS_ROOT/lib" 2>/dev/null
    rm -rf "$SHELL_TOOLS_ROOT/modules" 2>/dev/null
    rm -rf "$SHELL_TOOLS_ROOT/tools" 2>/dev/null
    rm -f "$SHELL_TOOLS_ROOT/plugin.zsh" 2>/dev/null
    rm -f "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null

    # Copy new files
    cp -r "$extracted_dir"/* "$SHELL_TOOLS_ROOT"/

    # Verify VERSION was updated correctly
    local installed_version=$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null | tr -d '[:space:]')
    if [[ "$installed_version" != "${new_version#v}" ]]; then
        _st_warn "VERSION file mismatch after install: expected ${new_version#v}, got $installed_version"
    fi

    # Restore user's module customizations if they exist
    # (This is a simple approach - could be smarter about merging)
    if [[ -f "$temp_dir/modules.backup/local.zsh" ]]; then
        cp "$temp_dir/modules.backup/local.zsh" "$SHELL_TOOLS_ROOT/modules/local.zsh"
    fi

    # Cleanup
    rm -rf "$temp_dir"

    _st_success "Updated to $new_version!"
    return 0
}

# Main update check function (called from st-reload)
_st_check_for_updates() {
    # Check if we should check for updates
    _st_should_check_updates || return 0

    # Update last check timestamp
    date +%s > "$UPDATE_CHECK_CACHE"

    # Get current and latest versions
    local current_version=$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "0.0.0")
    local latest_version

    # Get latest version (suppress errors on automatic checks)
    latest_version=$(_st_get_latest_version 2>/dev/null)

    # Handle errors silently on automatic checks (don't spam user on every shell startup)
    if [[ -z "$latest_version" ]]; then
        return 0
    fi

    # Check if update available
    if _st_version_gt "$latest_version" "$current_version"; then
        echo ""
        _st_warn "🎉 New version available: $latest_version (current: $current_version)"
        echo ""
        read "update?Update now? (y/n): "

        if [[ "$update" =~ ^[Yy]$ ]]; then
            _st_perform_update "$latest_version" && {
                _st_log "Reloading shell with new version..."
                exec zsh
            }
        else
            echo "   Skipped. Run 'st-update' later to update."
        fi
    fi
}

# Manual update command
st-update() {
    local current_version=$(cat "$SHELL_TOOLS_ROOT/VERSION" 2>/dev/null || echo "0.0.0")
    local latest_version error_msg

    # Capture both stdout and stderr
    error_msg=$(_st_get_latest_version 2>&1 1>/dev/null)
    latest_version=$(_st_get_latest_version 2>/dev/null)

    # Handle errors with user-friendly messages
    if [[ -z "$latest_version" ]]; then
        case "$error_msg" in
            RATE_LIMIT_ERROR)
                _st_error "GitHub API rate limit exceeded"
                echo "  Please try again later or check manually at:"
                echo "  https://github.com/$SHELL_TOOLS_REPO/releases/latest"
                ;;
            FORBIDDEN_ERROR)
                _st_error "Access forbidden to GitHub API"
                echo "  Check your network connection or GitHub access"
                ;;
            NOT_FOUND_ERROR)
                _st_error "Repository not found: $SHELL_TOOLS_REPO"
                ;;
            NETWORK_ERROR:*)
                local code="${error_msg#NETWORK_ERROR:}"
                _st_error "Network error (HTTP $code)"
                echo "  Check your internet connection and try again"
                ;;
            *)
                _st_error "Failed to check for updates"
                echo "  Check your internet connection and try again"
                ;;
        esac
        return 1
    fi

    if _st_version_gt "$latest_version" "$current_version"; then
        echo "Update available: $current_version → $latest_version"
        read "update?Update now? (y/n): "

        if [[ "$update" =~ ^[Yy]$ ]]; then
            _st_perform_update "$latest_version" && {
                _st_log "Reloading shell with new version..."
                exec zsh
            }
        fi
    else
        _st_success "Already on latest version: $current_version"
    fi
}
