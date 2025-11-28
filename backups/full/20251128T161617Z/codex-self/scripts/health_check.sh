#!/bin/bash
TIMESTAMP=$(date -Iseconds)

# Get system resources
CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEMORY_MB=$(free -m | awk 'NR==2{print $3}')
DISK_MB=$(df -m ~ | awk 'NR==2{print $4}')

# Update maintenance state
jq --arg ts "$TIMESTAMP" \
   --arg cpu "$CPU_PERCENT" \
   --arg mem "$MEMORY_MB" \
   '.current_state.last_health_check = $ts |
    .current_state.cpu_percent_avg = ($cpu | tonumber) |
    .current_state.memory_mb_used = ($mem | tonumber)' \
   "$HOME/.codex-self/maintenance.json" > "$HOME/.codex-self/maintenance.tmp" && \
mv "$HOME/.codex-self/maintenance.tmp" "$HOME/.codex-self/maintenance.json"

# Determine health status
if (( $(echo "$CPU_PERCENT > 90" | bc -l) )); then
  jq '.health_indicators.resource_health = "red"' \
     "$HOME/.codex-self/maintenance.json" > "$HOME/.codex-self/maintenance.tmp" && \
  mv "$HOME/.codex-self/maintenance.tmp" "$HOME/.codex-self/maintenance.json"
elif (( $(echo "$CPU_PERCENT > 70" | bc -l) )); then
  jq '.health_indicators.resource_health = "yellow"' \
     "$HOME/.codex-self/maintenance.json" > "$HOME/.codex-self/maintenance.tmp" && \
  mv "$HOME/.codex-self/maintenance.tmp" "$HOME/.codex-self/maintenance.json"
else
  jq '.health_indicators.resource_health = "green"' \
     "$HOME/.codex-self/maintenance.json" > "$HOME/.codex-self/maintenance.tmp" && \
  mv "$HOME/.codex-self/maintenance.tmp" "$HOME/.codex-self/maintenance.json"
fi

echo "[$TIMESTAMP] Health check - CPU: ${CPU_PERCENT}%, Memory: ${MEMORY_MB}MB, Disk: ${DISK_MB}MB, Health: $(jq -r '.health_indicators.resource_health' "$HOME/.codex-self/maintenance.json")" >> "$HOME/.codex-self/logs/resource.log"
