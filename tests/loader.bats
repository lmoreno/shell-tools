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
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"

    # Get cache modification time (cross-platform: macOS uses -f, Linux uses -c)
    if stat -f %m "$HOME/.shell-tools/cache/init.zsh" &>/dev/null; then
        CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init.zsh")
    else
        CACHE_TIME=$(stat -c %Y "$HOME/.shell-tools/cache/init.zsh")
    fi

    # Change VERSION
    echo "9.9.9" > "$HOME/.shell-tools/VERSION"
    sleep 1

    # Reload
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"

    # Cache should be newer (cross-platform)
    if stat -f %m "$HOME/.shell-tools/cache/init.zsh" &>/dev/null; then
        NEW_CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init.zsh")
    else
        NEW_CACHE_TIME=$(stat -c %Y "$HOME/.shell-tools/cache/init.zsh")
    fi
    assert [ "$NEW_CACHE_TIME" -gt "$CACHE_TIME" ]
}

@test "Loader: git config include is added automatically" {
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"

    # Check gitconfig has include
    run git config --global --get-all include.path
    assert_output --partial ".shell-tools/cache/git-aliases"
}
