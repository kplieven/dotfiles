# Ubuntu config steps
## System
### Settings
- Set default applications
- Keyboard shortcuts
    - Move to workspace above: Alt+Super+K
    - Move to workspace below: Alt+Super+J
    - Move window one workspace down: Alt+Super+Page Down
    - Move window one workspace up: Alt+Super+Page Up
    - Copy a screenshot on an area to clipboard: Shift+Super+S
    - Next track: Ctrl+Super+Right
    - Play (or play/pause): Ctrl+Super+Up
    - Previous track: Ctrl+Super+Left
    - Volume down: Ctrl+Super+Page Down
    - Volume up: Ctrl+Super+Page Up
    - Hide window: Ctrl+Super+-
    - Maximise window: Ctrl+Super+=

### General Packages
```zsh
❯ sudo apt-get install gnome-tweaks neofetch gparted ack-grep
```

### Kitty Terminal
```zsh
❯ curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin installer=nightly
❯ ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/
❯ cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
❯ cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
❯ sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
❯ sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
❯ kitty +kitten themes
```
Theme Tokyo Night

### GRUB
In `/etc/default/grub`:
* `GRUB_TIMEOUT=10` -> `GRUB_TIMEOUT=-1`

To edit entries, install `grub-customizer`:
```zsh
❯ sudo apt-get install grub-customizer
```

### Fonts
IBM Plex families:
* [IBM Plex Sans](https://fonts.google.com/specimen/IBM+Plex+Sans)
* [IBM Plex Serif](https://fonts.google.com/specimen/IBM+Plex+Serif)
* [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono)
* [IBM Plex Sans Condensed](https://fonts.google.com/specimen/IBM+Plex+Sans+Condensed)

```zsh
❯ sudo apt-get install fonts-firacode
```

### zsh
#### Install
```zsh
❯ sudo apt-get install zsh
❯ chsh -s $(which zsh)
```
Log out.

#### Config
Install Oh My Zsh:
```zsh
❯ sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
Install [patched font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) then configure [p10k theme](https://github.com/romkatv/powerlevel10k.git)
```zsh
❯ git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/themes/powerlevel10k
```

#### Plugins
Plugins without manual install: add `copyfile` to plugins in ~/.zshrc.

Install [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
```zsh
❯ git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
Add `zsh-autosuggestions` to plugins in ~/.zshrc.

Install [zsh-vim-mode](https://github.com/softmoth/zsh-vim-mode.git):
```zsh
❯ git clone https://github.com/softmoth/zsh-vim-mode.git $ZSH/custom/plugins/zsh-vim-mode
```
Add `zsh-vim-mode` to plugins in ~/.zshrc.

### Theming
#### [Gnome extensions](https://extensions.gnome.org/)
- [User Themes](https://extensions.gnome.org/extension/19/user-themes/)
- [Clipboard Indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)
- [Crypto Price Tracker](https://extensions.gnome.org/extension/2817/crypto-price-tracker/)
- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)
    - **Position and size**
        - Position on screen: Bottom
        - Icon size limit: 64
    - **Launchers**
        - Show mounted volumes: off
    - **Behaviour**
        - Click action: Minimize or show previews
        - Scroll action: Cycle through windows
    - **Appearance**
        - Customise windows counter indicators: Dashes (Use dominant colour: on)
        - Customise the dash colour: 2de donkerste grijswaarde
        - Customise opacity: Fixed
        - Opacity: 80%
- [ArcMenu](https://extensions.gnome.org/extension/3628/arcmenu/)
    - **Pinned software**: Whatever you feel is important enough to have quick access but not important enough to pin on the dock
- [Sound Input & Output Device Chooser](https://extensions.gnome.org/extension/906/sound-output-device-chooser/)
- [Tiling Assistant](https://extensions.gnome.org/extension/3733/tiling-assistant/)

#### [Gnome-look](https://www.gnome-look.org/browse/)
- [Icon Theme](https://www.gnome-look.org/browse?cat=132&ord=rating)
    - [Tela](https://github.com/vinceliuice/Tela-icon-theme.git)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/Tela-icon-theme.git
    ❯ ./Tela-icon-theme/install.sh
    ```
- [GTK3/4 Theme](https://www.gnome-look.org/browse?cat=135&ord=rating)
    - [Orchis](https://github.com/vinceliuice/Orchis-theme)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/Orchis-theme.git
    ❯ ./Orchis-theme/install.sh
    ```
    - [WhiteSur](https://github.com/vinceliuice/WhiteSur-gtk-theme)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    ❯ ./WhiteSur-gtk-theme/install.sh -i simple
    ```
    - [Graphite](https://github.com/vinceliuice/Graphite-gtk-theme)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/Graphite-gtk-theme
    ❯ ./Graphite-gtk-theme/install.sh -c dark --tweaks rimless
    ```
- [Cursor Theme](https://www.gnome-look.org/browse?cat=107&ord=rating)
    - [Vimix](https://www.gnome-look.org/p/1358330)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/Vimix-cursors.github && cd Vimix-cursors
    ❯ sudo ./install.sh
    ```
- [GRUB Theme](https://www.gnome-look.org/browse?cat=109&ord=rating)
    - [Vineliuice themes](https://github.com/vinceliuice/grub2-themes)
    ```zsh
    ❯ git clone https://github.com/vinceliuice/grub2-themes.git
    ❯ cd grub2-themes
    ❯ sudo ./install.sh -b -t [THEME] -i [ICON]
    ```
    THEME = tela/vimix/stylish/whitesur
    ICON = color/white/whitesur
    - [Matter theme](https://github.com/mateosss/matter)
    ```zsh
    ❯ git clone https://github.com/mateosss/matter.git && cd matter
    ```
    Run `./matter.py` to find the grub entries, so you can assign icons accordingly:
    ```
    ❯ ./matter.py -i ubuntu folder _ _ _ _ microsoft-windows microsoft-windows ubuntu folder _ _ _ _ _ cog \
      -hl ef233c -bg 2b2d42 -fg edf2f4 \
      -ff ~/.local/share/fonts/SplineSans/static/SplineSans-Regular.ttf -fn Spline Sans Regular -fs 20
    ```
- [GDM Theme](https://www.gnome-look.org/browse?cat=131&ord=rating)
    - [Change background script](https://github.com/thiggy01/change-gdm-background)

#### Background slideshow
Install shotwell:
```zsh
❯ sudo apt-get install shotwell
```

### Backups

Install timeshift:
```zsh
❯ sudo apt-get install timeshift
```

## Programming
### LLVM
Clone the [LLVM repository](https://github.com/llvm/llvm-project):
```zsh
❯ git clone --depth 1 --branch llvmorg-13.0.0 https://github.com/llvm/llvm-project.git
❯ cmake -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
        -DLLVM_TARGETS_TO_BUILD="X86;ARM;NVPTX;AArch64;Mips;Hexagon;WebAssembly" \
        -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON -DLLVM_BUILD_32_BITS=OFF \
        -S llvm-project/llvm -B llvm-build -G Ninja
❯ cmake --build llvm-build
❯ cmake --install llvm-build --prefix llvm-install
```

### Halide
Install [LLVM](#llvm), then export variables:
```zsh
❯ export LLVM_ROOT=$PWD/llvm-install
❯ export LLVM_CONFIG=$LLVM_ROOT/bin/llvm-config
```
Install [Halide](https://github.com/halide/Halide):
```zsh
❯ git clone https://github.com/halide/Halide.git && cd Halide
❯ mkdir build && cd build
❯ cmake -DCMAKE_BUILD_TYPE=Release -G Ninja ..
❯ ninja package
```
This gives a release package as tar file.

### Python
```zsh
❯ sudo apt-get install python3 pip3 python3-venv
```

### Node (nvm)
```zsh
❯ wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
❯ nvm install node
```

### OpenGL
```zsh
❯ sudo apt-get install libglu1-mesa-dev freeglut3-dev mesa-common-dev
```

### [Neovim](https://github.com/neovim/neovim)
#### Packages
```zsh
❯ sudo apt-get install build-essential ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen libssl-dev xclip fd-find
```

#### [CMake](https://cmake.org/download/)
Download Unix source, extract, then in the folder:

```zsh
❯ ./bootstrap
❯ make
❯ make install
```

#### [Vim plug](https://github.com/junegunn/vim-plug)
```zsh
❯ sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

#### Installation
```zsh
❯ git clone https://github.com/neovim/neovim.git && cd neovim
```
Checkout desirable version
```zsh
❯ make CMAKE_BUILD_TYPE=RelWithDebInfo
❯ sudo make install
```
Install [patched font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) for icons.

#### [Neovim config](https://github.com/kplieven/nvim.git)
```zsh
❯ git clone https://github.com/kplieven/nvim.git ~/.config/nvim
```
Don't forget to checkout the correct branch.
Then create a symlink to `fd` (default command is `fdfind`) and add default command `fd` for `fzf`:
```zsh
❯ ln -s $(which fdfind) ~/.local/bin/fd
❯ echo "export FZF_DEFAULT_COMMAND='fd --type f'" >> ~/.zshrc
```
Need ripgrep for Todo comments (check [releases](https://github.com/BurntSushi/ripgrep#installation) for newer version):
```zsh
❯ curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
❯ sudo dpkg -i ripgrep_13.0.0_amd64.deb
```

#### Language servers
- Python
```zsh
❯ npm install -g pyright
```
- C/C++
```zsh
❯ sudo apt-get install clangd
```
- Latex
```zsh
❯ sudo apt-get install texlive-latex-recommended texlive-science texlive-xetex latexmk texlive-fonts-extra texlive-publishers
```

### [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads)
[Purge NVIDIA driver](#purging-nvidia-drivers) and [disable nouveau driver](#disable-nouveau-driver). Restart, then download and run the toolkit runfile.
After install add the bin folder to path:
```zsh
❯ echo "export PATH='/usr/local/cuda/bin:$PATH'" >> ~/.zshrc
```

## Software
### Command line
- [Spotify](https://www.spotify.com/nl/download/linux/)
```zsh
❯ curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
❯ echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
❯ sudo apt-get update && sudo apt-get install spotify-client
```
- [Flatpak](https://flatpak.org/setup/Ubuntu/)
```zsh
❯ sudo apt-get install flatpak
❯ flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Deb files
- Google Chrome
    ```zsh
    ❯ wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    ❯ sudo dpkg -i google-chrome-stable_current_amd64.deb```
- Discord
    ```zsh
    ❯ wget -O discord.deb https://discord.com/api/download?platform=linux&format=deb
    ❯ sudo dpkg -i discord.deb
    ```

### Flatpak
- [Telegram](https://desktop.telegram.org/)
```zsh
❯ flatpak install flathub org.telegram.desktop
```

## FAQ/issues
### Nvidia drivers
#### Purging nvidia drivers
```zsh
❯ sudo apt-get remove --purge '*nvidia*'
❯ sudo apt autoremove
```

#### Disable nouveau drivers
```zsh
❯ sudo sh -c 'echo "blacklist nouveau\noptions nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf'
❯ sudo update-initramfs -u
❯ sudo reboot
```

### Neofetch wrong GPU name
```zsh
❯ sudo update-pciids
```

### Flatpak can't load URI (unacceptable TLS certificate)
```zsh
❯ sudo apt install --reinstall ca-certificates
```

### GRUB input lag
In `/etc/default/grub`, lower the resolution. Run `sudo update-grub`.
