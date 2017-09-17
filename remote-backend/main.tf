provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terraform_backend_bucket" {
  bucket_prefix = "terraform-backend-"
  region        = "us-west-2"

  versioning {
    enabled = true
  }
}

output "terraform_backend_bucket" {
  value = "${aws_s3_bucket.terraform_backend_bucket.id}"
}
