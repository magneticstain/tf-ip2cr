resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "tf_backend-ip2cr" {
  name          = "tf-ip2cr-gcp-${random_id.bucket_prefix.hex}-bucket-tfstate"
  force_destroy = false
  location      = "US"
  storage_class = "STANDARD"
}

output "tf-gcs-bucket-metadata" {
  value = [
    resource.google_storage_bucket.tf_backend-ip2cr.name
  ]
}