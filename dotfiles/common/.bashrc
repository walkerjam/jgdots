if [ -f ~/.profile ]; then
  source ~/.profile
fi

PS1="\[\e[00;32m\][\u@\h \w]\\$ \[\e[0m\]"
