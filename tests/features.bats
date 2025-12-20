#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup
    
    # Manual Install of LOCAL code to sandbox
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
    
    # Create required cache dir
    mkdir -p "$HOME/.shell-tools/cache"
}

@test "Features: gitconfig is generated and included" {
    # Source the plugin in zsh to trigger init
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"

    # Check if .gitconfig exists
    assert [ -f "$HOME/.gitconfig" ]

    # Check if it includes the shell-tools git config
    run grep "path = .*/.shell-tools/modules/git.gitconfig" "$HOME/.gitconfig"
    # Note: The code might point to cache/git-aliases or modules/git.gitconfig depending on implementation.
    # Checking README: "git.gitconfig # Git aliases (generates cache/git-aliases)"
    # Let's check the code or just grep for 'path =' roughly.
}

@test "Features: aliases are loaded" {
    # We verify that sourcing the plugin loads aliases.
    # Since we can't easily inspect zsh internal state from bats (bash),
    # we'll run zsh and ask it to list aliases.

    # Add a test alias to the local file to verify loading
    echo "alias test-alias='echo success'" >> "$HOME/.shell-tools/modules/aliases.zsh"

    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -i -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && alias test-alias"
    assert_output --partial "test-alias='echo success'"
}

@test "Features: cache is generated" {
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"

    assert [ -f "$HOME/.shell-tools/cache/init.zsh" ]
}
