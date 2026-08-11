#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/kplieven/dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup"

config() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning bare repository into $DOTFILES_DIR..."
    git clone --bare "$REPO_URL" "$DOTFILES_DIR"
fi

echo "Attempting to checkout dotfiles..."
checkout_output=$(config checkout 2>&1) && checkout_ok=true || checkout_ok=false

if [ "$checkout_ok" = false ] && echo "$checkout_output" | grep -q "would be overwritten"; then
    echo "Backing up conflicting files to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    echo "$checkout_output" | grep $'^\t' | while read -r file; do
        file=$(echo "$file" | xargs)
        if [ -n "$file" ] && [ -e "$HOME/$file" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
            echo "  Backed up: $file"
        fi
    done

    echo "Retrying checkout after resolving conflicts..."
    config checkout
elif [ "$checkout_ok" = false ]; then
    echo "Error: Failed to check out dotfiles."
    echo "$checkout_output"
    exit 1
fi

echo "Dotfiles successfully checked out."
config config status.showUntrackedFiles no

echo "Installing knowledge-tracking statusline extension..."
node "$HOME/.copilot/extensions/knowledge-tracking/install.mjs" install
echo "Knowledge-tracking extension installed."
