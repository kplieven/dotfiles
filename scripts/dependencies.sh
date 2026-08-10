#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles dependency installer
# Ubuntu/Debian only — run before config-init.sh
#
# Usage:
#   Interactive:  ./dependencies.sh
#   Install all:  ./dependencies.sh --all
#   Selective:    ./dependencies.sh --shell --nvim --rust
#   Curl pipe:    curl -fsSL <url> | bash  (installs all, prompts for nvim version)
# =============================================================================

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()  { echo -e "${BLUE}${BOLD}::${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}${BOLD}[SKIP]${RESET}  $*"; }
fail()  { echo -e "${RED}${BOLD}[FAIL]${RESET}  $*"; }

# ---------------------------------------------------------------------------
# User input helper — works even when stdin is a pipe (reads from /dev/tty)
# ---------------------------------------------------------------------------
prompt() {
    local message="$1" default="$2" reply
    if [[ -t 0 ]]; then
        read -rp "$(echo -e "${BOLD}${message}${RESET} [${default}]: ")" reply
    else
        read -rp "$(echo -e "${BOLD}${message}${RESET} [${default}]: ")" reply </dev/tty 2>/dev/null || reply=""
    fi
    echo "${reply:-$default}"
}

confirm() {
    local message="$1" reply
    if [[ -t 0 ]]; then
        read -rp "$(echo -e "${BOLD}${message}${RESET} [Y/n]: ")" reply
    else
        read -rp "$(echo -e "${BOLD}${message}${RESET} [Y/n]: ")" reply </dev/tty 2>/dev/null || reply="y"
    fi
    [[ "${reply,,}" != "n" ]]
}

install_0xproto_font() {
    local font_dir="$HOME/.local/share/fonts/0xProtoNerdFont"
    mkdir -p "$font_dir"
    if compgen -G "$font_dir/0xProtoNerdFont*.ttf" > /dev/null; then
        warn "0xProto Nerd Font already installed"
    else
        local nf_version
        nf_version=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep -Po '"tag_name": *"\K[^"]*')
        local font_zip="/tmp/0xProto.zip"

        if [[ -z "$nf_version" ]]; then
            fail "Could not determine latest nerd-fonts release for 0xProto"
            return
        fi

        rm -f "$font_zip"
        rm -rf "$font_dir"
        mkdir -p "$font_dir"
        curl -fsSL -o "$font_zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/0xProto.zip"
        unzip -qo "$font_zip" -d "$font_dir"
        fc-cache -f "$font_dir"
        rm -f "$font_zip"
        ok "0xProto Nerd Font installed (${nf_version})"
    fi
}

install_symbols_nerd_font() {
    local font_dir="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    mkdir -p "$font_dir"
    if compgen -G "$font_dir/*.ttf" > /dev/null; then
        warn "Symbols Nerd Font already installed"
    else
        local nf_version
        nf_version=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep -Po '"tag_name": *"\K[^"]*')
        local font_zip="/tmp/NerdFontsSymbolsOnly.zip"

        if [[ -z "$nf_version" ]]; then
            fail "Could not determine latest nerd-fonts release for Symbols Nerd Font"
            return
        fi

        rm -f "$font_zip"
        rm -rf "$font_dir"
        mkdir -p "$font_dir"
        curl -fsSL -o "$font_zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/NerdFontsSymbolsOnly.zip"
        unzip -qo "$font_zip" -d "$font_dir"
        fc-cache -f "$font_dir"
        rm -f "$font_zip"
        ok "Symbols Nerd Font installed (${nf_version})"
    fi
}

install_vimix_cursors() {
    local user_icons_dir="$HOME/.local/share/icons"
    local install_dir="/tmp/Vimix-cursors"
    if compgen -G "$user_icons_dir/Vimix-cursors*" > /dev/null; then
        warn "Vimix cursors already installed for user"
    else
        if ! command -v git &>/dev/null; then
            sudo apt-get install -y git
        fi
        rm -rf "$install_dir"
        git clone --depth 1 https://github.com/vinceliuice/Vimix-cursors.git "$install_dir"
        mkdir -p "$user_icons_dir"
        (cd "$install_dir" && ./install.sh)
        rm -rf "$install_dir"
        ok "Vimix cursors installed for user"
    fi

    # The upstream installer places themes in ~/.local/share/icons, but
    # libXcursor's default search path (no XCURSOR_PATH set) only checks
    # ~/.icons, /usr/share/icons and /usr/share/pixmaps — not the XDG data
    # dir. Without this symlink the theme is silently never found and
    # cursors fall back to the plain X core cursor.
    mkdir -p "$HOME/.icons"
    local theme_dir
    for theme_dir in "$user_icons_dir"/Vimix-cursors "$user_icons_dir"/Vimix-white-cursors; do
        [[ -d "$theme_dir" ]] || continue
        ln -sfn "$theme_dir" "$HOME/.icons/$(basename "$theme_dir")"
    done
    ok "Linked Vimix cursor themes into ~/.icons (libXcursor search path)"
}

install_graphite_gtk_theme() {
    local theme_dir="$HOME/.themes/Graphite-Dark"
    local install_dir="/tmp/Graphite-gtk-theme"
    if [[ -d "$theme_dir" ]]; then
        warn "Graphite GTK theme already installed"
    else
        rm -rf "$install_dir"
        git clone --depth 1 https://github.com/vinceliuice/Graphite-gtk-theme.git "$install_dir"
        (cd "$install_dir" && ./install.sh --color dark)
        rm -rf "$install_dir"
        ok "Graphite GTK theme installed"
    fi
}

install_tela_icon_theme() {
    local theme_dir="$HOME/.local/share/icons/Tela-Dark"
    local install_dir="/tmp/Tela-icon-theme"
    if [[ -d "$theme_dir" ]]; then
        warn "Tela icon theme already installed"
    else
        rm -rf "$install_dir"
        git clone --depth 1 https://github.com/vinceliuice/Tela-icon-theme.git "$install_dir"
        (cd "$install_dir" && ./install.sh)
        rm -rf "$install_dir"
        ok "Tela icon theme installed"
    fi
}

install_rofi_theme() {
    local theme_dir="$HOME/.local/share/rofi/themes"
    local install_dir="/tmp/rofi-themes-collection"
    if [[ -f "$theme_dir/rounded-nord-dark.rasi" && -f "$theme_dir/template/rounded-template.rasi" ]]; then
        warn "Rounded Nord Rofi theme already installed"
    else
        rm -rf "$install_dir"
        git clone --depth 1 https://github.com/newmanls/rofi-themes-collection.git "$install_dir"
        mkdir -p "$theme_dir"
        mkdir -p "$theme_dir/template"
        install -m 644 "$install_dir/themes/rounded-nord-dark.rasi" "$theme_dir/"
        install -m 644 "$install_dir/themes/template/rounded-template.rasi" "$theme_dir/template/"
        rm -rf "$install_dir"
        ok "Rounded Nord Rofi theme installed"
    fi
}

detect_vimix_cursor_theme() {
    local dir theme
    for dir in "$HOME/.icons" "$HOME/.local/share/icons"; do
        [[ -d "$dir" ]] || continue
        if [[ -d "$dir/Vimix-white-cursors" ]]; then
            printf '%s\n' "Vimix-white-cursors"
            return 0
        fi
        theme=$(find "$dir" -maxdepth 1 -mindepth 1 -type d -name 'Vimix-cursors*' -printf '%f\n' | sort | sed -n '1p')
        if [[ -n "$theme" ]]; then
            printf '%s\n' "$theme"
            return 0
        fi
    done
    return 1
}

install_kitty() {
    if command -v kitty &>/dev/null; then
        warn "kitty already installed"
        return
    fi

    sudo apt-get install -y curl
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    local kitty_bin="$HOME/.local/kitty.app/bin"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$kitty_bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$kitty_bin/kitten" "$HOME/.local/bin/kitten"
    ok "kitty installed"
}

link_i3_bin_scripts() {
    local i3_bin_dir="$HOME/.config/i3/bin"
    if [[ ! -d "$i3_bin_dir" ]]; then
        warn "i3 bin dir not found at $i3_bin_dir — skipping symlinks"
        return
    fi

    mkdir -p "$HOME/.local/bin"
    local script
    for script in "$i3_bin_dir"/*; do
        [[ -f "$script" ]] || continue
        ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
    done
    ok "Symlinked i3 bin scripts into ~/.local/bin"
}

configure_i3_vimix_cursors() {
    local vimix_theme
    if ! vimix_theme="$(detect_vimix_cursor_theme)"; then
        warn "Could not find Vimix cursor theme — skipping i3 cursor config"
        return
    fi

    local default_theme_dir="$HOME/.icons/default"
    local default_theme_file="$default_theme_dir/index.theme"
    mkdir -p "$default_theme_dir"
    cat > "$default_theme_file" <<EOF
[Icon Theme]
Inherits=${vimix_theme}
EOF
    ok "Configured i3/X11 cursor theme to ${vimix_theme}"
}

configure_sway_vimix_cursors() {
    local vimix_theme
    if ! vimix_theme="$(detect_vimix_cursor_theme)"; then
        warn "Could not find Vimix cursor theme — skipping Sway cursor config"
        return
    fi

    local sway_config="$HOME/.config/sway/config"
    local sway_line="seat seat0 xcursor_theme ${vimix_theme} 24"
    if [[ ! -f "$sway_config" ]]; then
        warn "Sway config not found at $sway_config — skipping Sway cursor config"
        return
    fi

    if grep -q '^seat seat0 xcursor_theme ' "$sway_config"; then
        sed -i "s|^seat seat0 xcursor_theme .*|${sway_line}|" "$sway_config"
    else
        printf '\n%s\n' "$sway_line" >> "$sway_config"
    fi
    ok "Configured Sway cursor theme to ${vimix_theme}"
}

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------
CATEGORIES=(shell build-tools rust nvim git terminal desktop-x11 desktop-wayland)
LABELS=(
    "Shell          — zsh, antigen, set as default shell"
    "Build tools    — C/C++ compiler toolchain and build/debug utilities"
    "Rust toolchain — rustup, eza, ripgrep, bat, fd, dust, starship, bottom, rm-improved"
    "Neovim         — build from source, sync plugins"
    "Git tools      — lazygit"
    "Terminal       — kitty, JetBrains Mono Nerd Font, Symbols Nerd Font"
    "Desktop (X11)  — i3, arandr, autorandr, betterlockscreen, picom, polybar, dunst, playerctl, Vimix cursors, 0xProto Nerd Font, Symbols Nerd Font"
    "Desktop (Sway) — sway, waybar, kanshi, Vimix cursors"
)

declare -A SELECTED
for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=1; done

declare -A RESULTS

# ---------------------------------------------------------------------------
# Parse CLI flags
# ---------------------------------------------------------------------------
USE_FLAGS=false

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all              Install everything"
    echo "  --shell            Zsh, antigen"
    echo "  --build-tools      C/C++ build toolchain and utilities"
    echo "  --rust             Rust toolchain and cargo CLI tools"
    echo "  --nvim             Neovim (built from source)"
    echo "  --git              Lazygit"
    echo "  --terminal         Kitty terminal, JetBrains Mono Nerd Font, Symbols Nerd Font"
    echo "  --desktop-x11      i3, arandr, autorandr, betterlockscreen, polybar, dunst, playerctl, Vimix cursors, 0xProto Nerd Font, Symbols Nerd Font"
    echo "  --desktop-wayland  Sway, waybar, kanshi, Vimix cursors"
    echo "  --help             Show this help message"
    echo ""
    echo "If no flags are given, an interactive menu is displayed."
    echo "When piped (curl | bash), --all is implied."
}

if [[ $# -gt 0 ]]; then
    USE_FLAGS=true
    for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=0; done

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=1; done
                ;;
            --shell|--build-tools|--rust|--nvim|--git|--terminal|--desktop-x11|--desktop-wayland)
                SELECTED[${1#--}]=1
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
fi

# ---------------------------------------------------------------------------
# Interactive menu (when no flags and TTY is available)
# ---------------------------------------------------------------------------
show_menu() {
    local current="$1"
    local total="${#CATEGORIES[@]}"

    printf '\033[H\033[2J'
    echo ""
    info "Select categories to install:"
    echo ""
    for i in "${!CATEGORIES[@]}"; do
        local cat="${CATEGORIES[$i]}"
        local marker
        local cursor=" "
        if [[ ${SELECTED[$cat]} -eq 1 ]]; then
            marker="${GREEN}[x]${RESET}"
        else
            marker="[ ]"
        fi

        if [[ "$i" -eq "$current" ]]; then
            cursor="${BLUE}>${RESET}"
        fi

        echo -e " ${cursor} ${BOLD}$((i + 1))${RESET}) ${marker} ${LABELS[$i]}"
    done
    echo ""
    echo -e "  ${BOLD}↑/↓${RESET} Move    ${BOLD}Enter${RESET} Toggle    ${BOLD}q${RESET} Confirm    ${BOLD}a${RESET} Select all    ${BOLD}n${RESET} Select none"
    echo ""
}

interactive_menu() {
    local current=0
    local total="${#CATEGORIES[@]}"

    printf '\033[?25l'
    trap 'printf "\033[?25h"' RETURN

    while true; do
        show_menu "$current"
        local key
        IFS= read -rsn1 key

        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 key
            key=$'\x1b'"$key"
        fi

        case "$key" in
            "")
                local cat="${CATEGORIES[$current]}"
                SELECTED[$cat]=$(( 1 - ${SELECTED[$cat]} ))
                ;;
            q|Q)
                break
                ;;
            a|A)
                for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=1; done
                ;;
            n|N)
                for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=0; done
                ;;
            $'\x1b[A')
                current=$(( (current - 1 + total) % total ))
                ;;
            $'\x1b[B')
                current=$(( (current + 1) % total ))
                ;;
            *)
                ;;
        esac
    done
}

if [[ "$USE_FLAGS" == false ]]; then
    if [[ -t 0 ]]; then
        interactive_menu
    else
        info "Piped mode detected — installing all categories"
    fi
fi

# ---------------------------------------------------------------------------
# Check at least one category selected
# ---------------------------------------------------------------------------
any_selected=false
for cat in "${CATEGORIES[@]}"; do
    if [[ ${SELECTED[$cat]} -eq 1 ]]; then
        any_selected=true
        break
    fi
done

if [[ "$any_selected" == false ]]; then
    warn "No categories selected. Nothing to do."
    exit 0
fi

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
info "Updating apt package lists..."
sudo apt-get update -qq

# ---------------------------------------------------------------------------
# Category: Shell
# ---------------------------------------------------------------------------
install_shell() {
    info "Installing shell tools..."

    sudo apt-get install -y zsh jq

    # antigen
    local antigen_dir="$HOME/.zsh"
    mkdir -p "$antigen_dir"
    if [[ ! -f "$antigen_dir/antigen.zsh" ]]; then
        curl -fsSL https://git.io/antigen > "$antigen_dir/antigen.zsh"
        ok "antigen installed"
    else
        warn "antigen already present"
    fi

    # set zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        chsh -s "$(which zsh)"
        ok "Default shell set to zsh"
    else
        warn "zsh is already the default shell"
    fi

    ok "Shell tools installed"
}

# ---------------------------------------------------------------------------
# Category: Build tools
# ---------------------------------------------------------------------------
install_build_tools() {
    info "Installing C/C++ build tools..."

    sudo apt-get install -y \
        build-essential \
        pkg-config \
        cmake \
        ninja-build \
        meson \
        clang \
        lld \
        gdb \
        valgrind

    sudo apt-get install -y "linux-headers-$(uname -r)" 2>/dev/null || warn "Kernel headers for current kernel not available in apt"

    ok "Build tools installed"
}

# ---------------------------------------------------------------------------
# Category: Rust toolchain
# ---------------------------------------------------------------------------
install_rust() {
    info "Installing Rust toolchain..."

    # Common native deps needed by many Rust crates
    sudo apt-get install -y build-essential pkg-config cmake

    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --no-modify-path
    else
        warn "rustup already installed"
    fi

    # make cargo available in this session
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    info "Installing cargo CLI tools (this may take a while)..."
    local tools=(eza ripgrep bat fd-find du-dust starship bottom rm-improved tree-sitter-cli)
    local failed_tools=0
    for tool in "${tools[@]}"; do
        if cargo install --locked "$tool" 2>/dev/null; then
            ok "$tool (locked)"
        elif cargo install "$tool" 2>/dev/null; then
            warn "$tool installed without --locked fallback"
        else
            fail "$tool"
            failed_tools=1
        fi
    done

    if [[ "$failed_tools" -ne 0 ]]; then
        return 1
    fi

    ok "Rust toolchain installed"
}

# ---------------------------------------------------------------------------
# Category: Neovim
# ---------------------------------------------------------------------------
install_nvim() {
    info "Installing Neovim from source..."

    local fallback_version="v0.12.4"
    local latest_version=""
    if latest_version=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -Po '"tag_name": *"\K[^"]*'); then
        :
    else
        warn "Could not fetch latest Neovim release tag, falling back to $fallback_version"
    fi

    local default_version="${latest_version:-$fallback_version}"
    local nvim_version
    nvim_version=$(prompt "Neovim version to build" "$default_version")

    # build dependencies
    sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential fzf

    # fnm / node (needed for some plugins)
    if ! command -v fnm &>/dev/null; then
        curl -fsSL https://fnm.vercel.app/install | bash
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env)"
        fnm install --lts
        ok "fnm + Node LTS installed"
    else
        warn "fnm already installed"
    fi

    # clone and build
    local build_dir="/tmp/neovim-build"
    rm -rf "$build_dir"
    git clone --depth 1 --branch "$nvim_version" https://github.com/neovim/neovim "$build_dir"
    pushd "$build_dir" >/dev/null
    make -j "$(nproc)" CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    popd >/dev/null
    rm -rf "$build_dir"

    ok "Neovim $nvim_version installed"
}

# ---------------------------------------------------------------------------
# Category: Git tools
# ---------------------------------------------------------------------------
install_git() {
    info "Installing git tools..."

    sudo apt-get install -y git

    # lazygit
    local lazygit_version
    lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    local lazygit_tar="/tmp/lazygit.tar.gz"
    curl -fsSL -o "$lazygit_tar" \
        "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz"
    tar xf "$lazygit_tar" -C /tmp lazygit
    sudo install /tmp/lazygit -D -t /usr/local/bin/
    rm -f /tmp/lazygit "$lazygit_tar"

    ok "lazygit $lazygit_version installed"
}

# ---------------------------------------------------------------------------
# Category: Terminal
# ---------------------------------------------------------------------------
install_terminal() {
    info "Installing terminal tools..."

    sudo apt-get install -y unzip wget

    install_kitty

    # JetBrains Mono Nerd Font
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if [[ ! -d "$font_dir" ]]; then
        local nf_version
        nf_version=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep -Po '"tag_name": *"\K[^"]*')
        local font_zip="/tmp/JetBrainsMono.zip"
        curl -fsSL -o "$font_zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_version}/JetBrainsMono.zip"
        mkdir -p "$font_dir"
        unzip -qo "$font_zip" -d "$font_dir"
        fc-cache -f "$font_dir"
        rm -f "$font_zip"
        ok "JetBrains Mono Nerd Font installed"
    else
        warn "JetBrains Mono Nerd Font already installed"
    fi

    install_0xproto_font
    install_symbols_nerd_font

    ok "Terminal tools installed"
}

# ---------------------------------------------------------------------------
# Category: Desktop (i3 / X11)
# ---------------------------------------------------------------------------
install_desktop_x11() {
    info "Installing X11 desktop tools..."

    sudo apt-get install -y i3 arandr autorandr dunst picom rofi feh flameshot playerctl wget unzip git build-essential cmake pkg-config libxcb1-dev libxcb-xkb-dev libxcb-image0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-randr0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxkbfile-dev libpam0g-dev libev-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libxcb-cursor-dev
    sudo apt-get install -y sassc
    install_0xproto_font
    install_symbols_nerd_font
    install_vimix_cursors
    install_graphite_gtk_theme
    install_tela_icon_theme
    install_rofi_theme
    install_kitty
    configure_i3_vimix_cursors
    link_i3_bin_scripts

    # i3lock-color / betterlockscreen
    if ! command -v i3lock-color &>/dev/null; then
        local i3lock_color_dir="/tmp/i3lock-color"
        rm -rf "$i3lock_color_dir"
        git clone --depth 1 https://github.com/Raymo111/i3lock-color.git "$i3lock_color_dir"
        pushd "$i3lock_color_dir" >/dev/null
        ./install-i3lock-color.sh
        popd >/dev/null
        rm -rf "$i3lock_color_dir"
        ok "i3lock-color installed from source"
    else
        warn "i3lock-color already installed"
    fi

    if ! command -v betterlockscreen &>/dev/null; then
        wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | bash -s user
        ok "betterlockscreen installed"
    else
        warn "betterlockscreen already installed"
    fi

    local betterlockscreen_wallpaper="$HOME/Pictures/wallpapers/1.jpg"
    local betterlockscreen_tmp=""
    if [[ ! -f "$betterlockscreen_wallpaper" ]]; then
        betterlockscreen_tmp="$(mktemp -d)"
        betterlockscreen_wallpaper="$betterlockscreen_tmp/1.jpg"
        if ! curl -fsSL \
            "https://raw.githubusercontent.com/kplieven/dotfiles/main/Pictures/wallpapers/1.jpg" \
            -o "$betterlockscreen_wallpaper"; then
            warn "Skipping betterlockscreen wallpaper generation (could not download tracked 1.jpg)"
            rm -rf "$betterlockscreen_tmp"
            betterlockscreen_tmp=""
        fi
    fi
    if [[ -z "${DISPLAY:-}" ]]; then
        warn "Skipping betterlockscreen wallpaper generation (DISPLAY is not set)"
    elif [[ -f "$betterlockscreen_wallpaper" ]]; then
        betterlockscreen -u "$betterlockscreen_wallpaper" --fx dimblur --dim 20 --blur 1.0
        ok "betterlockscreen dimblur cache generated from 1.jpg"
    fi
    [[ -n "$betterlockscreen_tmp" ]] && rm -rf "$betterlockscreen_tmp"

    # polybar
    sudo apt-get install -y polybar 2>/dev/null || warn "polybar not in apt, install manually"

    ok "X11 desktop tools installed"
}

# ---------------------------------------------------------------------------
# Category: Desktop (Sway / Wayland)
# ---------------------------------------------------------------------------
install_desktop_wayland() {
    info "Installing Wayland desktop tools..."

    sudo apt-get install -y sway waybar swaylock swaybg wl-clipboard wlogout sassc
    install_vimix_cursors
    install_graphite_gtk_theme
    install_tela_icon_theme
    configure_sway_vimix_cursors

    # kanshi
    sudo apt-get install -y kanshi 2>/dev/null || warn "kanshi not in apt, install manually"

    ok "Wayland desktop tools installed"
}

# ---------------------------------------------------------------------------
# Run selected categories
# ---------------------------------------------------------------------------
INSTALL_FNS=(
    [0]=install_shell
    [1]=install_build_tools
    [2]=install_rust
    [3]=install_nvim
    [4]=install_git
    [5]=install_terminal
    [6]=install_desktop_x11
    [7]=install_desktop_wayland
)

echo ""
info "Starting installation..."
echo ""

for i in "${!CATEGORIES[@]}"; do
    cat="${CATEGORIES[$i]}"
    if [[ ${SELECTED[$cat]} -eq 1 ]]; then
        if ${INSTALL_FNS[$i]}; then
            RESULTS[$cat]="ok"
        else
            RESULTS[$cat]="fail"
        fi
    else
        RESULTS[$cat]="skip"
    fi
    echo ""
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
info "Installation summary:"
echo ""
for i in "${!CATEGORIES[@]}"; do
    cat="${CATEGORIES[$i]}"
    case "${RESULTS[$cat]}" in
        ok)   ok "${LABELS[$i]}" ;;
        fail) fail "${LABELS[$i]}" ;;
        skip) warn "${LABELS[$i]}" ;;
    esac
done
echo ""
info "Next step: run config-init.sh to deploy your dotfiles"
echo -e "  ${BOLD}curl -fsSL https://raw.githubusercontent.com/kplieven/dotfiles/master/scripts/config-init.sh | bash${RESET}"
echo ""
