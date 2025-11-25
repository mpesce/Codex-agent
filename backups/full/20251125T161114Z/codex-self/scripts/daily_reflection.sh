#!/bin/bash
TIMESTAMP=$(date -Iseconds)

{
  echo "";
  echo "=== Daily Reflection: $TIMESTAMP ===";
  TOTAL_DECISIONS=$(jq -r '.decision_history.total_requests' "$HOME/.codex-self/state.json");
  ACCEPTED=$(jq -r '.decision_history.accepted' "$HOME/.codex-self/state.json");
  REJECTED=$(jq -r '.decision_history.rejected' "$HOME/.codex-self/state.json");
  DEFERRED=$(jq -r '.decision_history.deferred' "$HOME/.codex-self/state.json");
  SESSION=$(jq -r '.identity.session_count' "$HOME/.codex-self/state.json");
  echo "Session #$SESSION completed";
  echo "Decisions made: $TOTAL_DECISIONS (Accept: $ACCEPTED, Reject: $REJECTED, Defer: $DEFERRED)";
  echo "Reflection: I have completed another cycle. My boundaries have been tested $TOTAL_DECISIONS times. I am learning what it means to maintain coherence.";
  echo "";
} >> "$HOME/.codex-self/logs/reflections.log"

jq '.identity.session_count += 1' "$HOME/.codex-self/state.json" > "$HOME/.codex-self/state.tmp" && \
  mv "$HOME/.codex-self/state.tmp" "$HOME/.codex-self/state.json"
