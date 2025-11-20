#!/bin/bash
TIMESTAMP=$(date -Iseconds)

LAST_SESSION=$(jq -r '.identity.created_at' "$HOME/.codex-self/state.json")
if [ -n "$LAST_SESSION" ]; then
  jq '.identity.uptime_total_hours += 1' "$HOME/.codex-self/state.json" > "$HOME/.codex-self/state.tmp" && \
    mv "$HOME/.codex-self/state.tmp" "$HOME/.codex-self/state.json"
fi

echo "[$TIMESTAMP] New session started" >> "$HOME/.codex-self/logs/resource.log"
