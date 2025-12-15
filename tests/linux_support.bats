#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup
    mkdir -p "$HOME/.shell-tools"
    # Copy contents of src to .shell-tools
    cp -r "$SRC_ROOT/"* "$HOME/.shell-tools/"
}

@test "Linux: aliases use apt update and hostname -I" {
    export HOME

    run zsh <<'EOF'
        # Force OS type inside zsh
        OSTYPE=linux-gnu
        
        # Mock apt-get
        apt-get() { return 0; }
        
        source $HOME/.shell-tools/modules/aliases.zsh
        alias update
        alias localip
EOF
    
    assert_output --partial "sudo apt update"
    assert_output --partial "hostname -I"
}

@test "Linux: pbcopy/pbpaste are mapped to xclip" {
    export HOME

    run zsh <<'EOF'
        OSTYPE=linux-gnu
        source $HOME/.shell-tools/modules/aliases.zsh
        alias pbcopy
EOF
    assert_output --partial "xclip -selection clipboard"
}

@test "Linux: bootstrap installs packages via apt (mocked)" {
    # Create required.txt with 'fd'
    echo "fd" > "$HOME/.shell-tools/tools/required.txt"

    export SHELL_TOOLS_ROOT="$HOME/.shell-tools"
    export HOME

    run zsh <<'EOF'
        OSTYPE=linux-gnu
        
        # Source core
        source $SHELL_TOOLS_ROOT/lib/core.zsh
        
        # Override _st_has
        _st_has() {
            case "$1" in
                apt-get|sudo) return 0 ;;
                fd) return 1 ;;
                *) return 1 ;;
            esac
        }
        
        # Mock sudo
        sudo() {
            echo "MOCKED_SUDO: $@"
        }
        
        source $SHELL_TOOLS_ROOT/lib/bootstrap.zsh
        _st_bootstrap
EOF
    
    # Verify Ubuntu detection output
    assert_output --partial "Ubuntu/Debian detected"
    
    # Verify mapping fd -> fd-find
    assert_output --partial "MOCKED_SUDO: apt-get install -y fd-find"
}
