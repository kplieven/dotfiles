#!/usr/bin/env bash
set -euo pipefail

script_dir="$(readlink -f -- "$(dirname -- "${BASH_SOURCE[0]}")/..")"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home/.zsh" \
    "$tmp_dir/home/.local/share/fonts/JetBrainsMonoNerdFont" \
    "$tmp_dir/home/.local/share/fonts/0xProtoNerdFont" \
    "$tmp_dir/home/.local/share/fonts/NerdFontsSymbolsOnly"
touch "$tmp_dir/home/.zsh/antigen.zsh" \
    "$tmp_dir/home/.local/share/fonts/0xProtoNerdFont/0xProtoNerdFont-Regular.ttf" \
    "$tmp_dir/home/.local/share/fonts/NerdFontsSymbolsOnly/Symbols.ttf"

# Run the real menu and installer; only external commands and input are mocked.
cat > "$tmp_dir/mocks.sh" <<'EOF'
trace() { printf '%s\n' "$*" >> "$TEST_LOG"; }
command() {
    [[ "$#" -eq 2 && "$1" == -v ]] || {
        echo "Unexpected command probe: $*" >&2
        return 1
    }
    [[ "$2" != zsh || "$TEST_CHANGE" != zsh-unavailable ]] || return 1
    case "$2" in
        zsh|starship|eza|rg|bat|fd|dust|btm|rip|cpx|cargo-binstall|\
        gcc|clang|cmake|ninja|meson|gdb|valgrind|pkg-config|rustup|cargo|\
        nvim|tree-sitter|fnm|node|npm|mmdc|git|lazygit|kitty|docker)
            printf '/usr/bin/%s\n' "$2" ;;
        *) return 1 ;;
    esac
}
id() { [[ "$*" == -u ]] && echo 1001; }
getent() {
    trace "getent $*"
    [[ "$*" == "passwd 1001" ]] || {
        echo "Unexpected account lookup: $*" >&2
        return 1
    }
    case "$TEST_CHANGE" in
        lookup-failed) echo "mock account lookup failed" >&2; return 2 ;;
        empty-record) return 0 ;;
    esac
    printf 'testuser:x:1001:1001:Test User:%s:%s\n' "$HOME" "$(cat "$TEST_ACCOUNT")"
}
which() { [[ "$*" == zsh ]] && echo /usr/bin/zsh; }
chsh() {
    trace "chsh $*"
    [[ "$*" == "-s /usr/bin/zsh" ]] || {
        echo "Unexpected shell change: $*" >&2
        return 1
    }
    if [[ "${TEST_AUTH:-}" == required ]]; then
        local password
        printf 'Password: ' >&2
        if ! builtin read -rs password || [[ "$password" != test-password ]]; then
            echo "mock chsh: PAM: Authentication failure" >&2
            return 1
        fi
        printf '\n' >&2
    fi
    if [[ "$TEST_CHANGE" == denied ]]; then
        echo "mock chsh: Permission denied" >&2
        return 1
    fi
    printf '/usr/bin/zsh\n' > "$TEST_ACCOUNT"
}
sudo() {
    trace "sudo $*"
    case "$*" in
        "apt-get update -qq"|"apt-get install -y zsh jq") return 0 ;;
        *) echo "Unexpected sudo command: $*" >&2; return 1 ;;
    esac
}
cargo-binstall() {
    trace "cargo-binstall $*"
    [[ "$*" == "-y --root $HOME/.local eza" || \
       "$*" == "-y --root $HOME/.local ripgrep" || \
       "$*" == "-y --root $HOME/.local bat" || \
       "$*" == "-y --root $HOME/.local fd-find" || \
       "$*" == "-y --root $HOME/.local du-dust" || \
       "$*" == "-y --root $HOME/.local starship" || \
       "$*" == "-y --root $HOME/.local bottom" || \
       "$*" == "-y --root $HOME/.local rm-improved" || \
       "$*" == "-y --root $HOME/.local cpx" ]]
}
curl() { echo "Unexpected network request: $*" >&2; return 1; }
git() { echo "Unexpected git operation: $*" >&2; return 1; }
rm() { echo "Unexpected installer removal: $*" >&2; return 1; }
cd() { echo "Unexpected installer directory change: $*" >&2; return 1; }
pushd() { echo "Unexpected installer directory change: $*" >&2; return 1; }
make() { echo "Unexpected source build: $*" >&2; return 1; }
# Leave the default shell tick unchanged; deselect only the missing desktops.
menu_keys=(
    $'\x1b' '[B' $'\x1b' '[B' $'\x1b' '[B' $'\x1b' '[B'
    $'\x1b' '[B' $'\x1b' '[B' $'\x1b' '[B' ''
    $'\x1b' '[B' '' q
)
menu_index=0
read() {
    [[ "$menu_index" -lt "${#menu_keys[@]}" ]] || return 1
    printf -v "${!#}" '%s' "${menu_keys[$menu_index]}"
    menu_index=$(( menu_index + 1 ))
}
EOF

cat > "$tmp_dir/terminal.py" <<'EOF'
import errno
import os
import pty
import select
import signal
import sys
import time

mode, installer = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0:
    if mode == "curl-pipe":
        os.execvp("bash", ["bash", "-c", 'cat "$1" | bash -s -- --shell', "bash", installer])
    os.execvp("bash", ["bash", installer, "--shell"])

output = bytearray()
answered = False
finished = False
try:
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if not select.select([fd], [], [], max(0, deadline - time.monotonic()))[0]:
            break
        try:
            chunk = os.read(fd, 4096)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            break
        if not chunk:
            break
        output.extend(chunk)
        if not answered and b"Password: " in output:
            os.write(fd, b"test-password\n")
            answered = True
    exited, status = os.waitpid(pid, os.WNOHANG)
    if not exited:
        raise AssertionError("installer did not finish after password input")
    finished = True
    assert os.waitstatus_to_exitcode(status) == 0, "installer failed"
    assert answered, "password prompt was not displayed"
finally:
    if not finished:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
    os.close(fd)
    sys.stdout.write(output.decode(errors="replace"))
EOF

fail_case() {
    cat "$output" "$log" >&2
    echo "FAIL: $name: $*" >&2
    return 1
}

run_case() {
    local name="$1" mode="$2" account="$3" environment="$4" change="$5"
    local output="$tmp_dir/output" log="$tmp_dir/log" account_file="$tmp_dir/account"
    printf '%s\n' "$account" > "$account_file"
    : > "$log"
    local -a runner=(bash "$script_dir/dependencies.sh" --shell)
    local auth=none
    if [[ "$mode" == menu ]]; then
        runner=(script -q -e -c "bash '$script_dir/dependencies.sh'" /dev/null)
    elif [[ "$mode" == terminal || "$mode" == curl-pipe ]]; then
        runner=(python3 "$tmp_dir/terminal.py" "$mode" "$script_dir/dependencies.sh")
        auth=required
    fi
    if ! HOME="$tmp_dir/home" PATH=/usr/bin:/bin SHELL="$environment" USER=wronguser \
        BASH_ENV="$tmp_dir/mocks.sh" TEST_LOG="$log" TEST_ACCOUNT="$account_file" \
        TEST_CHANGE="$change" TEST_AUTH="$auth" timeout 10 "${runner[@]}" </dev/null >"$output" 2>&1; then
        fail_case "installer failed or waited for input"
        return 1
    fi
    sed -i $'s/\033\\[[0-9;?]*[A-Za-z]//g; s/\r//g' "$output"
    if grep -Fq 'Unexpected ' "$output"; then
        fail_case "installer attempted an unexpected external operation"
        return 1
    fi
    if [[ "$change" == ok ]] && grep -Fq '[FAIL]' "$output"; then
        fail_case "installer reported an unexpected failure"
        return 1
    fi

    if [[ "$mode" == menu ]]; then
        local first_shell
        first_shell="$(grep '1) .*Shell ' "$output" | head -n 1)"
        if [[ "${account##*/}" == zsh ]]; then
            [[ "$first_shell" == *"[ ]"* ]] \
                || { fail_case "configured zsh was not marked complete"; return 1; }
        else
            [[ "$first_shell" == *"[x]"* && "$first_shell" == *"(11/12)"* ]] \
                || { fail_case "all tools with account bash did not preselect an incomplete shell"; return 1; }
        fi
        for desktop in 'Desktop (X11)' 'Desktop (Sway)'; do
            [[ "$(grep -F "$desktop" "$output" | grep -E '^[[:space:]>]*[0-9]+\)' | tail -n 1)" == *"[ ]"* ]] \
                || { fail_case "$desktop was not disabled in the menu"; return 1; }
        done
    fi

    if [[ "$change" != ok ]]; then
        grep -Fq '[FAIL]  Shell ' "$output" \
            || { fail_case "shell category failure was not reported"; return 1; }
        if grep -Eq 'Default shell set to zsh|Shell tools installed' "$output"; then
            fail_case "shell failure was reported as success"
            return 1
        fi
        if [[ "$change" == denied ]]; then
            grep -Fq 'mock chsh: Permission denied' "$output" \
                || { fail_case "chsh error was hidden"; return 1; }
            grep -Fq 'Could not set default shell to zsh' "$output" \
                || { fail_case "shell change failure had no context"; return 1; }
        elif grep -q '^chsh ' "$log"; then
            fail_case "unknown account shell triggered chsh"
            return 1
        fi
        case "$change" in
            lookup-failed)
                grep -Fq 'Could not determine configured login shell' "$output" \
                    || { fail_case "account lookup failure was hidden"; return 1; } ;;
            empty-record)
                grep -Fq 'no valid configured login shell' "$output" \
                    || { fail_case "missing account record was hidden"; return 1; } ;;
            zsh-unavailable)
                grep -Fq 'Could not find zsh' "$output" \
                    || { fail_case "missing zsh was not reported"; return 1; } ;;
        esac
    elif [[ "${account##*/}" == zsh ]]; then
        if grep -q '^chsh ' "$log"; then
            fail_case "account zsh with stale SHELL triggered chsh"
            return 1
        fi
        if [[ "$mode" == flag ]]; then
            grep -Fq 'zsh is already the default shell' "$output" \
                || { fail_case "configured zsh was not skipped"; return 1; }
        elif [[ -s "$log" ]] && grep -q '^sudo ' "$log"; then
            fail_case "complete shell or unselected categories triggered installation"
            return 1
        fi
    else
        grep -Fxq 'chsh -s /usr/bin/zsh' "$log" \
            || { fail_case "account bash was not changed to zsh"; return 1; }
        [[ "$(cat "$account_file")" == /usr/bin/zsh ]] \
            || { fail_case "configured shell was not changed"; return 1; }
        grep -Fq 'Default shell set to zsh' "$output" \
            || { fail_case "successful shell change was not reported"; return 1; }
        # Repeat with the same stale environment and the updated account.
        if ! HOME="$tmp_dir/home" PATH=/usr/bin:/bin SHELL="$environment" USER=wronguser \
            BASH_ENV="$tmp_dir/mocks.sh" TEST_LOG="$log" TEST_ACCOUNT="$account_file" \
            TEST_CHANGE=ok timeout 10 bash "$script_dir/dependencies.sh" --shell \
            >"$output" 2>&1; then
            fail_case "rerun failed or waited for input"
            return 1
        fi
        [[ "$(grep -c '^chsh ' "$log")" -eq 1 ]] \
            || { fail_case "rerun repeated chsh despite updated account"; return 1; }
        grep -Fq 'zsh is already the default shell' "$output" \
            || { fail_case "rerun did not recognize the updated account"; return 1; }
        if grep -Fq '[FAIL]' "$output"; then
            fail_case "rerun reported a shell failure"
            return 1
        fi
    fi
    echo "PASS: $name"
}

failed=0
run_case headless-default menu /bin/bash /bin/bash ok || failed=1
run_case complete-menu-stale-env menu /bin/zsh /bin/bash ok || failed=1
run_case configured-zsh-stale-env flag /usr/bin/zsh /bin/bash ok || failed=1
run_case configured-bash-stale-env flag /bin/bash /usr/bin/zsh ok || failed=1
run_case misleading-shell-name flag /bin/not-zsh /bin/not-zsh ok || failed=1
run_case chsh-denied flag /bin/bash /bin/bash denied || failed=1
run_case account-lookup-failed flag /bin/bash /usr/bin/zsh lookup-failed || failed=1
run_case account-record-missing flag /bin/bash /usr/bin/zsh empty-record || failed=1
run_case zsh-unavailable flag /bin/bash /bin/bash zsh-unavailable || failed=1
run_case terminal-password terminal /bin/bash /bin/bash ok || failed=1
run_case curl-pipe-password curl-pipe /bin/bash /bin/bash ok || failed=1
run_case curl-pipe-password-denied curl-pipe /bin/bash /bin/bash denied || failed=1
exit "$failed"
