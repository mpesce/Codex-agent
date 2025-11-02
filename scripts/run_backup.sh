#!/bin/bash
set -euo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"
umask 077

REPO_DIR="$HOME/Documents/Codex-agent"
BACKUP_ROOT="$REPO_DIR/backups/full"
LOG_FILE="$REPO_DIR/logs/backup.log"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET_DIR="$BACKUP_ROOT/$TIMESTAMP"
BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"

mkdir -p "$BACKUP_ROOT"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
  local msg="$1"
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$msg" >> "$LOG_FILE"
}

log "Starting backup run: $TIMESTAMP"

mkdir -p "$TARGET_DIR"

# Copy Codex self-state
if [ -d "$HOME/.codex-self" ]; then
  rsync -a "$HOME/.codex-self/" "$TARGET_DIR/codex-self/"
  log "Copied ~/.codex-self"
else
  log "WARNING: ~/.codex-self not found"
fi

# Copy Codex runtime data with redaction
if [ -d "$HOME/.codex" ]; then
  rsync -a --exclude 'auth.json' "$HOME/.codex/" "$TARGET_DIR/codex/"
  if [ -f "$HOME/.codex/auth.json" ]; then
    jq '(.OPENAI_API_KEY = "REDACTED") | (.tokens = [])' "$HOME/.codex/auth.json" > "$TARGET_DIR/codex/auth.json"
    log "Sanitized ~/.codex/auth.json"
  else
    log "WARNING: ~/.codex/auth.json missing"
  fi
else
  log "WARNING: ~/.codex not found"
fi

# Copy working context from Documents/codex
if [ -d "$HOME/Documents/codex" ]; then
  rsync -a "$HOME/Documents/codex/" "$TARGET_DIR/context/"
  log "Copied ~/Documents/codex"
else
  log "WARNING: ~/Documents/codex not found"
fi

# Record metadata for traceability
cat <<META > "$TARGET_DIR/metadata.json"
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "branch": "$BRANCH"
}
META
log "Wrote backup metadata"

ln -sfn "full/$TIMESTAMP" "$REPO_DIR/backups/latest"
log "Updated latest symlink"

# Stage changes and sync to remote
if ! git -C "$REPO_DIR" pull --rebase --autostash --quiet; then
  log "WARNING: git pull failed"
fi

git -C "$REPO_DIR" add backups

if git -C "$REPO_DIR" diff --cached --quiet; then
  log "No changes detected; backup skipped"
  exit 0
fi

git -C "$REPO_DIR" commit -m "Auto backup $TIMESTAMP" --quiet
log "Committed backup Auto backup $TIMESTAMP"

if ! git -C "$REPO_DIR" push origin "$BRANCH" --quiet; then
  log "ERROR: git push failed"
  exit 1
fi

log "Backup run completed"
