PS1="\[\e[00;32m\][\u@\h \w]\\$ \[\e[0m\]"

if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

# Local override
if [ -f "$HOME/.bashrc_local" ]; then
  source "$HOME/.bashrc_local"
fi
