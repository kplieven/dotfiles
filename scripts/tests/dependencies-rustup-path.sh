#!/usr/bin/env bash
set -euo pipefail

script_dir="$(readlink -f -- "$(dirname -- "${BASH_SOURCE[0]}")/..")"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mock_bin="$tmp_dir/bin"
mock_home="$tmp_dir/home"
mkdir -p "$mock_bin" "$mock_home"

cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$mock_bin/curl" <<'EOF'
#!/usr/bin/env bash
cat <<'INSTALLER'
cargo_bin="${CARGO_HOME:-$HOME/.cargo}/bin"
case ":$PATH:" in
    *":$cargo_bin:"*) ;;
    *) printf '\033[0;31mYour path is missing %s, you might want to add it.\033[0m\n' "$cargo_bin" >&2 ;;
esac
mkdir -p "$cargo_bin"
: > "${CARGO_HOME:-$HOME/.cargo}/env"
INSTALLER
EOF

chmod +x "$mock_bin/sudo" "$mock_bin/curl"

output="$tmp_dir/output"
if ! HOME="$mock_home" CARGO_HOME="$mock_home/.cargo" PATH="$mock_bin:/usr/bin:/bin" \
    bash "$script_dir/dependencies.sh" --rust >"$output" 2>&1; then
    cat "$output" >&2
    exit 1
fi

if grep -Fq "Your path is missing" "$output"; then
    cat "$output" >&2
    echo "rustup install printed a missing Cargo PATH warning" >&2
    exit 1
fi
