# shell-tools

A minimal, personal Zsh plugin system for shell customizations.

## Project Structure

```
shell-tools/
├── src/                    # Source files (shipped in releases)
│   ├── plugin.zsh          # Main entry point
│   ├── VERSION             # Bump to trigger cache regeneration
│   ├── lib/                # Internal machinery
│   │   ├── core.zsh        # Logging and utility functions
│   │   ├── bootstrap.zsh   # First-run tool installation
│   │   ├── loader.zsh      # Cache generation and version checking
│   │   └── updater.zsh     # Auto-update system
│   ├── modules/            # User-editable content
│   │   ├── aliases.zsh     # All alias definitions
│   │   ├── functions.zsh   # Utility functions
│   │   ├── env.zsh         # Environment variables
│   │   ├── tools.zsh       # Tool initializations (dynamic, not cached)
│   │   ├── completions.zsh # zstyle completion enhancements
│   │   └── git.gitconfig   # Git aliases
│   ├── tools/
│   │   └── required.txt    # CLI tools to auto-install via Homebrew
│   └── cache/              # Auto-generated (gitignored)
├── scripts/                # Development scripts (not released)
│   └── setup-hooks.sh      # Git hooks installer
├── tests/                  # Bats test suite (not released)
├── .github/                # GitHub workflows (not released)
├── install.sh              # Installation script (kept at root for curl URLs)
├── README.md               # Documentation (kept at root for GitHub)
├── Makefile                # Development automation
└── CLAUDE.md               # Project instructions
```

**Note:** Release ZIPs contain files at root (lib/, modules/, etc.), not in src/ subdirectory.

## Architecture

- **Static cache pattern**: Aliases, functions, env, and completions are concatenated into `cache/init.zsh` for fast loading (~5ms)
- **Dynamic tools**: Tool initializations (zoxide, fzf, thefuck, nvm, sdkman) contain evals and are loaded separately
- **Version-based regeneration**: Bump `VERSION` file to trigger cache rebuild

## Commands

- `st-reload` - Force cache regeneration and reload
- `st-version` - Show current version

## Development

After editing any module in `src/modules/`:
1. Bump the version in `src/VERSION`, OR
2. Run `st-reload` in your shell

## Development Commands

### Testing
```bash
make test                   # Run all Bats tests
bats tests/features.bats    # Run specific test file
```

### Version Management
```bash
make bump-patch            # Bump patch version (2.3.0 -> 2.3.1)
make bump-minor            # Bump minor version (2.3.0 -> 2.4.0)
make bump-major            # Bump major version (2.3.0 -> 3.0.0)
```

### Git Hooks
```bash
make hooks                 # Install pre-commit hooks
```

## Git Workflow & Pull Requests

**IMPORTANT**: PRs are merged using **squash and commit**. This means:
- All commits in a PR are squashed into a single commit on main
- The commit hash changes after merge
- **Never reuse a branch after its PR is merged** - it will have conflicts
- **Never push additional commits to a branch after creating a PR expecting it to be merged soon**

### Correct Workflow for Fixes/Features

1. **Always branch from latest main**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/my-feature  # or fix/my-bugfix
   ```

2. **Make changes and commit**:
   ```bash
   # Make your changes
   git add <files>
   git commit -m "feat: description"
   ```

3. **Create PR**:
   ```bash
   git push -u origin feat/my-feature
   gh pr create --title "..." --body "..."
   ```

4. **After PR is merged**:
   - **DO NOT** push more commits to the same branch
   - **DO NOT** reuse the branch
   - For new work, create a NEW branch from main
   - Delete the old branch: `git branch -d feat/my-feature`

5. **For additional fixes/changes**:
   - If PR not yet merged: Can push to same branch (but avoid if possible)
   - If PR merged or will be merged soon: Create NEW branch from main

### Example: Making Two Separate Changes

❌ **WRONG** (will cause conflicts after first PR merges):
```bash
git checkout -b feat/feature-a
# work on feature A
git push -u origin feat/feature-a
gh pr create  # PR #1

# After PR #1 is merged, continuing on same branch:
git checkout feat/feature-a  # ❌ Don't do this!
# work on feature B
git push  # ❌ Will have conflicts!
```

✅ **CORRECT**:
```bash
# Feature A
git checkout main
git checkout -b feat/feature-a
# work on feature A
git push -u origin feat/feature-a
gh pr create  # PR #1

# After PR #1 is merged, start fresh:
git checkout main
git pull origin main  # Get the squashed commit
git checkout -b feat/feature-b  # ✅ New branch!
# work on feature B
git push -u origin feat/feature-b
gh pr create  # PR #2
```

### Local Testing
To test the plugin locally from src/:
```bash
source ~/projects/shell-tools/src/plugin.zsh
st-version
st-reload
```

## Adding New Aliases/Functions

1. Edit the appropriate file in `src/modules/`
2. Run `st-reload` or bump `src/VERSION`

## Adding New Tools

1. Add tool name to `src/tools/required.txt`
2. If it needs initialization (eval), add to `src/modules/tools.zsh`
3. Run `st-reload`
