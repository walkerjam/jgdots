PS1="\[\e[00;32m\][\u@\h \w]\\$ \[\e[0m\]"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

# Local override
if [ -f ~/.bashrc_local ]; then
  source ~/.bashrc_local
fi
