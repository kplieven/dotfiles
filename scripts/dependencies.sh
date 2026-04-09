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

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------
CATEGORIES=(shell rust nvim git terminal desktop-x11 desktop-wayland)
LABELS=(
    "Shell          — zsh, antigen, set as default shell"
    "Rust toolchain — rustup, eza, ripgrep, bat, fd, starship, bottom, rm-improved"
    "Neovim         — build from source, sync plugins"
    "Git tools      — lazygit"
    "Terminal       — kitty, JetBrains Mono Nerd Font"
    "Desktop (X11)  — i3, picom, polybar, dunst, i3status-rust"
    "Desktop (Sway) — sway, waybar, kanshi"
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
    echo "  --rust             Rust toolchain and cargo CLI tools"
    echo "  --nvim             Neovim (built from source)"
    echo "  --git              Lazygit"
    echo "  --terminal         Kitty terminal, JetBrains Mono Nerd Font"
    echo "  --desktop-x11      i3, polybar, dunst, i3status-rust"
    echo "  --desktop-wayland  Sway, waybar, kanshi"
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
            --shell|--rust|--nvim|--git|--terminal|--desktop-x11|--desktop-wayland)
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
    echo ""
    info "Select categories to install (toggle with number, Enter to confirm):"
    echo ""
    for i in "${!CATEGORIES[@]}"; do
        local cat="${CATEGORIES[$i]}"
        local marker
        if [[ ${SELECTED[$cat]} -eq 1 ]]; then
            marker="${GREEN}[x]${RESET}"
        else
            marker="[ ]"
        fi
        echo -e "  ${BOLD}$((i + 1))${RESET}) ${marker} ${LABELS[$i]}"
    done
    echo ""
    echo -e "  ${BOLD}a${RESET}) Select all    ${BOLD}n${RESET}) Select none    ${BOLD}Enter${RESET}) Confirm"
    echo ""
}

interactive_menu() {
    while true; do
        show_menu
        local choice
        read -rp "$(echo -e "${BOLD}>${RESET} ")" choice

        case "$choice" in
            "")
                break
                ;;
            a|A)
                for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=1; done
                ;;
            n|N)
                for cat in "${CATEGORIES[@]}"; do SELECTED[$cat]=0; done
                ;;
            [1-7])
                local idx=$((choice - 1))
                local cat="${CATEGORIES[$idx]}"
                SELECTED[$cat]=$(( 1 - ${SELECTED[$cat]} ))
                ;;
            *)
                echo "Invalid input."
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

    sudo apt-get install -y zsh

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
# Category: Rust toolchain
# ---------------------------------------------------------------------------
install_rust() {
    info "Installing Rust toolchain..."

    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --no-modify-path
    else
        warn "rustup already installed"
    fi

    # make cargo available in this session
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    info "Installing cargo CLI tools (this may take a while)..."
    local tools=(eza ripgrep bat fd-find starship bottom rm-improved)
    for tool in "${tools[@]}"; do
        cargo install "$tool" 2>/dev/null && ok "$tool" || fail "$tool"
    done

    ok "Rust toolchain installed"
}

# ---------------------------------------------------------------------------
# Category: Neovim
# ---------------------------------------------------------------------------
install_nvim() {
    info "Installing Neovim from source..."

    local default_version="v0.12.1"
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

    # kitty
    if ! command -v kitty &>/dev/null; then
        curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
        local kitty_bin="$HOME/.local/kitty.app/bin"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$kitty_bin/kitty" "$HOME/.local/bin/kitty"
        ln -sf "$kitty_bin/kitten" "$HOME/.local/bin/kitten"
        ok "kitty installed"
    else
        warn "kitty already installed"
    fi

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

    ok "Terminal tools installed"
}

# ---------------------------------------------------------------------------
# Category: Desktop (i3 / X11)
# ---------------------------------------------------------------------------
install_desktop_x11() {
    info "Installing X11 desktop tools..."

    sudo apt-get install -y i3 dunst picom

    # polybar
    sudo apt-get install -y polybar 2>/dev/null || warn "polybar not in apt, install manually"

    # i3status-rust (cargo)
    if [[ -f "$HOME/.cargo/env" ]]; then
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi
    if command -v cargo &>/dev/null; then
        cargo install i3status-rs 2>/dev/null && ok "i3status-rust" || fail "i3status-rust"
    else
        warn "cargo not available — skipping i3status-rust (install Rust category first)"
    fi

    ok "X11 desktop tools installed"
}

# ---------------------------------------------------------------------------
# Category: Desktop (Sway / Wayland)
# ---------------------------------------------------------------------------
install_desktop_wayland() {
    info "Installing Wayland desktop tools..."

    sudo apt-get install -y sway waybar

    # kanshi
    sudo apt-get install -y kanshi 2>/dev/null || warn "kanshi not in apt, install manually"

    ok "Wayland desktop tools installed"
}

# ---------------------------------------------------------------------------
# Run selected categories
# ---------------------------------------------------------------------------
INSTALL_FNS=(
    [0]=install_shell
    [1]=install_rust
    [2]=install_nvim
    [3]=install_git
    [4]=install_terminal
    [5]=install_desktop_x11
    [6]=install_desktop_wayland
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
