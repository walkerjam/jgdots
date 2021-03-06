export VISUAL=vim
export EDITOR="$VISUAL"

if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Self update
alias jgdots='curl -s https://raw.githubusercontent.com/walkerjam/jgdots/master/install.sh | bash -s -- -o -v'

# General shell
alias ll='ls -la'
alias lt='ls -latr'
alias grep='grep --color=auto'
alias hosts='sudo vim /etc/hosts'
alias profile='vim ~/.profile && source ~/.profile'
alias sa='eval $(ssh-agent) && ssh-add'

# Git
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log'
alias glp='git log --oneline --abbrev-commit --all --graph --decorate --color'
alias gf='git fetch'
alias gfa='git fetch --all --tags'
alias gm='git merge'
alias gp='git pull'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gco='git checkout'
alias gcb='git checkout -b'

# Github / Azure DevOps
alias ghw='gh repo view --web'
alias adw='az repos show -r `git remote -v | grep "(fetch)" | awk '"'"'{print $2}'"'"' | awk -F'"'"'/'"'"' '"'"'{print $NF}'"'"'` --open 1>/dev/null 2>/dev/null'

# Docker
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias de='docker exec -it'
alias dl='docker logs'
alias dlf='docker logs -f'
alias dil='docker image ls'
alias dila='docker image ls -a'
alias dcl='docker container ls'
alias dcla='docker container ls -a'

# Kubernetes
alias k='kubectl'
alias kc='kubectx'
alias kn='kubens'
alias mkk='minikube kubectl'

# Source extra files
for configFile in $HOME/.config/jgdots/*; do
  source $configFile
done

# Local override
if [ -f "$HOME/.profile_local" ]; then
  source "$HOME/.profile_local"
fi
