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

@test "Loader: cache is regenerated when VERSION changes" {
    # Initial load
    run zsh -c "source $HOME/.shell-tools/plugin.zsh"

    # Get cache modification time
    CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init.zsh")

    # Change VERSION
    echo "9.9.9" > "$HOME/.shell-tools/VERSION"
    sleep 1

    # Reload
    run zsh -c "source $HOME/.shell-tools/plugin.zsh"

    # Cache should be newer
    NEW_CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init.zsh")
    assert [ "$NEW_CACHE_TIME" -gt "$CACHE_TIME" ]
}

@test "Loader: git config include is added automatically" {
    run zsh -c "source $HOME/.shell-tools/plugin.zsh"

    # Check gitconfig has include
    run git config --global --get-all include.path
    assert_output --partial ".shell-tools/cache/git-aliases"
}
