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
        elif _st_is_linux && _st_has apt-get; then
            _st_log "Ubuntu/Debian detected. Installing via apt..."
            
            # Check sudo access
            local sudo_cmd=""
            if [[ $EUID -ne 0 ]]; then
                # Check if we can use sudo (either cached credential or passwordless)
                # or strictly just check if command exists, as user might type password.
                if command -v sudo &>/dev/null; then
                     sudo_cmd="sudo"
                else
                     _st_warn "No sudo found. Skipping auto-installation."
                     _st_warn "Please manually install: ${missing[*]}"
                     mkdir -p "$SHELL_TOOLS_ROOT/cache"
                     return 0
                fi
            fi

            # Update apt cache first? optional but recommended
            # $sudo_cmd apt-get update -y >/dev/null 2>&1

            for tool in "${missing[@]}"; do
                local pkg="$tool"
                # Ubuntu mapping
                [[ "$tool" == "fd" ]] && pkg="fd-find"
                [[ "$tool" == "ripgrep" ]] && pkg="ripgrep"
                [[ "$tool" == "eza" ]] && pkg="eza" # eza might not be in default repos for old ubuntu
                
                # Special case: eza needs gierens/eza repo usually, but let's assume standard repos first.
                # If eza fails, user might need to add repo. 

                _st_log "  Installing $pkg..."
                if $sudo_cmd apt-get install -y "$pkg"; then
                    _st_success "  Installed $pkg"
                    
                    # Fix Ubuntu quirks (batcat -> bat, fdfind -> fd)
                    mkdir -p "$HOME/.local/bin"
                    
                    if [[ "$tool" == "bat" ]] && ! _st_has bat; then
                        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
                        _st_success "    Linked batcat -> bat"
                    fi
                    
                    if [[ "$tool" == "fd" ]] && ! _st_has fd; then
                        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
                        _st_success "    Linked fdfind -> fd"
                    fi
                else
                    _st_error "  Failed to install $pkg"
                fi
            done
        elif _st_is_linux; then
            _st_warn "Linux (non-Debian) detected. Please install manually:"
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
