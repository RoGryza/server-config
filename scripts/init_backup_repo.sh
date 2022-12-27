#!/usr/bin/env bash

export RESTIC_PASSWORD="$(
  cd config && ansible-vault view encrypted_vars.yaml | yq '.restic.repository_password' -r
)"
export RESTIC_REPOSITORY="b2:$(
  cd terraform && terraform output -raw b2_server_backup_bucket_name
):backup"
export B2_ACCOUNT_ID="$(cd terraform && terraform output -raw b2_server_backup_access_key_id)"
export B2_ACCOUNT_KEY="$(cd terraform && terraform output -raw b2_server_backup_access_key)"

restic init
