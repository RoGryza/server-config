#!/usr/bin/env bash

SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")"

gpg --batch --use-agent --decrypt "$SCRIPT_PATH/../.vault-pass.gpg"
