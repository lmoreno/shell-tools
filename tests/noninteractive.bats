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

@test "Non-interactive: st-update fails gracefully" {
    # st-update requires interactive shell
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-update"
    assert_failure
    assert_output --partial "requires an interactive shell"
}

@test "Non-interactive: _st_is_interactive returns false in non-interactive shell" {
    # zsh -c runs non-interactively - run from HOME to avoid dev mode
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && _st_is_interactive && echo 'interactive' || echo 'non-interactive'"
    assert_success
    assert_output --partial "non-interactive"
}

@test "Non-interactive: plugin loads without hanging" {
    # This test verifies the plugin loads quickly without hanging on prompts
    # If this hangs, it means there's an interactive prompt blocking
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'loaded'"
    assert_success
    assert_output --partial "loaded"
}

@test "Non-interactive: logging goes to stderr not stdout" {
    # Force a log message by triggering cache regeneration
    rm -f "$HOME/.shell-tools/cache/.version"

    # Capture stdout and stderr separately
    # stdout should not contain [shell-tools] logs
    local stdout_file="$TEST_TEMP_DIR/stdout.txt"
    local stderr_file="$TEST_TEMP_DIR/stderr.txt"

    zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh" >"$stdout_file" 2>"$stderr_file"

    # stderr should contain shell-tools logs
    run cat "$stderr_file"
    assert_output --partial "[shell-tools]"

    # stdout should NOT contain shell-tools logs
    run cat "$stdout_file"
    refute_output --partial "[shell-tools]"
}

@test "Non-interactive: update check does not prompt" {
    # Even with update available, non-interactive mode should not prompt
    # This is implicitly tested by the plugin loading without hanging
    run zsh -c "cd $HOME && export SHELL_TOOLS_UPDATE_CHECK=always && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success
    assert_output --partial "done"
}
