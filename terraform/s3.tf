output "b2_server_backup_bucket_name" {
  value = b2_bucket.b2_server_backup.bucket_name
}

output "b2_server_backup_access_key_id" {
  value = b2_application_key.b2_server_backup.application_key_id
}

output "b2_server_backup_access_key" {
  value     = b2_application_key.b2_server_backup.application_key
  sensitive = true
}

resource "random_string" "b2_bucket_prefix" {
  length  = 6
  special = false
  upper   = false
}

resource "b2_bucket" "b2_server_backup" {
  bucket_info = {}
  bucket_name = "${random_string.b2_bucket_prefix.result}-server-backup"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "b2_server_backup" {
  key_name     = "server-backup"
  capabilities = ["deleteFiles", "listBuckets", "listFiles", "readBuckets", "readFiles", "shareFiles", "writeFiles"]
  bucket_id    = b2_bucket.b2_server_backup.id
}
