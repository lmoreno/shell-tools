# =============================================================================
# MODERN TOOL REPLACEMENTS
# =============================================================================

# eza (ls replacement)
if command -v eza &>/dev/null; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
else
    # Fallback to standard ls with platform-specific options
    if [[ "$OSTYPE" == darwin* ]]; then
        # macOS (BSD ls)
        alias ls='ls -GFh'
        alias ll='ls -lGFh'
        alias la='ls -lAGFh'
    elif [[ "$OSTYPE" == linux* ]]; then
        # Linux (GNU ls)
        alias ls='ls --color=auto -Fh'
        alias ll='ls -l --color=auto -Fh'
        alias la='ls -lA --color=auto -Fh'
    else
        # Generic fallback for other Unix systems
        alias ll='ls -l'
        alias la='ls -lA'
    fi
fi

# bat (cat replacement)
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never --style=changes'
fi

# rg (grep replacement)
if command -v rg &>/dev/null; then
    alias grep='rg'
fi

# =============================================================================
# SAFETY NETS
# =============================================================================

# trash (safe delete)
if command -v trash &>/dev/null; then
    alias del="trash"
fi

alias rmi="rm -iv"
alias cpi="cp -iv"
alias mvi="mv -iv"

# =============================================================================
# NAVIGATION
# =============================================================================

alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias mkdir="mkdir -pv"
alias proj='cd ~/projects'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'

# =============================================================================
# QUICK EDITS & SHELL MANAGEMENT
# =============================================================================

alias vz='vim ~/.zshrc'
alias sz='source ~/.zshrc'
alias srczsh='source ~/.zshrc'
alias reload='source ~/.zshrc'
alias zshconf='vim ~/.zshrc'

# Shortcuts using bat (if available, else fallback to cat/vim?)
# Actually, if bat missing, we just won't define the 'aliases' alias or use cat.
if command -v bat &>/dev/null; then
    alias aliases='bat ~/.shell-tools/modules/aliases.zsh'
    alias zshrc='bat ~/.zshrc'
    alias functions='bat ~/.shell-tools/modules/functions.zsh'
    alias gitconfig='bat ~/.gitconfig'
    alias hosts='bat /etc/hosts'
else
    alias aliases='cat ~/.shell-tools/modules/aliases.zsh'
    alias zshrc='cat ~/.zshrc'
    alias functions='cat ~/.shell-tools/modules/functions.zsh'
    alias gitconfig='cat ~/.gitconfig'
    alias hosts='cat /etc/hosts'
fi

alias valiases='vim ~/.shell-tools/modules/aliases.zsh'
alias vzshrc='vim ~/.zshrc'
alias vfunctions='vim ~/.shell-tools/modules/functions.zsh'
alias vgitconfig='vim ~/.gitconfig'
alias vhosts='sudo vim /etc/hosts'

# =============================================================================
# UTILITIES
# =============================================================================

alias ping="ping -c 5"
alias myip='curl http://ipecho.net/plain; echo'
alias ffs='sudo !!'

if command -v yarn &>/dev/null; then
    alias y='yarn'
fi

alias process-on-port='lsof -i -P | grep LISTEN | grep'
alias sigkill='kill -15'
alias python='python3'

# =============================================================================
# ALIAS DISCOVERY & MANAGEMENT
# =============================================================================

alias mkd='take'
alias alias-git='alias | grep "^g"'
alias alias-docker='alias | grep "^d"'
alias alias-npm='alias | grep "^n\|^y"'
alias alias-list='alias | sort'

# =============================================================================
# FILE FINDING & SEARCHING
# =============================================================================

if command -v fd &>/dev/null; then
    alias ff='fd'
fi

if command -v fzf &>/dev/null; then
    if command -v bat &>/dev/null; then
        alias fzp='fzf --preview "bat --color=always {}"'
    else
        alias fzp='fzf --preview "cat {}"'
    fi
fi

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
# netstat checks
if command -v netstat &>/dev/null; then
    if [[ "$OSTYPE" == linux* ]]; then
        alias ports='netstat -tulanp'
    fi
fi
alias myps='ps -ef | grep $USER'

# =============================================================================
# GIT ALIASES
# =============================================================================

if command -v git &>/dev/null; then
    # alias g='git'
    alias gb="git branch"
    alias gs="git status"
    alias gco="git checkout"
    alias gcob="git checkout -b"
    alias gec="git config --global -e"
    alias gpull="git pull --rebase --prune"
    alias gcm="git add -A && git commit -m"
    alias gundo="git reset HEAD~1 --mixed"
    alias greset="git reset 'HEAD@{1}'"
    alias gamend="git commit -a --amend"
    alias gl='git log --oneline --graph --decorate --all'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gp='git push'
    alias gpl='git pull'
    alias gf='git fetch'
    alias gst='git stash'
    alias gstp='git stash pop'
    alias gclean='git clean -fd'
    alias gwip='git add -A && git commit -m "WIP"'
    alias gunwip='git log -n 1 | grep -q -c "WIP" && git reset HEAD~1'
    alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
fi

# =============================================================================
# DOCKER ALIASES
# =============================================================================

if command -v docker &>/dev/null; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias drm='docker rm'
    alias drmi='docker rmi'
    alias dstop='docker stop $(docker ps -q)'
    alias dclean='docker system prune -af'
fi

# =============================================================================
# NODE.JS / NPM / YARN ALIASES
# =============================================================================

if command -v npm &>/dev/null; then
    alias ni='npm install'
    alias ns='npm start'
    alias nt='npm test'
    alias nb='npm run build'
    alias nd='npm run dev'
fi

if command -v yarn &>/dev/null; then
    alias yi='yarn install'
    alias ys='yarn start'
    alias yt='yarn test'
    alias yb='yarn build'
    alias yd='yarn dev'
fi

# =============================================================================
# OS SPECIFIC & NETWORK
# =============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
    # macOS
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
    alias cleanup='find . -name ".DS_Store" -delete'
    if command -v brew &>/dev/null; then
        alias update='brew update && brew upgrade && brew cleanup'
    fi
    alias localip='ipconfig getifaddr en0'
elif [[ "$OSTYPE" == linux* ]]; then
    # Linux
    if command -v apt-get &>/dev/null; then
        alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
    fi
    alias localip='hostname -I | awk "{ print \$1 }"'
    if command -v xdg-open &>/dev/null; then
        alias open='xdg-open'
    fi
    if command -v xclip &>/dev/null; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    fi
fi

alias publicip='curl -s https://api.ipify.org'
if command -v python3 &>/dev/null; then
    alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
fi

# =============================================================================
# DISK USAGE
# =============================================================================

alias ducks='du -cksh * | sort -hr | head -n 15'
alias df='df -h'