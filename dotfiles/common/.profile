if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# General shell
alias ll='ls -la'
alias lt='ls -latr'
alias grep='grep --color=auto'
alias hosts='sudo vim /etc/hosts'
alias profile='vim ~/.profile && source ~/.profile'

# Git
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log'
alias glp='git log --oneline --abbrev-commit --all --graph --decorate --color'
alias gf='git fetch'
alias gfa='git fetch --all --tags'
alias gp='git pull'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gcb='git checkout -b'

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
