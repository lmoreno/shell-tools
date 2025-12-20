#!/bin/bash

HOOK_DIR=".git/hooks"
PRE_COMMIT="$HOOK_DIR/pre-commit"

echo "Setting up git hooks..."
mkdir -p "$HOOK_DIR"

cat > "$PRE_COMMIT" << 'EOF'
#!/bin/bash
# Wrapper that calls the actual pre-commit script
exec ./scripts/pre-commit.sh
EOF

chmod +x "$PRE_COMMIT"
echo "✅ Pre-commit hook installed."
