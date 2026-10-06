#!/usr/bin/env bash
set -euo pipefail

script_dir="$(readlink -f -- "$(dirname -- "${BASH_SOURCE[0]}")/..")"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home"

# BASH_ENV mocks external effects while running the entire installer.
cat > "$tmp_dir/mocks.sh" <<'EOF'
trace() { printf '%s\n' "$*" >> "$TEST_LOG"; }
sudo() {
    trace "sudo $*"
    case "$*" in
        apt-get\ *|make\ install) return 0 ;;
        *) echo "Unexpected sudo command: $*" >&2; return 1 ;;
    esac
}
curl() {
    trace "curl $*"
    if [[ "$*" != "-fsSL https://api.github.com/repos/neovim/neovim/releases/latest" ]]; then
        echo "Unexpected download: $*" >&2
        return 1
    fi
    [[ "$TEST_RELEASE" != unavailable ]] || return 1
    printf '{"tag_name": "%s"}\n' "$TEST_RELEASE"
}
fnm() {
    trace "fnm $*"
    case "$*" in
        "env --shell bash") echo ":" ;;
        default) echo "v22.0.0" ;;
        "use default") return 0 ;;
        *) echo "Unexpected fnm command: $*" >&2; return 1 ;;
    esac
}
node() { return 0; }
npm() {
    trace "npm $*"
    [[ "$*" == "list -g --depth=0 @mermaid-js/mermaid-cli" ]]
}
nvim() {
    [[ "$TEST_INSTALLED" != absent ]] || return 1
    printf 'NVIM %s\n' "$TEST_INSTALLED"
}
tree-sitter() { return 0; }
cargo-binstall() { trace "cargo-binstall $*"; }
git() { trace "git $*"; }
make() { trace "make $*"; }
nproc() { echo 2; }
# Never touch the installer's shared /tmp/neovim-build directory.
rm() {
    trace "rm $*"
    [[ "$*" == "-rf /tmp/neovim-build" ]]
}
pushd() { [[ "$*" == /tmp/neovim-build ]]; }
popd() { return 0; }
EOF

cat > "$tmp_dir/terminal.py" <<'EOF'
import errno
import os
import pty
import select
import signal
import sys
import time

mode, installer, reply, default, should_prompt = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0:
    if mode == "curl-pipe":
        os.execvp("bash", ["bash", "-c", 'cat "$1" | bash -s -- --nvim', "bash", installer])
    os.execvp("bash", ["bash", installer, "--nvim"])

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
        if not answered and b"Neovim version to build" in output and f"[{default}]: ".encode() in output:
            # Send input only AFTER the user-visible prompt has appeared.
            os.write(fd, b"\x04" if reply == "__EOF__" else (reply + "\n").encode())
            answered = True
    else:
        raise AssertionError("installer waited without a visible version prompt")
    exited, status = os.waitpid(pid, os.WNOHANG)
    if not exited:
        raise AssertionError("installer did not finish after showing the prompt and reading input")
    finished = True
    assert os.waitstatus_to_exitcode(status) == 0, "installer failed"
    assert answered == (should_prompt == "yes"), "version prompt missing or shown for up-to-date install"
finally:
    if not finished:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
    os.close(fd)
    sys.stdout.write(output.decode(errors="replace"))
EOF

fail_case() {
    cat "$output" "$log" >&2
    echo "FAIL: $mode/$installed/$release: $*" >&2
    exit 1
}

run_case() {
    local mode="$1" installed="$2" release="$3" expected="$4" reply="${5:-}"
    local output="$tmp_dir/output" log="$tmp_dir/log"
    local default="$release" should_prompt=yes
    [[ "$release" != unavailable ]] || default=v0.12.4
    [[ "$installed" != "$default" ]] || should_prompt=no
    : > "$log"
    if [[ "$mode" != no-terminal ]]; then
        if ! HOME="$tmp_dir/home" PATH=/usr/bin:/bin BASH_ENV="$tmp_dir/mocks.sh" \
            TEST_LOG="$log" TEST_INSTALLED="$installed" TEST_RELEASE="$release" \
            python3 "$tmp_dir/terminal.py" "$mode" "$script_dir/dependencies.sh" \
            "$reply" "$default" "$should_prompt" >"$output" 2>&1; then
            fail_case "installer failed or did not display its prompt before waiting"
        fi
    else
        if ! HOME="$tmp_dir/home" PATH=/usr/bin:/bin BASH_ENV="$tmp_dir/mocks.sh" \
            TEST_LOG="$log" TEST_INSTALLED="$installed" TEST_RELEASE="$release" \
            timeout 10 setsid --wait bash "$script_dir/dependencies.sh" --nvim \
            </dev/null >"$output" 2>&1; then
            fail_case "installer failed or waited for input"
        fi
        if [[ "$should_prompt" == yes ]]; then
            grep -Fq "No terminal available" "$output" \
                || fail_case "unattended default selection was not explained"
        fi
    fi
    if grep -Fq '[FAIL]' "$output"; then
        if [[ "$reply" != __EOF__ ]]; then
            fail_case "installer reported a failed category"
        fi
    fi
    if [[ "$reply" == __EOF__ ]]; then
        grep -Fq 'Could not read input for Neovim version to build' "$output" \
            || fail_case "terminal EOF was not reported"
        grep -Eq '\[FAIL\].*Neovim ' "$output" \
            || fail_case "terminal EOF did not fail the category"
        if grep -Eq '^(git |make |sudo make |sudo apt-get install |rm |cargo-binstall )' "$log"; then
            fail_case "terminal EOF triggered installation"
        fi
        echo "PASS: $mode/terminal-EOF"
        return 0
    fi
    grep -Fxq 'fnm use default' "$log" || fail_case "Node default was not activated"
    grep -Fxq 'npm list -g --depth=0 @mermaid-js/mermaid-cli' "$log" \
        || fail_case "Mermaid dependencies were not checked"

    if [[ "$installed" == "$expected" ]]; then
        grep -Fq "Neovim $expected is already the latest" "$output" \
            || fail_case "latest installed version was not skipped"
        if grep -Eq '^(git |make |sudo make |sudo apt-get install |rm |cargo-binstall )' "$log"; then
            fail_case "up-to-date Neovim with tree-sitter triggered installation"
        fi
    else
        grep -Fxq "git clone --depth 1 --branch $expected https://github.com/neovim/neovim /tmp/neovim-build" "$log" \
            || fail_case "source clone did not use the expected release"
        grep -Fxq 'make -j 2 CMAKE_BUILD_TYPE=RelWithDebInfo' "$log" \
            || fail_case "source build was not run"
        grep -Fxq 'sudo make install' "$log" || fail_case "built Neovim was not installed"
        grep -Eq '^cargo-binstall .* tree-sitter-cli$' "$log" \
            || fail_case "tree-sitter-cli was not installed"
        grep -Fq "Neovim $expected installed" "$output" \
            || fail_case "installed release was not reported"
    fi
    if [[ "$release" == unavailable ]]; then
        grep -Fq "Could not fetch latest Neovim release tag, falling back to $expected" "$output" \
            || fail_case "release-fetch failure was not reported"
    fi
    echo "PASS: $mode/$installed/$release -> $expected"
}

for mode in terminal curl-pipe no-terminal; do
    run_case "$mode" absent v0.99.1 v0.99.1
    run_case "$mode" v0.11.0 v0.99.1 v0.99.1
    run_case "$mode" v0.99.1 v0.99.1 v0.99.1
    run_case "$mode" absent unavailable v0.12.4
done
for mode in terminal curl-pipe; do
    run_case "$mode" absent v0.99.1 v0.11.0 v0.11.0
    run_case "$mode" absent v0.99.1 v0.99.1 __EOF__
done
