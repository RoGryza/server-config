#!/bin/bash

set -euo pipefail

TMP="$(mktemp -d)"
PIDS=()
PGPORT=$(($RANDOM % 64536 + 1000))

function cleanup() {
  for PID in "${PIDS[@]}"; do
    kill "$PID" &>/dev/null || true
  done
  rm -f "$TMP/*.sock"
  rm -f ".tf.auto.tfvars"
}
trap cleanup EXIT

HOST="$(terraform output -raw ip)"
SSH_PORT="$(terraform output -raw ssh_port)"
PG_INTERNAL_HOST="$(terraform output -raw postgres_internal_ip)"

function tunnel() {
  local LOCAL_ADDR="$1"
  local REMOTE_ADDR="$2"

  ssh -o UserKnownHostsFile=../.hosts \
    -nNT \
    -p "$SSH_PORT" \
    "rogryza@$HOST" \
    -L "$LOCAL_ADDR:$REMOTE_ADDR" &
  echo "$!"
}

ssh-add -t 10m
PIDS+=("$(tunnel "$TMP/docker.sock" /var/run/docker.sock)")
PIDS+=("$(tunnel "$PGPORT" "$PG_INTERNAL_HOST:5432")")

cat > .tf.auto.tfvars <<-EOF
  docker_host="unix:///$TMP/docker.sock"
  postgres_port="$PGPORT"
EOF

terraform "$@"
