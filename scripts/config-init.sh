#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/kplieven/dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup"

if [ ! -d "$DOTFILES_DIR" ]; then
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
fi

function config {
  git --git-dir="$DOTFILES_DIR" --work-tree=$HOME $@
}

mkdir -p "$BACKUP_DIR"

echo "Attempting to checkout dotfiles..."
checkout_output=$(config checkout 2>&1)

if echo "$checkout_output" | grep -q "would be overwritten"; then
  echo "Backing up conflicting files to $BACKUP_DIR..."
  echo "$checkout_output" | sed -n '/would be overwritten/,$p' | tail -n +2 | while read -r file; do
    file=$(echo "$file" | xargs)
    if [ -e "$HOME/$file" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      mv "$HOME/$file" "$BACKUP_DIR/$file"
    fi
  done

  echo "Retrying checkout after resolving conflicts..."
  config checkout
fi

if [ $? -eq 0 ]; then
  echo "Dotfiles successfully checked out. Local system matches the remote repository."
else
  echo "Error: Failed to fully check out dotfiles."
  exit 1
fi

config config status.showUntrackedFiles no
