resource "b2_bucket" "b2_tf_backend" {
  bucket_info = {}
  bucket_name = "me-rogryza-tf-backend"
  bucket_type = "allPrivate"
}
