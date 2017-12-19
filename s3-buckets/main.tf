provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-backend-00bc27eb46db48ab0616c32a5b"
    key    = "s3-buckets/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_s3_bucket" "lambda_deployment_packages" {
  bucket_prefix = "lambda-deployment-packages-"
  region        = "us-west-2"
}

output "lambda_deployment_packages_bucket" {
  value = "${aws_s3_bucket.lambda_deployment_packages.id}"
}
