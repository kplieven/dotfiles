#!/usr/bin/env bash

git clone --bare git@github.com:kplieven/dotfiles.git $HOME/.dotfiles

# define config alias locally since the dotfiles
# aren't isntalled on the system yet
function config {
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}

# create a directory to backup existing dotfiles to
mkdir -p .dotfiles-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out fotiles from git@github.com:kplieven/dotfiles.git"
else
  echo "Moving existing dotfiles to ~/.dotfiles-backup"
  config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | while read line; do
    mkdir -p .dotfiles-backup/`dirname "$line"`
    mv "$line" .dotfiles-backup/"$line"
  done
fi

# checkout dotfiles from repo
config checkout
config config status.showUntrackedFiles no

for FILE in $HOME/scripts/bin/*; do
    ln -s $FILE $HOME/.local/bin/
done
