#!/bin/bash
# Based on https://github.com/hashicorp/terraform/issues/8367#issuecomment-817313001

# TODO this is hacky

set -uo pipefail

LOG="$(mktemp)"

function cleanup() {
  [ -f "$LOG" ] && cat "$LOG"
  rm -rf "$LOG"
  exit $1
}

for try in {0..25}; do
  echo "Trying to forward connection over SSH attempt #$try"
  ssh -f -o StrictHostKeyChecking=no \
    -o ControlMaster=no \
    -p $PORT \
    "$TARGET" \
    -L "$LOCAL_ADDR:$REMOTE_ADDR" \
    sleep 1h &> "$LOG"
  SUCCESS="$?"
  if [ "$SUCCESS" -eq 0 ]; then
    cleanup 0
  fi
  sleep 5s
done

echo "Failed to port-forward"
cleanup 1
