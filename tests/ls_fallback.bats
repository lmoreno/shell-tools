#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Copy aliases module to sandbox
    mkdir -p "$HOME/.shell-tools/modules"
    cp "$SRC_ROOT/modules/aliases.zsh" "$HOME/.shell-tools/modules/"
}

@test "eza aliases are used when eza is available" {
    # Mock eza command
    mkdir -p "$HOME/bin"
    echo '#!/bin/sh' > "$HOME/bin/eza"
    chmod +x "$HOME/bin/eza"

    run zsh -c "export PATH=\"$HOME/bin:\$PATH\" && source $HOME/.shell-tools/modules/aliases.zsh && alias ls"
    assert_output --partial "eza --icons --git --group-directories-first"

    run zsh -c "export PATH=\"$HOME/bin:\$PATH\" && source $HOME/.shell-tools/modules/aliases.zsh && alias ll"
    assert_output --partial "eza -l --icons --git --group-directories-first"

    run zsh -c "export PATH=\"$HOME/bin:\$PATH\" && source $HOME/.shell-tools/modules/aliases.zsh && alias la"
    assert_output --partial "eza -la --icons --git --group-directories-first"
}

@test "macOS: BSD ls fallback used when eza is missing" {
    # Simulate macOS environment without eza by overriding command builtin
    run zsh -c "
        export OSTYPE=darwin22
        # Override command to make eza unavailable
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ls
    "
    assert_output --partial "ls -GFh"

    run zsh -c "
        export OSTYPE=darwin22
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ll
    "
    assert_output --partial "ls -lGFh"

    run zsh -c "
        export OSTYPE=darwin22
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias la
    "
    assert_output --partial "ls -lAGFh"
}

@test "Linux: GNU ls fallback used when eza is missing" {
    # Simulate Linux environment without eza by overriding command builtin
    run zsh -c "
        export OSTYPE=linux-gnu
        # Override command to make eza unavailable
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ls
    "
    assert_output --partial "ls --color=auto -Fh"

    run zsh -c "
        export OSTYPE=linux-gnu
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ll
    "
    assert_output --partial "ls -l --color=auto -Fh"

    run zsh -c "
        export OSTYPE=linux-gnu
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias la
    "
    assert_output --partial "ls -lA --color=auto -Fh"
}

@test "Generic fallback: minimal ls aliases for unknown OS" {
    # Simulate unknown Unix environment without eza
    run zsh -c "
        export OSTYPE=freebsd12
        # Override command to make eza unavailable
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ll
    "
    assert_output --partial "ls -l"

    run zsh -c "
        export OSTYPE=freebsd12
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias la
    "
    assert_output --partial "ls -lA"
}

@test "All directory listing aliases are defined without eza" {
    # Verify all three aliases exist in fallback mode
    run zsh -c "
        export OSTYPE=linux-gnu
        # Override command to make eza unavailable
        command() {
            if [[ \$2 == 'eza' ]]; then
                return 1
            fi
            builtin command \"\$@\"
        }
        source $HOME/.shell-tools/modules/aliases.zsh
        alias ls && alias ll && alias la
    "
    assert_success
    assert_output --partial "ls"
    assert_output --partial "ll"
    assert_output --partial "la"
}
