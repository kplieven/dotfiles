## Git dotfiles
alias config="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

alias icat='kitty +kitten icat'
alias s='kitty +kitten ssh'

which exa > /dev/null 2>&1
if [ $? -eq 0 ]; then
  alias ll='exa -albh --icons --color=auto --group-directories-first'
else
  alias ll='ls -alh --color=auto'
fi

alias ls='ls --color=auto'

# vim using
lvim --version > /dev/null 2>&1
LVIM_INSTALLED=$?
nvim --version > /dev/null 2>&1
NEOVIM_INSTALLED=$?
if [ $LVIM_INSTALLED -eq 0 ]; then
  alias vim="lvim"
elif [ $NEOVIM_INSTALLED -eq 0 ]; then
  alias vim="nvim"
fi

# mimic vim functions
alias :q='exit'
alias :e='vim'

# zsh profile editing
alias vzsh='vim ~/.zshrc'

# git
alias g='git'

# Barco
alias sshphoenix='sshpass -p letmein ssh root@10.200.18.72'
