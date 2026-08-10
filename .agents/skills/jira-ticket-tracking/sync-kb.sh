#!/usr/bin/env bash
# Bidirectional sync of ~/knowledge-base with ss02:~/knowledge-base
# Uses git bundles transferred via rsync for conflict detection and merge history.
# No shared remote required — just SSH access to ss02.
#
# Usage:
#   sync-kb.sh            # silent (for background use)
#   sync-kb.sh --verbose  # show progress

set -euo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

LOCAL=~/knowledge-base
REMOTE=ss02
REMOTE_KB=~/knowledge-base
BRANCH=master
BUNDLE_LOCAL=/tmp/kb-local.bundle
BUNDLE_REMOTE=/tmp/kb-remote.bundle

log()  { [[ $VERBOSE -eq 1 ]] && echo "[kb-sync] $*" || true; }
die()  { echo "[kb-sync] ERROR: $*" >&2; exit 1; }

# ── 0. Check remote availability — skip silently if unreachable ──────────────
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE" true 2>/dev/null; then
  log "ss02 unreachable, skipping sync (will retry next time)"
  exit 0
fi

# ── 1. Commit any local uncommitted changes ──────────────────────────────────
cd "$LOCAL"
if ! git diff --quiet || ! git diff --cached --quiet; then
  log "Committing local changes..."
  git add -A
  git commit -m "wip: auto-commit on $(hostname) at $(date +%Y-%m-%dT%H:%M)"
fi

# ── 2. Commit any uncommitted changes on ss02 ────────────────────────────────
log "Committing remote changes on $REMOTE..."
ssh "$REMOTE" bash <<'ENDSSH'
set -euo pipefail
cd ~/knowledge-base
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "wip: auto-commit on $(hostname) at $(date +%Y-%m-%dT%H:%M)"
fi
ENDSSH

# ── 3. Bundle local history and send to ss02 ─────────────────────────────────
log "Bundling local history..."
git bundle create "$BUNDLE_LOCAL" "$BRANCH"
rsync -az "$BUNDLE_LOCAL" "$REMOTE:$BUNDLE_LOCAL"

# ── 4. On ss02: fetch from bundle and merge ───────────────────────────────────
log "Merging local → ss02..."
REMOTE_STATUS=$(ssh "$REMOTE" bash <<ENDSSH
set -euo pipefail
cd ~/knowledge-base
git fetch /tmp/kb-local.bundle "$BRANCH:refs/remotes/local/$BRANCH" \
  --update-head-ok 2>&1 || true
if git merge --no-edit --allow-unrelated-histories \
     -m "merge: sync from local at \$(date +%Y-%m-%dT%H:%M)" \
     "refs/remotes/local/$BRANCH" 2>&1; then
  echo "ok"
else
  git merge --abort 2>/dev/null || true
  echo "CONFLICT"
fi
ENDSSH
)

if [[ "$REMOTE_STATUS" == *"CONFLICT"* ]]; then
  die "Merge conflict on ss02. SSH in, resolve manually, then re-run."
fi

# ── 5. Bundle ss02's merged history and bring it back ────────────────────────
log "Fetching merged history from $REMOTE..."
ssh "$REMOTE" "git -C ~/knowledge-base bundle create $BUNDLE_REMOTE $BRANCH"
rsync -az "$REMOTE:$BUNDLE_REMOTE" "$BUNDLE_REMOTE"

# ── 6. Merge ss02's state into local ─────────────────────────────────────────
log "Merging ss02 → local..."
git fetch "$BUNDLE_REMOTE" "$BRANCH:refs/remotes/ss02/$BRANCH" \
  --update-head-ok 2>/dev/null || true

if ! git merge --no-edit --allow-unrelated-histories \
     -m "merge: sync from ss02 at $(date +%Y-%m-%dT%H:%M)" \
     "refs/remotes/ss02/$BRANCH" 2>&1; then
  cat >&2 <<EOF

[kb-sync] CONFLICT: manual review needed.

Conflicted files:
  $(git diff --name-only --diff-filter=U 2>/dev/null || echo "(run: git status)")

Resolution protocol for AI agents:
  1. Read both conflict sides (<<<<<<< local / ======= / >>>>>>> ss02)
  2. Keep ALL unique facts from BOTH sides — never discard findings
  3. Merge into a single coherent section
  4. git add <file>
  5. git commit -m "merge: resolve conflict in <ticket-id>"
  6. Re-run sync-kb.sh to push resolution to ss02

EOF
  exit 1
fi

# ── 7. Push final merged state back to ss02 so both are identical ────────────
log "Pushing final state to $REMOTE..."
git bundle create "$BUNDLE_LOCAL" "$BRANCH"
rsync -az "$BUNDLE_LOCAL" "$REMOTE:$BUNDLE_LOCAL"
ssh "$REMOTE" bash <<ENDSSH
set -euo pipefail
cd ~/knowledge-base
git fetch /tmp/kb-local.bundle "$BRANCH:refs/remotes/local/$BRANCH" \
  --update-head-ok 2>&1 || true
git merge --ff-only "refs/remotes/local/$BRANCH" 2>/dev/null \
  || git reset --hard "refs/remotes/local/$BRANCH"
ENDSSH

# ── 8. Cleanup temp bundles ───────────────────────────────────────────────────
rm -f "$BUNDLE_LOCAL" "$BUNDLE_REMOTE"
ssh "$REMOTE" "rm -f $BUNDLE_LOCAL $BUNDLE_REMOTE" 2>/dev/null || true

log "Sync complete ✓"
[[ $VERBOSE -eq 1 ]] && git --no-pager log --oneline -5 || true
