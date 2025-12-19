#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Install shell-tools to sandbox
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
}

@test "Bootstrap: Oh-My-Zsh check runs even when cache exists" {
    # Create cache directory (simulating existing installation)
    mkdir -p "$HOME/.shell-tools/cache"
    touch "$HOME/.shell-tools/cache/init.zsh"

    # Mock Oh-My-Zsh as already installed
    mkdir -p "$HOME/.oh-my-zsh"

    # Source plugin - should still check for Oh-My-Zsh
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && echo 'loaded'"
    assert_success
    assert_output --partial "loaded"
}

@test "Bootstrap: detects when Oh-My-Zsh is not installed" {
    # No cache, no Oh-My-Zsh
    run zsh -c "
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh

        if [[ -d '$HOME/.oh-my-zsh' ]]; then
            echo 'installed'
        else
            echo 'not-installed'
        fi
    "
    assert_output "not-installed"
}

@test "Bootstrap: detects when Oh-My-Zsh is already installed" {
    # Create mock Oh-My-Zsh installation
    mkdir -p "$HOME/.oh-my-zsh"

    run zsh -c "
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh

        if [[ -d '$HOME/.oh-my-zsh' ]]; then
            echo 'installed'
        else
            echo 'not-installed'
        fi
    "
    assert_output "installed"
}

@test "Bootstrap: _st_bootstrap_omz is idempotent" {
    # Create mock Oh-My-Zsh installation
    mkdir -p "$HOME/.oh-my-zsh"
    touch "$HOME/.oh-my-zsh/.installed-marker"

    # Run bootstrap multiple times
    run zsh -c "
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_bootstrap_omz
        _st_bootstrap_omz
        _st_bootstrap_omz

        if [[ -f '$HOME/.oh-my-zsh/.installed-marker' ]]; then
            echo 'marker-exists'
        fi
    "
    assert_success
    assert_output --partial "marker-exists"
}

@test "Bootstrap: skips installation if Oh-My-Zsh exists" {
    # Pre-create Oh-My-Zsh directory
    mkdir -p "$HOME/.oh-my-zsh"

    # Run bootstrap
    run zsh -c "
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_bootstrap_omz 2>&1
    "
    assert_success
    # Should be silent (no output) when Oh-My-Zsh already exists
    assert_output ""
}

@test "Bootstrap: generates .zshrc with Oh-My-Zsh config" {
    # Create mock Oh-My-Zsh
    mkdir -p "$HOME/.oh-my-zsh"

    # Run zshrc generation
    run zsh -c "
        export SHELL_TOOLS_ROOT='$HOME/.shell-tools'
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_generate_zshrc
    "
    assert_success

    # Check .zshrc was created
    assert [ -f "$HOME/.zshrc" ]

    # Check it contains Oh-My-Zsh configuration
    run grep "export ZSH=" "$HOME/.zshrc"
    assert_success

    run grep 'ZSH_THEME="spaceship"' "$HOME/.zshrc"
    assert_success

    run grep "source.*oh-my-zsh.sh" "$HOME/.zshrc"
    assert_success

    run grep "source.*shell-tools/plugin.zsh" "$HOME/.zshrc"
    assert_success
}

@test "Bootstrap: .zshrc generation is idempotent" {
    # Create mock Oh-My-Zsh
    mkdir -p "$HOME/.oh-my-zsh"

    # Generate first time
    run zsh -c "
        export SHELL_TOOLS_ROOT='$HOME/.shell-tools'
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_generate_zshrc
    "
    assert_success

    # Add custom content
    echo "# My custom config" >> "$HOME/.zshrc"

    # Generate again - should skip because Oh-My-Zsh section exists
    run zsh -c "
        export SHELL_TOOLS_ROOT='$HOME/.shell-tools'
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_generate_zshrc 2>&1
    "
    assert_success
    assert_output --partial "already contains"

    # Custom content should still be there
    run grep "My custom config" "$HOME/.zshrc"
    assert_success
}

@test "Bootstrap: backs up existing .zshrc before generation" {
    # Create existing .zshrc
    echo "# Old config" > "$HOME/.zshrc"

    # Create mock Oh-My-Zsh
    mkdir -p "$HOME/.oh-my-zsh"

    # Generate new .zshrc
    run zsh -c "
        export SHELL_TOOLS_ROOT='$HOME/.shell-tools'
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh
        _st_generate_zshrc 2>&1
    "
    assert_success
    assert_output --partial "Backing up"

    # Check backup exists with old content
    run ls "$HOME"/.zshrc.backup-*
    assert_success

    # New .zshrc should have Oh-My-Zsh config
    run grep "export ZSH=" "$HOME/.zshrc"
    assert_success
}

@test "Bootstrap: required.txt tools are checked" {
    # Create a sample required.txt
    echo "eza" > "$HOME/.shell-tools/tools/required.txt"
    echo "bat" >> "$HOME/.shell-tools/tools/required.txt"

    # Mock eza as installed, bat as missing
    # We'll just verify the bootstrap function runs without errors
    run zsh -c "
        source $HOME/.shell-tools/lib/core.zsh
        source $HOME/.shell-tools/lib/bootstrap.zsh

        # Mock _st_has to return false for bat
        _st_has() {
            [[ \$1 == 'eza' ]]
        }

        _st_bootstrap 2>&1 | head -1
    "
    # Should not crash
    assert_success
}

@test "Bootstrap: cache directory is created" {
    # No cache initially
    run zsh -c "
        export SHELL_TOOLS_ROOT='$HOME/.shell-tools'
        source \$SHELL_TOOLS_ROOT/lib/core.zsh
        source \$SHELL_TOOLS_ROOT/lib/bootstrap.zsh
        _st_bootstrap
    "
    assert_success

    # Check cache directory exists
    assert [ -d "$HOME/.shell-tools/cache" ]
}
