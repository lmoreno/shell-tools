#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Install shell-tools
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"

    mkdir -p "$HOME/.shell-tools/cache"
}

@test "Functions: add-alias creates new alias" {
    # Source plugin
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'y' | add-alias testcmd 'echo hello'"

    # Verify alias was added
    run grep "alias testcmd=" "$HOME/.shell-tools/modules/aliases.zsh"
    assert_success
}

@test "Functions: remove-alias command exists and validates" {
    # Verify remove-alias function exists
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && type remove-alias"
    assert_success

    # Test that it requires an argument
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && remove-alias"
    assert_failure
    assert_output --partial "Usage: remove-alias <name>"

    # Test that it reports when alias doesn't exist
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && printf 'y\\n' | remove-alias nonexistent"
    assert_output --partial "not found"
}

@test "Functions: backup creates timestamped copy" {
    # Create test file
    echo "test content" > "$HOME/testfile.txt"

    # Backup it
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && backup $HOME/testfile.txt"

    # Verify backup exists
    run ls "$HOME"/testfile.txt.backup-*
    assert_success
}

@test "Functions: take creates directory and changes into it" {
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && take $HOME/newdir && pwd"

    # Check output contains the directory path
    assert_output --partial "$HOME/newdir"
    # Verify directory was created
    assert [ -d "$HOME/newdir" ]
}
