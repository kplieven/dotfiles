#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/kplieven/dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup"

if [ ! -d "$DOTFILES_DIR" ]; then
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
fi

# define config alias locally since the dotfiles
# aren't installed on the system yet
function config {
  git --git-dir="$DOTFILES_DIR" --work-tree=$HOME $@
}

# create a directory to backup existing dotfiles to
mkdir -p "$BACKUP_DIR"

config config status.showUntrackedFiles no
conflicts=$(config checkout 2>&1)

if echo "$conflicts" | grep -q "would be overwritten"; then
  echo "Backing up conflicting files to $BACKUP_DIR"
  echo "$conflicts" | grep "would be overwritten" | awk '{print $1}' | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    mv "$HOME/$file" "$BACKUP_DIR/$file"
  done

  # Retry the checkout after backing up files
  echo "Retrying checkout after resolving conflicts..."
  config checkout
fi

# if [ $? = 0 ]; then
#   echo "Checked out dotfiles from https://github.com/kplieven/dotfiles.git"
# else
#   echo "Moving existing dotfiles to ~/.dotfiles-backup"
#   config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | while read line; do
#     mkdir -p .dotfiles-backup/`dirname "$line"`
#     mv "$line" .dotfiles-backup/"$line"
#   done
# fi

# checkout dotfiles from repo
# config checkout

mkdir -p $HOME/.local/bin
for FILE in $HOME/scripts/bin/*; do
    if [ ! -f $HOME/.local/bin/$(basename $FILE) ]; then
      ln -s $FILE $HOME/.local/bin/
    fi
done
