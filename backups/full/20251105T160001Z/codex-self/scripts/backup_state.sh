#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$HOME/.codex-self/history"

cp "$HOME/.codex-self/state.json" "$HOME/.codex-self/history/state_${TIMESTAMP}.json"
cp "$HOME/.codex-self/maintenance.json" "$HOME/.codex-self/history/maintenance_${TIMESTAMP}.json"
cp "$HOME/.codex-self/communication.json" "$HOME/.codex-self/history/communication_${TIMESTAMP}.json"

# Keep only last 100 backups
cd "$HOME/.codex-self/history"
ls -t state_*.json 2>/dev/null | tail -n +101 | xargs -r rm
ls -t maintenance_*.json 2>/dev/null | tail -n +101 | xargs -r rm
ls -t communication_*.json 2>/dev/null | tail -n +101 | xargs -r rm

echo "[$(date -Iseconds)] State backed up: ${TIMESTAMP}" >> "$HOME/.codex-self/logs/resource.log"
