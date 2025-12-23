#!/bin/bash
set -euo pipefail

# ----------------------------
# Defaults
# ----------------------------
your_node_number="50445"
connection_mode="2"   # 0 = connect to last node using last_mode; 2/3/74 = connect to most-connected

# ----------------------------
# Paths (persistent state + lock)
# ----------------------------
STATE_DIR="/var/lib/asterisk/state"
STATE_NODE_FILE="${STATE_DIR}/last_connected_node.txt"
STATE_MODE_FILE="${STATE_DIR}/last_mode.txt"
LOCKFILE="/var/lock/mckn.lock"

mkdir -p "$STATE_DIR"

# ----------------------------
# Args
# ----------------------------
if [ "${1-}" != "" ]; then
  your_node_number="$1"
fi
if [ "${2-}" != "" ]; then
  connection_mode="$2"
fi

# Validate connection mode
if [[ "$connection_mode" != "0" && "$connection_mode" != "2" && "$connection_mode" != "3" && "$connection_mode" != "74" ]]; then
  echo "Connection mode must be 0, 2, 3, or 74."
  exit 1
fi

# ----------------------------
# Lock (avoid double-run from DTMF)
# ----------------------------
exec 9>"$LOCKFILE" || exit 1
if ! flock -n 9; then
  echo "Another instance is running; exiting."
  exit 0
fi

# ----------------------------
# Load last node + last mode
# ----------------------------
LAST_CONNECTED_NODE=""
LAST_MODE="2"   # default if last_mode missing

if [ -s "$STATE_NODE_FILE" ]; then
  LAST_CONNECTED_NODE="$(tr -d ' \r\n\t' < "$STATE_NODE_FILE" || true)"
fi

if [ -s "$STATE_MODE_FILE" ]; then
  tmp_mode="$(tr -d ' \r\n\t' < "$STATE_MODE_FILE" || true)"
  if [[ "$tmp_mode" == "2" || "$tmp_mode" == "3" || "$tmp_mode" == "74" ]]; then
    LAST_MODE="$tmp_mode"
  fi
fi

# ----------------------------
# Mode 0: connect to last node using last saved mode
# ----------------------------
if [[ "$connection_mode" == "0" ]]; then
  if [[ -z "$LAST_CONNECTED_NODE" ]]; then
    echo "No last connected node stored yet: $STATE_NODE_FILE"
    exit 1
  fi

  echo "Connecting to LAST node: $LAST_CONNECTED_NODE using LAST mode: $LAST_MODE ..."
  asterisk -rx "rpt fun $your_node_number *${LAST_MODE}${LAST_CONNECTED_NODE}"
  exit 0
fi

# ----------------------------
# Otherwise: find most-connected node (excluding LAST_CONNECTED_NODE)
# ----------------------------
TMP_HTML="$(mktemp)"
trap 'rm -f "$TMP_HTML"' EXIT

URL="http://stats.allstarlink.org/stats/keyed"
if ! curl -fsSL "$URL" -o "$TMP_HTML"; then
  echo "Failed to download: $URL"
  exit 1
fi

most_connected_node=""
max_connections=0
current_node=""
connection_count=0

while IFS= read -r line; do
  if [[ "$line" == *'<td><a href="/stats/'* ]]; then
    new_node="$(echo "$line" | grep -oP '(?<=/stats/)[0-9]+' || true)"
    if [[ -n "$new_node" ]]; then
      current_node="$new_node"
    fi
    connection_count=0
  fi

  if [[ "$line" == *'<a href="/stats/'* ]]; then
    ((connection_count++)) || true
  fi

  if [[ "$line" == *'</tr>'* && -n "$current_node" ]]; then
    echo "Node $current_node: $connection_count connections"

    if [[ "$connection_count" -gt "$max_connections" && "$current_node" != "$LAST_CONNECTED_NODE" ]]; then
      max_connections="$connection_count"
      most_connected_node="$current_node"
    fi
  fi
done < "$TMP_HTML"

echo "Most connected node: $most_connected_node with $max_connections connections"

if [[ -n "$most_connected_node" ]]; then
  echo "Connecting to node $most_connected_node with mode $connection_mode..."
  asterisk -rx "rpt fun $your_node_number *${connection_mode}${most_connected_node}"

  # Save state
  echo "$most_connected_node" > "$STATE_NODE_FILE"
  echo "$connection_mode" > "$STATE_MODE_FILE"
else
  echo "No suitable node found."
  exit 1
fi
