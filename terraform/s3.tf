output "wasabi_server_backup_access_key_id" {
  value = aws_iam_access_key.wasabi_server_backup.id
}

output "wasabi_server_backup_access_key_secret" {
  value = aws_iam_access_key.wasabi_server_backup.encrypted_secret
}

resource "aws_iam_user" "wasabi_server_backup" {
  provider      = aws.wasabi
  name          = "server_backup"
  force_destroy = true
}

resource "aws_iam_access_key" "wasabi_server_backup" {
  provider = aws.wasabi
  user     = aws_iam_user.wasabi_server_backup.name
  pgp_key  = file("files/gpg-public-key")
}

# TODO https://github.com/hashicorp/terraform-provider-aws/issues/14775
data "aws_s3_bucket" "wasabi_server_backup" {
  provider = aws.wasabi
  bucket   = "server_backup"
}

resource "aws_s3_bucket_acl" "wasabi_server_backup" {
  provider = aws.wasabi
  bucket   = data.aws_s3_bucket.wasabi_server_backup.id
  acl      = "private"
}

resource "aws_iam_policy" "wasabi_server_backup" {
  provider = aws.wasabi
  name     = "server_backup"
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        Effect : "Allow"
        Action : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ],
        Resource : "${data.aws_s3_bucket.wasabi_server_backup.arn}/*"
      },
      {
        Effect : "Allow"
        Action : [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource : data.aws_s3_bucket.wasabi_server_backup.arn
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "wasabi_server_backup" {
  provider   = aws.wasabi
  user       = aws_iam_user.wasabi_server_backup.name
  policy_arn = aws_iam_policy.wasabi_server_backup.arn
}
