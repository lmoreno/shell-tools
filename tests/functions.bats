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
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && echo 'y' | add-alias testcmd 'echo hello'"

    # Verify alias was added
    run grep "alias testcmd=" "$HOME/.shell-tools/modules/aliases.zsh"
    assert_success
}

@test "Functions: remove-alias deletes existing alias" {
    # Add test alias first
    echo "alias testcmd='echo hello'" >> "$HOME/.shell-tools/modules/aliases.zsh"

    # Remove it
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && echo 'y' | remove-alias testcmd"

    # Verify removal
    run grep "alias testcmd=" "$HOME/.shell-tools/modules/aliases.zsh"
    assert_failure
}

@test "Functions: backup creates timestamped copy" {
    # Create test file
    echo "test content" > "$HOME/testfile.txt"

    # Backup it
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && backup $HOME/testfile.txt"

    # Verify backup exists
    run ls "$HOME"/testfile.txt.backup-*
    assert_success
}

@test "Functions: take creates directory and changes into it" {
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && take $HOME/newdir && pwd"

    # Check output contains the directory path
    assert_output --partial "$HOME/newdir"
    # Verify directory was created
    assert [ -d "$HOME/newdir" ]
}
