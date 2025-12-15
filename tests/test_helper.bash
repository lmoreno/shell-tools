# Load libraries
load 'libs/bats-support/load'
load 'libs/bats-assert/load'

# Global setup for all tests
common_setup() {
    # Create a safe sandbox directory
    TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR"
    export ZDOTDIR="$TEST_TEMP_DIR"

    # Create a dummy .zshrc
    touch "$HOME/.zshrc"

    # Project root (assuming tests/ is one level deep)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT

    # Source files are in src/ during development
    SRC_ROOT="$PROJECT_ROOT/src"
    export SRC_ROOT
}

teardown() {
    # Cleanup sandbox
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}
