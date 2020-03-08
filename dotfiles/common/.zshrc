export ZSH=$HOME/.oh-my-zsh

ZSH_THEME='powerlevel9k/powerlevel9k'
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='247'
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND='008'
POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND='008'
POWERLEVEL9K_CONTEXT_REMOTE_BACKGROUND='007'
POWERLEVEL9K_TIME_FOREGROUND='000'
POWERLEVEL9K_TIME_BACKGROUND='004'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='000'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='002'

DISABLE_AUTO_UPDATE='true'

plugins=(colored-man-pages git docker kubectl)
if [ -d $ZSH/custom/plugins/zsh-autosuggestions ]; then
  plugins+=(zsh-autosuggestions)
fi

if [ -f $ZSH/oh-my-zsh.sh ]; then
  source $ZSH/oh-my-zsh.sh
fi

# Source profile after zsh plugins so we can override aliases, etc.
if [ -f "$HOME/.profile" ]; then
  source "$HOME/.profile"
fi

# Local override
if [ -f "$HOME/.zshrc_local" ]; then
  source "$HOME/.zshrc_local"
fi
