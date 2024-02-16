resource "aws_s3_bucket" "tf_backend-ip2cr" {
  bucket_prefix = "tf-ip2cr-"
  force_destroy = true

  tags = {
    Name  = "IP2CR Terraform state bucket"
  }
}

resource "aws_dynamodb_table" "tf_backend-ip2cr" {
  name            = "tf-ip2cr"
  hash_key        = "LockID"
  billing_mode    = "PROVISIONED"
  read_capacity   = 5
  write_capacity  = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "tf-ip2cr-metadata" {
  value = [
    resource.aws_s3_bucket.tf_backend-ip2cr.bucket,
    resource.aws_dynamodb_table.tf_backend-ip2cr.name
  ]
}