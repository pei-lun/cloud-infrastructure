provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-backend-00bc27eb46db48ab0616c32a5b"
    key    = "aws-iam-roles/terraform.tfstate"
    region = "us-west-2"
  }
}

resource "aws_iam_role" "lambda_basic_execution_role" {
  name = "AWSLambdaBasicExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRolePolicy"
  role = "${aws_iam_role.lambda_basic_execution_role.id}"

  policy = "${data.aws_iam_policy_document.aws_lambda_basic_execution_role.json}"
}
