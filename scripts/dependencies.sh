#!/bin/bash

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --no-modify-path
. "$HOME/.cargo/env"

# rust tools
cargo install exa ripgrep bat fd-find starship btm rm-improved

# zsh
sudo apt-get install zsh
chsh -s $(which zsh)

# neovim
NEOVIM_VERSION=stable
sudo apt-get install ninja-build gettext cmake unzip curl build-essential
git clone https://github.com/neovim/neovim /tmp/neovim
cd /tmp/neovim
git checkout $NEOVIM_VERSION
make -j `nproc` CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install

nvim --headless "+Lazy! sync" +qa

# lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm lazygit
