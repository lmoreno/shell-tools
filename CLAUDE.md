# shell-tools

A minimal, personal Zsh plugin system for shell customizations.

## Project Structure

```
shell-tools/
├── plugin.zsh              # Main entry point (source from ~/.zshrc)
├── VERSION                 # Bump to trigger cache regeneration
├── lib/                    # Internal machinery
│   ├── core.zsh            # Logging and utility functions
│   ├── bootstrap.zsh       # First-run tool installation
│   └── loader.zsh          # Cache generation and version checking
├── modules/                # User-editable content
│   ├── aliases.zsh         # All alias definitions
│   ├── functions.zsh       # Utility functions
│   ├── env.zsh             # Environment variables
│   ├── tools.zsh           # Tool initializations (dynamic, not cached)
│   └── completions.zsh     # zstyle completion enhancements
├── tools/
│   └── required.txt        # CLI tools to auto-install via Homebrew
└── cache/                  # Auto-generated (gitignored)
```

## Architecture

- **Static cache pattern**: Aliases, functions, env, and completions are concatenated into `cache/init.zsh` for fast loading (~5ms)
- **Dynamic tools**: Tool initializations (zoxide, fzf, thefuck, nvm, sdkman) contain evals and are loaded separately
- **Version-based regeneration**: Bump `VERSION` file to trigger cache rebuild

## Commands

- `st-reload` - Force cache regeneration and reload
- `st-version` - Show current version

## Development

After editing any module in `modules/`:
1. Bump the version in `VERSION`, OR
2. Run `st-reload` in your shell

## Adding New Aliases/Functions

1. Edit the appropriate file in `modules/`
2. Run `st-reload` or bump `VERSION`

## Adding New Tools

1. Add tool name to `tools/required.txt`
2. If it needs initialization (eval), add to `modules/tools.zsh`
3. Run `st-reload`
