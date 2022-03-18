#!/bin/env bash
# Source: https://victorkoronen.se/2017/07/07/merging-ansible-vaults-in-git/

set -euo pipefail

ANCESTOR_VERSION="$1"
CURRENT_VERSION="$2"
OTHER_VERSION="$3"
CONFLICT_MARKER_SIZE="$4"
MERGED_RESULT_PATHNAME="$5"

ANCESTOR_TEMPFILE=$(mktemp tmp.XXXXXXXXXX)
CURRENT_TEMPFILE=$(mktemp tmp.XXXXXXXXXX)
OTHER_TEMPFILE=$(mktemp tmp.XXXXXXXXXX)

delete_tempfiles() {
    rm -f "$ANCESTOR_TEMPFILE" "$CURRENT_TEMPFILE" "$OTHER_TEMPFILE"
}
trap delete_tempfiles EXIT

ansible-vault decrypt --output "$ANCESTOR_TEMPFILE" "$ANCESTOR_VERSION"
ansible-vault decrypt --output "$CURRENT_TEMPFILE" "$CURRENT_VERSION"
ansible-vault decrypt --output "$OTHER_TEMPFILE" "$OTHER_VERSION"

git merge-file "$CURRENT_TEMPFILE" "$ANCESTOR_TEMPFILE" "$OTHER_TEMPFILE"

ansible-vault encrypt --output "$CURRENT_VERSION" "$CURRENT_TEMPFILE"
