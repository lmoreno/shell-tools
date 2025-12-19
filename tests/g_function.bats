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

@test "g: passes arguments to git" {
    # Create a script to run the test to avoid quoting issues
    cat << 'EOF' > "$TEST_TEMP_DIR/test_arg.zsh"
        # Source the plugin
        source "$1/.shell-tools/plugin.zsh"
        
        # Mock git
        git() { echo "MOCKED_GIT: $*"; }
        
        # Run g with arguments
        g status
EOF
    
    run zsh "$TEST_TEMP_DIR/test_arg.zsh" "$HOME"
    
    assert_success
    assert_output --partial "MOCKED_GIT: status"
}

@test "g: interactive mode selects alias" {
    cat << 'EOF' > "$TEST_TEMP_DIR/test_interactive.zsh"
        source "$1/.shell-tools/plugin.zsh"
        
        # Mock git to return aliases for config command
        git() {
            if [[ "$1" == "config" ]]; then
                echo "alias.co checkout"
                echo "alias.br branch"
            else
                # Fallback for other git commands (shouldn't be reached here)
                echo "GIT_CALL: $*"
            fi
        }
        
        # Mock fzf to return a formatted line
        fzf() {
            echo "co                   → checkout"
        }
        
        # Mock print to capture the result
        print() {
            echo "CAPTURED_PRINT: $*"
        }
        
        # Run g without arguments
        g
EOF
    
    run zsh "$TEST_TEMP_DIR/test_interactive.zsh" "$HOME"
    
    assert_success
    assert_output --partial "CAPTURED_PRINT: -z g co"
}

@test "g: fails if fzf is missing in interactive mode" {
    cat << 'EOF' > "$TEST_TEMP_DIR/test_fail.zsh"
        source "$1/.shell-tools/plugin.zsh"
        
        # Define a command function that simulates missing fzf
        command() {
            if [[ "$2" == "fzf" ]]; then
                return 1
            fi
            builtin command "$@"
        }
        
        g
EOF
    
    run zsh "$TEST_TEMP_DIR/test_fail.zsh" "$HOME"
    
    assert_failure
    assert_output --partial "Error: 'fzf' is required"
}