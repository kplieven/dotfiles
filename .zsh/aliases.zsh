## Git dotfiles
alias config="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

alias icat='kitty +kitten icat'

alias ll='ls -alh --color=auto'
alias ls='ls --color=auto'

# vim using
nvim --version > /dev/null 2>&1
NEOVIM_INSTALLED=$?
if [ $NEOVIM_INSTALLED -eq 0 ]; then
  alias vim="nvim"
fi

# mimic vim functions
alias :q='exit'
alias :e='vim'

# zsh profile editing
alias vzsh='vim ~/.zshrc'

# Git Aliases
alias g='git'
alias gs='git status'
alias gi='vim .gitignore'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

## Git Push / Pull
alias gp='git push'
alias gpA='git push --all && git push --tags'
alias gpl='git pull'
alias gf='git fetch'
alias gr='git remote --verbose'

## Git Submodule
alias gS='git submodule'
alias gSuir='git submodule update --init --recursive'
