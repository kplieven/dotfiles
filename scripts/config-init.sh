#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles config installer
#
# Checks out only the selected packages from the bare dotfiles repo, using
# git sparse-checkout. Unselected files stay in the repo and keep receiving
# upstream changes, they are just never written to $HOME.
#
# Usage:
#   Interactive:  ./config-init.sh
#   Selective:    ./config-init.sh --shell --nvim
#   Everything:   ./config-init.sh --all
#   Curl pipe:    curl -fsSL <url> | bash   (opens the same menu)
#
# Once installed, the same script is reachable as:
#   config packages [list|add <pkg>...|remove <pkg>...]
# =============================================================================

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/kplieven/dotfiles.git}"
BACKUP_DIR="$HOME/.dotfiles-backup"
SCRIPT_PATH="$HOME/scripts/config-init.sh"

# When invoked as `config packages`, git exports these into our environment,
# where they would hijack the git calls below.
unset GIT_DIR GIT_WORK_TREE

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

info()  { echo -e "${BLUE}${BOLD}::${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}${BOLD}[SKIP]${RESET}  $*"; }
fail()  { echo -e "${RED}${BOLD}[FAIL]${RESET}  $*"; }

config() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# ---------------------------------------------------------------------------
# Packages
#
# Names mirror dependencies.sh so a machine's installed categories can be
# detected. build-tools, rust and docker own no dotfiles and are absent here.
# ---------------------------------------------------------------------------
PACKAGES=(shell nvim git terminal desktop-x11 desktop-wayland copilot agents)
LABELS=(
    "Shell          — .zshrc, .zsh/, starship"
    "Neovim         — .config/nvim/"
    "Git            — .gitconfig, .gitconfig-barco, lazygit"
    "Terminal       — kitty"
    "Desktop (X11)  — i3, polybar, dunst, rofi, picom, betterlockscreen, wallpapers"
    "Desktop (Sway) — sway, waybar, kanshi"
    "Copilot        — .copilot/ (settings, skills, statusline extension)"
    "Agents         — .agents/, .github/"
)

declare -A PATTERNS=(
    [shell]="/.zshrc /.zsh/ /.config/starship.toml"
    [nvim]="/.config/nvim/"
    [git]="/.gitconfig /.gitconfig-barco /.config/lazygit/"
    [terminal]="/.config/kitty/"
    [desktop-x11]="/.config/i3/ /.config/polybar/ /.config/dunst/ /.config/rofi/ /.config/picom.conf /.config/betterlockscreen/ /.xsessionrc /Pictures/wallpapers/"
    [desktop-wayland]="/.config/sway/ /.config/waybar/ /.config/kanshi/"
    [copilot]="/.copilot/"
    [agents]="/.agents/ /.github/"
)

# Binary whose presence means the matching dependencies.sh category was
# installed. Packages with no binary are detected by what is checked out.
declare -A DETECT=(
    [shell]="zsh"
    [nvim]="nvim"
    [git]="lazygit"
    [terminal]="kitty"
    [desktop-x11]="i3"
    [desktop-wayland]="sway"
    [copilot]=""
    [agents]=""
)

# Always checked out — scripts/ carries this script and dependencies.sh.
BASE_PATTERNS=(/README.md /scripts/)

# GTK theming is shared by both desktops; it follows whichever is selected.
GTK_PATTERNS=(/.config/gtk-3.0/ /.config/gtk-4.0/)

declare -A SELECTED
for pkg in "${PACKAGES[@]}"; do SELECTED[$pkg]=0; done

# ---------------------------------------------------------------------------
# Pattern / pathspec helpers
# ---------------------------------------------------------------------------

# Sparse patterns are anchored with a leading slash; git pathspecs are not.
pathspec_of() {
    local p="${1#/}"
    printf '%s\n' "${p%/}"
}

# Patterns for the given packages, without the always-on base set.
package_patterns() {
    local pkg pat
    for pkg in "$@"; do
        for pat in ${PATTERNS[$pkg]}; do
            printf '%s\n' "$pat"
        done
    done
}

# The full sparse-checkout pattern list for a selection.
selection_patterns() {
    local pkg desktop=0
    printf '%s\n' "${BASE_PATTERNS[@]}"
    for pkg in "$@"; do
        [[ "$pkg" == desktop-* ]] && desktop=1
    done
    (( desktop )) && printf '%s\n' "${GTK_PATTERNS[@]}"
    package_patterns "$@"
}

selected_packages() {
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        [[ ${SELECTED[$pkg]} -eq 1 ]] && printf '%s\n' "$pkg"
    done
    return 0
}

is_package() {
    local pkg candidate="$1"
    for pkg in "${PACKAGES[@]}"; do
        [[ "$pkg" == "$candidate" ]] && return 0
    done
    return 1
}

# Tracked files of the given packages that currently exist in $HOME.
package_files_on_disk() {
    local -a specs=()
    local pat file
    while IFS= read -r pat; do
        specs+=("$(pathspec_of "$pat")")
    done < <(package_patterns "$@")
    [[ ${#specs[@]} -gt 0 ]] || return 0
    while IFS= read -r file; do
        [[ -e "$HOME/$file" ]] && printf '%s\n' "$file"
    done < <(config ls-files -- "${specs[@]}" 2>/dev/null)
    return 0
}

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
repo_exists()  { [[ -d "$DOTFILES_DIR" ]]; }
sparse_active() { [[ "$(config config --get core.sparseCheckout 2>/dev/null || echo false)" == "true" ]]; }

# Packages recorded by the last run, if any.
recorded_packages() {
    config config --get dotfiles.packages 2>/dev/null || true
}

# Pre-tick rule: a package is on if its dependency binary is installed, or if
# its files are already checked out. The second half makes re-runs show the
# current selection rather than re-deriving it from the machine.
detect_packages() {
    local pkg bin recorded
    recorded="$(recorded_packages)"

    if [[ -n "$recorded" ]]; then
        printf '%s\n' $recorded
        return 0
    fi

    for pkg in "${PACKAGES[@]}"; do
        bin="${DETECT[$pkg]}"
        if [[ -n "$bin" ]] && command -v "$bin" &>/dev/null; then
            printf '%s\n' "$pkg"
        elif repo_exists && [[ -n "$(package_files_on_disk "$pkg" | head -1)" ]]; then
            printf '%s\n' "$pkg"
        fi
    done
    return 0
}

preselect() {
    local pkg
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && is_package "$pkg" && SELECTED[$pkg]=1
    done < <(detect_packages)
}

# ---------------------------------------------------------------------------
# Apply a selection
# ---------------------------------------------------------------------------

# Refuse to drop a package with uncommitted work: git would leave those files
# behind, where they show up as modified but sit outside the selection and so
# can no longer be committed.
assert_clean() {
    local -a specs=()
    local pat dirty
    while IFS= read -r pat; do
        specs+=("$(pathspec_of "$pat")")
    done < <(package_patterns "$@")
    [[ ${#specs[@]} -gt 0 ]] || return 0

    dirty="$(config status --porcelain -- "${specs[@]}" 2>/dev/null || true)"
    [[ -z "$dirty" ]] && return 0

    fail "These files have uncommitted changes and would be left behind:"
    printf '%s\n' "$dirty" | sed 's/^/    /'
    echo ""
    echo "Commit or discard them first:"
    echo -e "  ${BOLD}config commit -am 'your message'${RESET}   or   ${BOLD}config checkout -- <file>${RESET}"
    return 1
}

apply_selection() {
    local -a pkgs=("$@")
    local -a pats=()
    local pat
    while IFS= read -r pat; do
        pats+=("$pat")
    done < <(selection_patterns "${pkgs[@]}")

    config sparse-checkout set --no-cone "${pats[@]}"
    config config dotfiles.packages "${pkgs[*]}"
}

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
show_list() {
    local pkg i state count
    echo ""
    info "Dotfiles packages:"
    echo ""
    for i in "${!PACKAGES[@]}"; do
        pkg="${PACKAGES[$i]}"
        count="$(package_files_on_disk "$pkg" | wc -l)"
        if [[ ${SELECTED[$pkg]} -eq 1 ]]; then
            state="${GREEN}${BOLD}[x]${RESET}"
        else
            state="[ ]"
        fi
        echo -e " ${state} ${BOLD}$(printf '%-16s' "$pkg")${RESET} ${LABELS[$i]}"
        [[ ${SELECTED[$pkg]} -eq 1 ]] && echo -e "     ${count} file(s) in \$HOME"
    done
    echo ""
    echo -e "  Change with: ${BOLD}config packages${RESET}  |  ${BOLD}config packages add <pkg>${RESET}  |  ${BOLD}config packages remove <pkg>${RESET}"
    echo ""
}

# ---------------------------------------------------------------------------
# Interactive menu — reads keys from /dev/tty so it works under curl | bash,
# where stdin is the script itself.
# ---------------------------------------------------------------------------
confirm() {
    local message="$1" reply
    $ASSUME_YES && return 0
    if [[ -t 0 ]]; then
        read -rp "$(echo -e "${BOLD}${message}${RESET} [y/N]: ")" reply
    else
        read -rp "$(echo -e "${BOLD}${message}${RESET} [y/N]: ")" reply </dev/tty 2>/dev/null || reply="n"
    fi
    [[ "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
}

# `[[ -r /dev/tty ]]` is not enough: with no controlling terminal the device
# node still passes an access() check but cannot be opened.
tty_available() {
    ( exec </dev/tty ) 2>/dev/null
}

show_menu() {
    local current="$1" i pkg marker cursor

    printf '\033[H\033[2J'
    echo ""
    info "Select dotfiles packages to check out:"
    echo ""
    for i in "${!PACKAGES[@]}"; do
        pkg="${PACKAGES[$i]}"
        cursor=" "
        if [[ ${SELECTED[$pkg]} -eq 1 ]]; then
            marker="${GREEN}[x]${RESET}"
        else
            marker="[ ]"
        fi
        [[ "$i" -eq "$current" ]] && cursor="${BLUE}>${RESET}"
        echo -e " ${cursor} ${BOLD}$((i + 1))${RESET}) ${marker} ${LABELS[$i]}"
    done
    echo ""
    echo -e "  ${BOLD}↑/↓${RESET} Move    ${BOLD}Enter${RESET} Toggle    ${BOLD}q${RESET} Confirm    ${BOLD}a${RESET} Select all    ${BOLD}n${RESET} Select none"
    echo ""
    echo -e "  Unticked packages stay in the repo — they are only removed from \$HOME."
    echo ""
}

interactive_menu() {
    if ! tty_available; then
        fail "No terminal available for the selection menu."
        echo "Pass packages explicitly, for example:"
        echo -e "  ${BOLD}--shell --nvim${RESET}   or   ${BOLD}--all${RESET}"
        exit 1
    fi

    local current=0 total="${#PACKAGES[@]}" key pkg

    printf '\033[?25l'
    trap 'printf "\033[?25h"' RETURN

    while true; do
        show_menu "$current"
        if ! IFS= read -rsn1 key </dev/tty; then
            printf '\033[?25h'
            echo ""
            warn "Input closed — aborted, nothing changed."
            exit 0
        fi

        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 key </dev/tty || true
            key=$'\x1b'"$key"
        fi

        case "$key" in
            "")
                pkg="${PACKAGES[$current]}"
                SELECTED[$pkg]=$(( 1 - ${SELECTED[$pkg]} ))
                ;;
            q|Q) break ;;
            a|A) for pkg in "${PACKAGES[@]}"; do SELECTED[$pkg]=1; done ;;
            n|N) for pkg in "${PACKAGES[@]}"; do SELECTED[$pkg]=0; done ;;
            $'\x1b[A') current=$(( (current - 1 + total) % total )) ;;
            $'\x1b[B') current=$(( (current + 1) % total )) ;;
            *) ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Checkout (fresh clone only — sparse-checkout updates the work tree itself
# on a repo that is already checked out)
# ---------------------------------------------------------------------------
checkout_with_backup() {
    local checkout_output checkout_ok file

    info "Checking out selected packages..."
    checkout_output=$(config checkout 2>&1) && checkout_ok=true || checkout_ok=false

    if [[ "$checkout_ok" == false ]] && grep -q "would be overwritten" <<<"$checkout_output"; then
        info "Backing up conflicting files to $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        while IFS= read -r file; do
            file="$(echo "$file" | xargs)"
            if [[ -n "$file" && -e "$HOME/$file" ]]; then
                mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                mv "$HOME/$file" "$BACKUP_DIR/$file"
                echo "  Backed up: $file"
            fi
        done < <(grep $'^\t' <<<"$checkout_output" || true)
        config checkout
    elif [[ "$checkout_ok" == false ]]; then
        fail "Failed to check out dotfiles."
        echo "$checkout_output"
        exit 1
    fi

    ok "Dotfiles checked out"
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "       config packages [list | add <pkg>... | remove <pkg>...]"
    echo ""
    echo "Options:"
    echo "  --all              Check out every package"
    local i
    for i in "${!PACKAGES[@]}"; do
        printf '  --%-16s %s\n' "${PACKAGES[$i]}" "${LABELS[$i]}"
    done
    echo "  --list             Show packages and what is checked out"
    echo "  --yes              Do not prompt before removing files from \$HOME"
    echo "  --help             Show this help message"
    echo ""
    echo "With no arguments an interactive menu is shown, pre-selected from the"
    echo "packages already checked out, or from the dependencies detected on"
    echo "this machine on a first run."
}

MODE="menu"
ASSUME_YES=false
declare -a ARG_PKGS=()

parse_args() {
    # --yes may precede a subcommand: `packages --yes remove nvim`
    local -a rest=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            --yes|-y) ASSUME_YES=true ;;
            *) rest+=("$arg") ;;
        esac
    done
    set -- "${rest[@]}"

    [[ $# -eq 0 ]] && return 0

    case "$1" in
        list|--list) MODE="list"; return 0 ;;
        add|remove)
            MODE="$1"; shift
            if [[ $# -eq 0 ]]; then
                fail "Usage: config packages $MODE <package>..."
                exit 1
            fi
            ARG_PKGS=("$@")
            return 0
            ;;
        --help|-h) usage; exit 0 ;;
    esac

    MODE="apply"
    local pkg name
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all) for pkg in "${PACKAGES[@]}"; do SELECTED[$pkg]=1; done ;;
            --help|-h) usage; exit 0 ;;
            --*)
                name="${1#--}"
                if is_package "$name"; then
                    SELECTED[$name]=1
                else
                    fail "Unknown package: $name"
                    usage
                    exit 1
                fi
                ;;
            *)
                fail "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
parse_args "$@"

FRESH_CLONE=false
if ! repo_exists; then
    info "Cloning bare repository into $DOTFILES_DIR..."
    git clone --bare "$REPO_URL" "$DOTFILES_DIR"
    config config status.showUntrackedFiles no
    FRESH_CLONE=true
fi

# (Re)register the alias on every run so `config packages` self-heals.
config config alias.packages "!bash $SCRIPT_PATH"

case "$MODE" in
    list)
        preselect
        show_list
        exit 0
        ;;
    add|remove)
        preselect
        for pkg in "${ARG_PKGS[@]}"; do
            if ! is_package "$pkg"; then
                fail "Unknown package: $pkg"
                echo "Known packages: ${PACKAGES[*]}"
                exit 1
            fi
            [[ "$MODE" == "add" ]] && SELECTED[$pkg]=1 || SELECTED[$pkg]=0
        done
        ;;
    apply)
        : # flags already populated SELECTED
        ;;
    menu)
        preselect
        interactive_menu
        ;;
esac

# ---------------------------------------------------------------------------
# Work out what leaves $HOME, and make sure that is safe
# ---------------------------------------------------------------------------
declare -a TO_REMOVE=()
if ! $FRESH_CLONE; then
    for pkg in "${PACKAGES[@]}"; do
        if [[ ${SELECTED[$pkg]} -eq 0 ]] && [[ -n "$(package_files_on_disk "$pkg" | head -1)" ]]; then
            TO_REMOVE+=("$pkg")
        fi
    done
fi

if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
    removal_count="$(package_files_on_disk "${TO_REMOVE[@]}" | wc -l)"
    echo ""
    warn "Removing ${#TO_REMOVE[@]} package(s) from \$HOME: ${TO_REMOVE[*]}"
    echo "  ${removal_count} file(s) will be deleted from your home directory."
    echo "  They stay in the repo and keep receiving updates — re-add them any time with:"
    echo -e "    ${BOLD}config packages add ${TO_REMOVE[0]}${RESET}"
    echo ""
    package_files_on_disk "${TO_REMOVE[@]}" | sed 's/^/    /' | head -15
    [[ "$removal_count" -gt 15 ]] && echo "    ... and $((removal_count - 15)) more"
    echo ""

    assert_clean "${TO_REMOVE[@]}" || exit 1

    if ! confirm "Remove these files from \$HOME?"; then
        warn "Aborted — nothing changed."
        exit 0
    fi
fi

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------
declare -a CHOSEN=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && CHOSEN+=("$pkg")
done < <(selected_packages)

info "Applying selection: ${CHOSEN[*]:-<none>}"
apply_selection "${CHOSEN[@]}"

if $FRESH_CLONE; then
    checkout_with_backup
fi

ok "Sparse checkout updated"

# ---------------------------------------------------------------------------
# Package-specific follow-up
# ---------------------------------------------------------------------------
if [[ ${SELECTED[copilot]} -eq 1 ]]; then
    knowledge_installer="$HOME/.copilot/extensions/knowledge-tracking/install.mjs"
    if [[ -f "$knowledge_installer" ]] && command -v node &>/dev/null; then
        info "Installing knowledge-tracking statusline extension..."
        node "$knowledge_installer" install
        ok "Knowledge-tracking extension installed"
    elif [[ ! -f "$knowledge_installer" ]]; then
        warn "knowledge-tracking installer not found — skipping"
    else
        warn "node not installed — skipping knowledge-tracking extension"
    fi
fi

show_list

info "Pull and push work as usual and stay limited to your selection:"
echo -e "  ${BOLD}config pull${RESET}    updates only checked-out files"
echo -e "  ${BOLD}config status${RESET}  only ever sees your selected packages"
echo ""
