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
                if command -v sudo &>/dev/null; then
                    # Check if sudo can run without a password (non-interactive)
                    if sudo -n true &>/dev/null; then
                        sudo_cmd="sudo"
                    else
                        _st_warn "Sudo requires a password and cannot run non-interactively."
                        _st_warn "Please install tools manually or configure sudoers for passwordless access."
                        _st_warn "  Missing: ${missing[*]}"
                        mkdir -p "$SHELL_TOOLS_ROOT/cache"
                        return 0
                    fi
                else
                    _st_warn "No sudo command found. Skipping auto-installation."
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

    # Bootstrap Oh-My-Zsh if needed
    _st_bootstrap_omz

    return 0
}

# Bootstrap Oh-My-Zsh and Spaceship theme
_st_bootstrap_omz() {
    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"

    # Check if Oh-My-Zsh is already installed
    if [[ -d "$omz_dir" ]]; then
        return 0  # Silent return - nothing to do
    fi

    # Automatically install Oh-My-Zsh
    _st_log "Installing Oh-My-Zsh with Spaceship theme..."

    # Use official installer in unattended mode
    export RUNZSH=no
    export KEEP_ZSHRC=yes

    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null; then
        _st_success "Oh-My-Zsh installed successfully"
    else
        _st_error "Failed to install Oh-My-Zsh"
        return 1
    fi

    # Install Spaceship theme
    _st_log "Installing Spaceship prompt theme..."
    local custom_themes="${ZSH_CUSTOM:-$omz_dir/custom}/themes"

    if git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$custom_themes/spaceship-prompt" --depth=1 2>/dev/null; then
        ln -sf "$custom_themes/spaceship-prompt/spaceship.zsh-theme" "$custom_themes/spaceship.zsh-theme"
        _st_success "Spaceship theme installed"
    else
        _st_error "Failed to install Spaceship theme"
    fi

    # Install zsh-autosuggestions plugin
    _st_log "Installing zsh-autosuggestions plugin..."
    local custom_plugins="${ZSH_CUSTOM:-$omz_dir/custom}/plugins"

    if [[ ! -d "$custom_plugins/zsh-autosuggestions" ]]; then
        if git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions" --depth=1 2>/dev/null; then
            _st_success "zsh-autosuggestions installed"
        fi
    fi

    # Install zsh-syntax-highlighting plugin
    _st_log "Installing zsh-syntax-highlighting plugin..."
    if [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]]; then
        if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins/zsh-syntax-highlighting" --depth=1 2>/dev/null; then
            _st_success "zsh-syntax-highlighting installed"
        fi
    fi

    # Create/update .zshrc with Oh-My-Zsh configuration
    _st_generate_zshrc
}

# Generate .zshrc with Oh-My-Zsh configuration
_st_generate_zshrc() {
    local zshrc="$HOME/.zshrc"
    local backup="$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"

    # Check if Oh-My-Zsh section already exists
    if grep -q "Path to your Oh My Zsh installation" "$zshrc" 2>/dev/null; then
        _st_log ".zshrc already contains Oh-My-Zsh configuration"
        return 0
    fi

    # Backup existing .zshrc if it exists
    if [[ -f "$zshrc" ]]; then
        cp "$zshrc" "$backup"
        _st_warn "Backing up existing .zshrc to:"
        _st_warn "  $backup"
    fi

    # Generate new .zshrc with Oh-My-Zsh configuration
    cat > "$zshrc" << ZSHRC_EOF
# Path to your Oh My Zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="spaceship"

# Plugins
plugins=(
  git
  extract
  sudo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
source \$ZSH/oh-my-zsh.sh

# =============================================================================
# SHELL-TOOLS - Personal Zsh Plugin System
# =============================================================================
source $SHELL_TOOLS_ROOT/plugin.zsh
ZSHRC_EOF

    _st_success "Generated new .zshrc with Oh-My-Zsh configuration"
    _st_warn "Please reload your shell or run: exec zsh"
}
