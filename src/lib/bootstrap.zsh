# shell-tools bootstrap
# First-run setup and tool installation

# Map of command names to Homebrew formula names
# Format: "command:formula"
typeset -A _ST_BREW_FORMULAS
_ST_BREW_FORMULAS=(
    eza       eza
    bat       bat
    rg        ripgrep
    fd        fd
    zoxide    zoxide
    fzf       fzf
    trash     trash
    thefuck   thefuck
)

_st_bootstrap() {
    local tools_file="$SHELL_TOOLS_ROOT/tools/required.txt"
    local missing=()

    # Check for missing tools
    if [[ -f "$tools_file" ]]; then
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            local tool="${line%% *}"  # Get first word (tool name)

            # Map formula name to command name for checking
            local cmd="$tool"
            [[ "$tool" == "ripgrep" ]] && cmd="rg"

            if ! _st_has "$cmd"; then
                missing+=("$tool")
            fi
        done < "$tools_file"
    fi

    # Install missing tools
    if (( ${#missing[@]} > 0 )); then
        _st_warn "Missing tools: ${missing[*]}"

        if _st_is_macos && _st_has brew; then
            _st_log "Installing via Homebrew..."

            for tool in "${missing[@]}"; do
                _st_log "  Installing $tool..."
                if brew install "$tool" 2>/dev/null; then
                    _st_success "  Installed $tool"
                else
                    _st_error "  Failed to install $tool"
                fi
            done
        elif _st_is_linux; then
            _st_warn "Linux detected. Please install manually:"
            _st_warn "  ${missing[*]}"
            _st_warn ""
            _st_warn "On Ubuntu/Debian: sudo apt install <package>"
            _st_warn "On Fedora: sudo dnf install <package>"
            _st_warn "On Arch: sudo pacman -S <package>"
        else
            _st_warn "Homebrew not found. Please install tools manually:"
            _st_warn "  ${missing[*]}"
            _st_warn ""
            _st_warn "Install Homebrew: https://brew.sh"
        fi
    fi

    # Create cache directory
    mkdir -p "$SHELL_TOOLS_ROOT/cache"

    return 0
}
