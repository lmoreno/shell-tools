# shell-tools uninstaller
# Clean removal with user confirmation

# Marker file to track if shell-tools installed Oh-My-Zsh
_ST_OMZ_MARKER="$HOME/.shell-tools/.omz-installed-by-shell-tools"

# Remove shell-tools git include from ~/.gitconfig
_st_remove_git_include() {
    local existing_includes
    existing_includes=$(git config --global --get-all include.path 2>/dev/null | grep "cache/git-aliases$")

    if [[ -n "$existing_includes" ]]; then
        while IFS= read -r old_include; do
            git config --global --unset include.path "$old_include" 2>/dev/null
        done <<< "$existing_includes"
        return 0
    fi
    return 1
}

# Remove shell-tools source line from ~/.zshrc
_st_remove_zshrc_source() {
    local zshrc="$HOME/.zshrc"
    [[ ! -f "$zshrc" ]] && return 1

    # Remove lines containing shell-tools/plugin.zsh source
    if grep -q "shell-tools/plugin.zsh" "$zshrc" 2>/dev/null; then
        sed -i.uninstall-backup '/shell-tools\/plugin\.zsh/d' "$zshrc"
        return 0
    fi
    return 1
}

# Check for user customizations
_st_has_customizations() {
    local install_dir="$1"
    [[ -f "$install_dir/modules/local.zsh" ]]
}

# Main uninstall command
st-uninstall() {
    local install_dir="$HOME/.shell-tools"
    local version="$(cat "$install_dir/VERSION" 2>/dev/null || echo "unknown")"

    # Prevent running from dev mode on installed version
    if [[ -n "$SHELL_TOOLS_DEV" ]]; then
        _st_warn "Running st-uninstall from development mode"
        _st_log "This will uninstall the INSTALLED version at ~/.shell-tools"
        echo ""
    fi

    # Check if shell-tools is installed
    if [[ ! -d "$install_dir" ]]; then
        _st_error "shell-tools is not installed at ~/.shell-tools"
        return 1
    fi

    _st_log "Uninstall shell-tools v$version"
    echo ""

    # Show what will be removed
    echo "The following will be removed:"
    echo "  - ~/.shell-tools/ (installation directory)"

    if grep -q "shell-tools/plugin.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo "  - Source line from ~/.zshrc"
    fi

    local has_git_include=0
    if git config --global --get-all include.path 2>/dev/null | grep -q "cache/git-aliases$"; then
        echo "  - Git include from ~/.gitconfig"
        has_git_include=1
    fi

    echo ""

    # Check for customizations
    local has_custom=0
    if _st_has_customizations "$install_dir"; then
        has_custom=1
        _st_warn "Found user customizations:"
        echo "  - ~/.shell-tools/modules/local.zsh"
        echo ""
    fi

    # Prompt for confirmation
    local choice
    if [[ $has_custom -eq 1 ]]; then
        echo "Would you like to:"
        echo "  [1] Save customizations to ~/shell-tools-backup/ before removing"
        echo "  [2] Remove everything (customizations will be lost)"
        echo "  [3] Cancel"
        echo ""
        read "choice?Choice [1/2/3]: "

        case "$choice" in
            1)
                mkdir -p "$HOME/shell-tools-backup"
                cp "$install_dir/modules/local.zsh" "$HOME/shell-tools-backup/" 2>/dev/null
                _st_success "Saved customizations to ~/shell-tools-backup/"
                ;;
            2)
                # Continue without saving
                ;;
            3|*)
                _st_log "Uninstall cancelled"
                return 0
                ;;
        esac
    else
        read "choice?Proceed with uninstall? [y/n]: "
        if [[ "$choice" != [Yy] ]]; then
            _st_log "Uninstall cancelled"
            return 0
        fi
    fi

    # Check if shell-tools installed Oh-My-Zsh
    if [[ -f "$_ST_OMZ_MARKER" ]]; then
        echo ""
        _st_warn "Oh-My-Zsh was installed by shell-tools"
        echo "Would you like to remove it too?"
        echo "  [y] Yes, remove Oh-My-Zsh"
        echo "  [n] No, keep Oh-My-Zsh"
        echo ""
        read "omz_choice?Choice [y/n]: "

        if [[ "$omz_choice" == [Yy] ]]; then
            if [[ -d "$HOME/.oh-my-zsh" ]]; then
                rm -rf "$HOME/.oh-my-zsh"
                _st_success "Removed Oh-My-Zsh"
            fi
        else
            _st_log "Keeping Oh-My-Zsh"
        fi
    fi

    # Perform uninstall
    echo ""

    # Remove git include
    if [[ $has_git_include -eq 1 ]]; then
        if _st_remove_git_include; then
            _st_success "Removed git include from ~/.gitconfig"
        fi
    fi

    # Remove source line from .zshrc
    if _st_remove_zshrc_source; then
        _st_success "Removed source line from ~/.zshrc"
    fi

    # Remove installation directory
    rm -rf "$install_dir"
    _st_success "Removed ~/.shell-tools/"

    echo ""
    _st_success "Uninstall complete"
    _st_log "Restart your shell or run: exec zsh"
}
