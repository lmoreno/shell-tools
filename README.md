# shell-tools

A minimal, personal Zsh plugin system for managing shell customizations across multiple machines.

## Features

- **Fast startup** - Static cache pattern loads aliases/functions in ~5ms
- **Auto-install tools** - Missing CLI tools installed via Homebrew on first run
- **Git alias generation** - Portable git aliases via `[include]` directive
- **Modular organization** - Separate files for aliases, functions, env, tools, completions
- **Version-based updates** - Bump VERSION to trigger cache regeneration

## Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:lmoreno/shell-tools.git ~/.shell-tools
   ```

2. Add to your `~/.zshrc`:
   ```zsh
   source ~/.shell-tools/plugin.zsh
   ```

3. (Optional) For git aliases, add to your `~/.gitconfig`:
   ```gitconfig
   [include]
       path = ~/.shell-tools/cache/git-aliases
   ```

4. Restart your shell or run `source ~/.zshrc`

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

## License

MIT
