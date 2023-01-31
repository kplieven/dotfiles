## History
HISTFILE=~/.histfile
HISTSIZE=25000
SAVEHIST=10000

## Automatically cd
setopt autocd

bindkey -v
bindkey ^R history-incremental-search-backward 
bindkey ^S history-incremental-search-forward

eval "$(starship init zsh)"
