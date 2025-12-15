# =============================================================================
# MODERN TOOL REPLACEMENTS
# =============================================================================
# Original commands still available via \cat, \grep, \find, etc.

alias ls='eza --icons --git --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git --group-directories-first'

# Only alias cat if bat is available
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never --style=changes'
fi

alias grep='rg'
# NOTE: Don't alias find='fd' - it breaks scripts that rely on standard find syntax
# Use 'fd' directly or the 'ff' alias below

# =============================================================================
# SAFETY NETS
# =============================================================================

alias del="trash"           # Move to macOS Trash
alias rmi="rm -iv"          # Interactive permanent delete
alias cpi="cp -iv"          # Interactive copy
alias mvi="mv -iv"          # Interactive move

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

# Additional file shortcuts
alias vzu='vim ~/.zshrc'
alias aliases='bat ~/.shell-tools/modules/aliases.zsh'
alias valiases='vim ~/.shell-tools/modules/aliases.zsh'
alias zshrc='bat ~/.zshrc'
alias vzshrc='vim ~/.zshrc'
alias functions='bat ~/.shell-tools/modules/functions.zsh'
alias vfunctions='vim ~/.shell-tools/modules/functions.zsh'
alias gitconfig='bat ~/.gitconfig'
alias vgitconfig='vim ~/.gitconfig'
alias hosts='bat /etc/hosts'
alias vhosts='sudo vim /etc/hosts'

# =============================================================================
# UTILITIES
# =============================================================================

alias ping="ping -c 5"
alias myip='curl http://ipecho.net/plain; echo'
alias ffs='sudo !!'
alias y='yarn'
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

alias ff='fd'
alias fzp='fzf --preview "bat --color=always {}"'

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias ports='netstat -tulanp'
alias myps='ps -ef | grep $USER'

# =============================================================================
# GIT ALIASES
# =============================================================================

alias g='git'
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

# =============================================================================
# DOCKER ALIASES
# =============================================================================

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

# =============================================================================
# NODE.JS / NPM / YARN ALIASES
# =============================================================================

alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nd='npm run dev'
alias yi='yarn install'
alias ys='yarn start'
alias yt='yarn test'
alias yb='yarn build'
alias yd='yarn dev'

# =============================================================================
# OS SPECIFIC & NETWORK
# =============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
    # macOS
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
    alias cleanup='find . -name ".DS_Store" -delete'
    alias update='brew update && brew upgrade && brew cleanup'
    alias localip='ipconfig getifaddr en0'
elif [[ "$OSTYPE" == linux* ]]; then
    # Linux
    if command -v apt-get &>/dev/null; then
        alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
    fi
    alias localip='hostname -I | awk "{ print \$1 }"'
    alias open='xdg-open'
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

alias publicip='curl -s https://api.ipify.org'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# =============================================================================
# DISK USAGE
# =============================================================================

alias ducks='du -cksh * | sort -hr | head -n 15'
alias df='df -h'
