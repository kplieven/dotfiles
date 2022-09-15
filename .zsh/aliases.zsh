## Git dotfiles
alias config="git --git-dir=$HOME/.dotfiles/.git --work-tree=$HOME"

alias icat='kitty +kitten icat'

which exa > /dev/null 2>&1
if [ $? -eq 0 ]; then
  alias ll='exa -lbh --icons --color=auto --group-directories-first'
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

# Git Aliases
alias g='git'
alias gs='git status'
alias gi='vim .gitignore'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --graph --oneline --decorate'
alias gau='git add -u'

## Git Push / Pull
alias gp='git push'
alias gpA='git push --all && git push --tags'
alias gpl='git pull'
alias gf='git fetch'
alias gr='git remote --verbose'

## Git Submodule
alias gS='git submodule'
alias gSuir='git submodule update --init --recursive'
