# BEGIN Yoinked from existing
case $- in
    *i*) ;;
      *) return;;
esac
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
# END Yoinked from existing

PS1="\[\e[00;32m\][\u@\h \w]\\$ \[\e[0m\]"

if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

# Local override
if [ -f "$HOME/.bashrc_local" ]; then
  source "$HOME/.bashrc_local"
fi
