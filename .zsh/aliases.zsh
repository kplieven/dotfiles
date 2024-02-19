# Git dotfiles
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

alias icat='kitty +kitten icat'
alias s='kitty +kitten ssh'

# trick to enable running aliases as root
alias sudo='sudo '

which exa > /dev/null 2>&1
if [ $? -eq 0 ]; then
  alias ll='exa -albh --icons --color=auto --group-directories-first'
else
  alias ll='ls -alh --color=auto'
fi

alias ls='ls --color=auto'

# vim using
alias vim='lvim'

# mimic vim functions
alias :q='exit'
alias :e='vim'

# zsh profile editing
alias vzsh='vim ~/.zsh/'

# git
alias g='git'
alias wtf='git commit -m "$(curl -s whatthecommit.com/index.txt)"'

# Barco VPN
alias vpnconnect='openconnect korvpn.barco.com/token --background --useragent "AnyConnect Windows 4.10.06079" -v'
alias vpndisconnect='killall -SIGINT openconnect'

# Barco Docker
alias dockerrun='sudo docker run --user karlie --net host\
    --mount type=bind,source="$(pwd)",target=/home/karlie/$(basename "$(pwd)") \
    -v /home/karlie/Brewery/:/home/karlie/Brewery/ \
    -v /home/karlie/.conan/:/home/karlie/.conan/ \
    -v /home/karlie/.ssh/:/home/karlie/.ssh/ \
    -v /home/karlie/.zsh/:/home/karlie/.zsh/ \
    -v /home/karlie/.config/lvim/:/home/karlie/.config/lvim/ \
    -v /home/karlie/.zshrc:/home/karlie/.zshrc \
    -v /home/karlie/.gitconfig:/home/karlie/.gitconfig \
    -v /home/karlie/.config/starship.toml:/home/karlie/.config/starship.toml \
    --workdir /home/karlie/$(basename $(pwd)) \
    -it '

alias brewery-dev='ruby -I ~/projects/cs-brewery/lib ~/projects/cs-brewery/exe/cs-brewery'
