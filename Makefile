.PHONY: init test bump-patch bump-minor bump-major hooks help

# Default target
help:
	@echo "Shell-Tools Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  init         - Initialize project (submodules + hooks)"
	@echo "  test         - Run all Bats tests"
	@echo "  bump-patch   - Bump patch version (2.3.0 -> 2.3.1)"
	@echo "  bump-minor   - Bump minor version (2.3.0 -> 2.4.0)"
	@echo "  bump-major   - Bump major version (2.3.0 -> 3.0.0)"
	@echo "  hooks        - Install git hooks for development"
	@echo "  help         - Show this help message"

# Initialize project (submodules + hooks)
init:
	@echo "Initializing project..."
	@chmod +x scripts/setup-hooks.sh tests/run
	@git submodule update --init --recursive
	@scripts/setup-hooks.sh
	@echo "Project initialized successfully"

# Run all tests
test:
	@echo "Running Bats test suite..."
	@tests/libs/bats-core/bin/bats tests/*.bats

# Bump patch version (e.g., 2.3.0 -> 2.3.1)
bump-patch:
	@echo "Bumping patch version..."
	@current=$$(cat src/VERSION | tr -d '\n'); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	patch=$$(echo $$current | cut -d. -f3); \
	new_patch=$$((patch + 1)); \
	new_version="$$major.$$minor.$$new_patch"; \
	echo "$$new_version" > src/VERSION; \
	echo "Version bumped: $$current -> $$new_version"

# Bump minor version (e.g., 2.3.0 -> 2.4.0)
bump-minor:
	@echo "Bumping minor version..."
	@current=$$(cat src/VERSION | tr -d '\n'); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	new_minor=$$((minor + 1)); \
	new_version="$$major.$$new_minor.0"; \
	echo "$$new_version" > src/VERSION; \
	echo "Version bumped: $$current -> $$new_version"

# Bump major version (e.g., 2.3.0 -> 3.0.0)
bump-major:
	@echo "Bumping major version..."
	@current=$$(cat src/VERSION | tr -d '\n'); \
	major=$$(echo $$current | cut -d. -f1); \
	new_major=$$((major + 1)); \
	new_version="$$new_major.0.0"; \
	echo "$$new_version" > src/VERSION; \
	echo "Version bumped: $$current -> $$new_version"

# Install git hooks
hooks:
	@echo "Installing git hooks..."
	@bash scripts/setup-hooks.sh
	@echo "Git hooks installed successfully"
