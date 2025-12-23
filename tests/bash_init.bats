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

@test "Bash-init: file exists and is valid bash" {
    [[ -f "$HOME/.shell-tools/lib/bash-init.sh" ]]
    run bash -n "$HOME/.shell-tools/lib/bash-init.sh"
    assert_success
}

@test "Bash-init: does not exec zsh in non-interactive bash" {
    # Create a test script that sources bash-init in non-interactive mode
    cat > "$TEST_TEMP_DIR/test.sh" << 'EOF'
#!/bin/bash
source ~/.shell-tools/lib/bash-init.sh
echo "still in bash"
EOF
    chmod +x "$TEST_TEMP_DIR/test.sh"

    # Run the script - should NOT switch to zsh
    run bash "$TEST_TEMP_DIR/test.sh"
    assert_success
    assert_output "still in bash"
}

@test "Bash-init: contains interactive check" {
    run grep 'case \$-' "$HOME/.shell-tools/lib/bash-init.sh"
    assert_success
}

@test "Migration: detects old bashrc pattern" {
    # Create old-style .bashrc
    cat > "$HOME/.bashrc" << 'EOF'
# Auto-switch to zsh (minimal .bashrc)
if [ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ]; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
EOF

    # Source plugin to trigger migration
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    # Check that migration happened - new source line added
    run grep "bash-init.sh" "$HOME/.bashrc"
    assert_success

    # Check that old exec zsh was removed
    run grep "exec zsh" "$HOME/.bashrc"
    assert_failure

    # Check that backup was created
    run ls "$HOME/.bashrc.st-backup-"* 2>/dev/null
    assert_success
}

@test "Migration: migrated bashrc works in non-interactive mode" {
    # Create old-style .bashrc
    cat > "$HOME/.bashrc" << 'EOF'
# Auto-switch to zsh (minimal .bashrc)
if [ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ]; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
EOF

    # Run migration
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    # Create a test script that sources the migrated .bashrc
    cat > "$TEST_TEMP_DIR/test.sh" << 'EOF'
#!/bin/bash
source ~/.bashrc
echo "still in bash"
EOF
    chmod +x "$TEST_TEMP_DIR/test.sh"

    # Run the script - should NOT hang or switch to zsh
    # Note: if it hangs, the test framework will timeout
    run bash "$TEST_TEMP_DIR/test.sh"
    assert_success
    assert_output "still in bash"
}

@test "Migration: handles bashrc without comment marker" {
    # Create old-style .bashrc WITHOUT any comment
    cat > "$HOME/.bashrc" << 'EOF'
if [ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ]; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
EOF

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    run grep "bash-init.sh" "$HOME/.bashrc"
    assert_success

    run grep "exec zsh" "$HOME/.bashrc"
    assert_failure
}

@test "Migration: fixes broken migration with both old and new code" {
    # Simulate the broken state: has bash-init.sh BUT also old code
    cat > "$HOME/.bashrc" << 'EOF'
# shell-tools bash initialization
[[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh

if [ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ]; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
EOF

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    # Should still have bash-init.sh
    run grep "bash-init.sh" "$HOME/.bashrc"
    assert_success

    # Old exec zsh should be removed
    run grep "exec zsh" "$HOME/.bashrc"
    assert_failure
}

@test "Migration: skips if already migrated" {
    # Create already-migrated .bashrc
    cat > "$HOME/.bashrc" << 'EOF'
# shell-tools bash initialization
[[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh
EOF

    local original_content
    original_content=$(cat "$HOME/.bashrc")

    # Source plugin
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    # Content should be unchanged
    local new_content
    new_content=$(cat "$HOME/.bashrc")
    [[ "$original_content" == "$new_content" ]]
}

@test "Migration: skips if no exec zsh" {
    # Create .bashrc without exec zsh
    cat > "$HOME/.bashrc" << 'EOF'
# Some other config
export PATH="$HOME/bin:$PATH"
EOF

    local original_content
    original_content=$(cat "$HOME/.bashrc")

    # Source plugin
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo 'done'"
    assert_success

    # Content should be unchanged (no migration needed)
    local new_content
    new_content=$(cat "$HOME/.bashrc")
    [[ "$original_content" == "$new_content" ]]
}

@test "Plugin: auto-switch has interactive check" {
    run grep -A5 'Auto-switch to zsh' "$HOME/.shell-tools/plugin.zsh"
    assert_success
    assert_output --partial 'case $-'
}
