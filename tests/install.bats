#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup
}

@test "Installation: download and install latest release" {
    # Run the install script from the project root
    run bash "$PROJECT_ROOT/install.sh"

    # Assert success
    assert_success
    
    # Assert installation directory exists
    assert [ -d "$HOME/.shell-tools" ]
    assert [ -f "$HOME/.shell-tools/plugin.zsh" ]
    
    # Assert .zshrc was modified
    run grep "source ~/.shell-tools/plugin.zsh" "$HOME/.zshrc"
    assert_success
}

@test "Installation: verify exclusions (clean install)" {
    run bash "$PROJECT_ROOT/install.sh"
    assert_success

    # Ensure excluded files are NOT present
    assert [ ! -d "$HOME/.shell-tools/.github" ]
    assert [ ! -f "$HOME/.shell-tools/.gitignore" ]
    assert [ ! -f "$HOME/.shell-tools/CLAUDE.md" ]
}
