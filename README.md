# shell-tools

A minimal, personal Zsh plugin system for managing shell customizations across multiple machines.

## Features

- **Fast startup** - Static cache pattern loads aliases/functions in ~5ms
- **Auto-install tools** - Missing CLI tools installed via Homebrew on first run
- **Git alias generation** - Portable git aliases via `[include]` directive
- **Modular organization** - Separate files for aliases, functions, env, tools, completions
- **Version-based updates** - Bump VERSION to trigger cache regeneration

## Installation

### One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lmoreno/shell-tools/main/install.sh | bash
```

This will:
- Download the latest release
- Install to ~/.shell-tools
- Configure your ~/.zshrc
- Backup your existing .zshrc

### Manual Installation

1. Download the install script:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/lmoreno/shell-tools/main/install.sh -o /tmp/install-shell-tools.sh
   chmod +x /tmp/install-shell-tools.sh
   /tmp/install-shell-tools.sh
   ```

2. Restart shell:
   ```bash
   exec zsh
   ```

### Post-Installation

Verify:
```bash
st-version        # Shows version
use git           # Test enhanced alias finder
git s             # Test git aliases
```

**Note**: Git aliases are automatically configured via `~/.gitconfig` include directive. No manual git config needed!

### Adding Project-Specific Aliases

Keep project/machine-specific aliases in your ~/.zshrc **after** the shell-tools source line:

```zsh
source ~/.shell-tools/plugin.zsh

# Your local aliases below
alias myproject='cd ~/projects/myproject'
```

## Updates

shell-tools automatically checks for updates on every `st-reload` by default.

### Update Configuration

Control update checking by setting in your ~/.zshrc:

```zsh
# Check on every st-reload (default)
export SHELL_TOOLS_UPDATE_CHECK="always"

# Check once per day
export SHELL_TOOLS_UPDATE_CHECK="daily"

# Check once per week
export SHELL_TOOLS_UPDATE_CHECK="weekly"

# Never auto-check
export SHELL_TOOLS_UPDATE_CHECK="never"
```

### Manual Update

```bash
st-update    # Check and install updates manually
```

## Uninstallation

```bash
# Remove installation
rm -rf ~/.shell-tools

# Remove from ~/.zshrc
# Delete the line: source ~/.shell-tools/plugin.zsh
```

## Usage

| Command | Description |
|---------|-------------|
| `st-reload` | Regenerate cache and reload (after editing modules) |
| `st-version` | Show current shell-tools version |

## Directory Structure

```
~/.shell-tools/
├── plugin.zsh              # Entry point (source this)
├── VERSION                 # Bump to trigger regeneration
├── lib/
│   ├── core.zsh            # Logging utilities
│   ├── bootstrap.zsh       # First-run tool installation
│   └── loader.zsh          # Cache generation
├── modules/
│   ├── aliases.zsh         # Shell aliases
│   ├── functions.zsh       # Utility functions
│   ├── env.zsh             # Environment variables
│   ├── tools.zsh           # Tool initializations (zoxide, fzf, etc.)
│   ├── completions.zsh     # Zsh completion enhancements
│   └── git.gitconfig       # Git aliases (generates cache/git-aliases)
├── tools/
│   └── required.txt        # CLI tools to auto-install
└── cache/                  # Auto-generated (gitignored)
    ├── init.zsh            # Cached shell config
    └── git-aliases         # Generated git config
```

## Customization

### Adding Aliases

Edit `modules/aliases.zsh`:
```zsh
alias myalias='my-command'
```

Then run `st-reload`.

### Adding Functions

Edit `modules/functions.zsh`:
```zsh
myfunction() {
    echo "Hello, $1"
}
```

Then run `st-reload`.

### Adding Git Aliases

Edit `modules/git.gitconfig`:
```gitconfig
[alias]
    myalias = my-git-command
```

Then run `st-reload`.

### Adding Required Tools

Edit `tools/required.txt` (one tool per line):
```
newtool
```

Tools are auto-installed via Homebrew on first run or when missing.

## How It Works

1. On shell startup, `plugin.zsh` is sourced
2. If cache doesn't exist or VERSION changed, regenerates `cache/init.zsh` and `cache/git-aliases`
3. Loads cached content (fast) + dynamic tool initializations
4. Missing CLI tools are installed via Homebrew on first run

## Required Tools

The following are auto-installed if missing:

- `eza` - Modern `ls` replacement
- `bat` - Modern `cat` with syntax highlighting
- `ripgrep` - Fast `grep` replacement
- `fd` - Fast `find` replacement
- `zoxide` - Smart `cd` replacement
- `fzf` - Fuzzy finder
- `trash` - Safe delete to trash
- `thefuck` - Command correction

## Development

### Project Structure

Source files are in `src/` during development. Release ZIPs contain these files at root for backward compatibility.

### Local Testing

Test the plugin from source:
```bash
source ~/projects/shell-tools/src/plugin.zsh
st-version
```

### Running Tests

```bash
make test                   # Run all tests
bats tests/features.bats    # Run specific test file
```

### Version Bumping

```bash
make bump-patch            # 2.3.0 -> 2.3.1
make bump-minor            # 2.3.0 -> 2.4.0
make bump-major            # 2.3.0 -> 3.0.0
```

### Creating Releases

After making changes:
1. Bump version: `make bump-minor`
2. Commit: `git add src/VERSION && git commit -m "chore: bump version"`
3. Tag: `git tag v2.4.0 && git push origin main --tags`
4. GitHub Actions automatically creates release

**Note:** install.sh remains at project root (not in src/) to maintain the curl installation URL.

## License

MIT
