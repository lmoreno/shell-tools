# =============================================================================
# shell-tools migration utilities
# =============================================================================
# Auto-migrates old configurations to new format
# =============================================================================

# Migrate old .bashrc configurations
# Detects and replaces old shell-tools bash-to-zsh switch code
_st_migrate_bashrc() {
    local bashrc="$HOME/.bashrc"

    # Skip if no .bashrc
    [[ ! -f "$bashrc" ]] && return 0

    # Skip if already using new format (sources bash-init.sh) AND old code is gone
    if grep -q "bash-init.sh" "$bashrc" 2>/dev/null; then
        # Already has new source line - but check if old code remains
        if ! grep -q "exec zsh" "$bashrc" 2>/dev/null || grep -q 'case \$-' "$bashrc" 2>/dev/null; then
            return 0  # Clean state, skip
        fi
        # Has bash-init.sh BUT also has old exec zsh without case $- - needs cleanup
    fi

    # Check for old pattern: exec zsh without interactive check (case $-)
    # This catches the old shell-tools auto-switch code
    if grep -q "exec zsh" "$bashrc" 2>/dev/null && ! grep -q 'case \$-' "$bashrc" 2>/dev/null; then
        # Has old pattern that needs migration
        _st_log "Detected old .bashrc configuration, migrating..."

        # Create backup
        local backup="$HOME/.bashrc.st-backup-$(date +%Y%m%d-%H%M%S)"
        if ! cp "$bashrc" "$backup" 2>/dev/null; then
            _st_warn "Could not create backup, skipping .bashrc migration"
            return 1
        fi

        # Create new .bashrc content
        # Remove the old shell-tools block and add new source line
        local temp_file=$(mktemp)
        local in_shell_tools_block=0
        local added_source=0

        while IFS= read -r line || [[ -n "$line" ]]; do
            # Detect start of old shell-tools block (comment marker or if statement)
            if [[ "$line" == *"Auto-switch to zsh"* ]] || \
               [[ "$line" == *"shell-tools"* && "$line" == "#"* ]] || \
               [[ "$line" == "if "* && "$line" == *"command -v zsh"* ]]; then
                in_shell_tools_block=1
                # Add new source line once at the start of old block
                if [[ $added_source -eq 0 ]]; then
                    echo '# shell-tools bash initialization' >> "$temp_file"
                    echo '[[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh' >> "$temp_file"
                    added_source=1
                fi
                continue
            fi

            # Detect end of old shell-tools block (fi or empty line after block)
            if [[ $in_shell_tools_block -eq 1 ]]; then
                if [[ "$line" == "fi" ]]; then
                    in_shell_tools_block=0
                    continue
                fi
                # Skip lines inside the old block
                if [[ "$line" == *"exec zsh"* ]] || [[ "$line" == *"ZSH_VERSION"* ]] || \
                   [[ "$line" == *"command -v zsh"* ]] || [[ "$line" == *"export SHELL"* ]] || \
                   [[ "$line" == "if "* ]] || [[ "$line" == "    "* ]] || [[ "$line" == "#"* && "$line" != "" ]]; then
                    continue
                fi
                # Empty line ends the block
                if [[ -z "$line" ]]; then
                    in_shell_tools_block=0
                fi
            fi

            # Keep all other lines
            echo "$line" >> "$temp_file"
        done < "$bashrc"

        # If we never added the source line (no clear block found), add it at the end
        if [[ $added_source -eq 0 ]]; then
            echo '' >> "$temp_file"
            echo '# shell-tools bash initialization' >> "$temp_file"
            echo '[[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh' >> "$temp_file"
        fi

        # Replace .bashrc with new content
        if mv "$temp_file" "$bashrc" 2>/dev/null; then
            _st_success "Migrated ~/.bashrc (backup: $backup)"
        else
            _st_warn "Could not update .bashrc, please update manually"
            rm -f "$temp_file"
            return 1
        fi
    fi

    return 0
}

# Run all migrations
_st_run_migrations() {
    _st_migrate_bashrc
}
