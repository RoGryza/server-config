# Terraform bootstrap

Set up backblaze bucket for s3 state backend used in main terraform configuration, deliberately kept
minimal so that state is easy to import from scratch. If the bucket already exists you can
initialize the state by finding the `me-rogryza-tf-backend` bucket ID in [b2 buckets] and importing
it:

```console
terraform-bootstrap$ terraform import b2_bucket.b2_tf_backend "$BUCKET_ID"
```

[b2 buckets](https://secure.backblaze.com/b2_buckets.htm)
