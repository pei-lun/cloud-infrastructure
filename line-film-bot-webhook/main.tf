provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-backend-00bc27eb46db48ab0616c32a5b"
    key    = "line-film-bot-webhook/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "aws_iam_roles" {
  backend = "s3"

  config {
    bucket = "terraform-backend-00bc27eb46db48ab0616c32a5b"
    key    = "aws-iam-roles/terraform.tfstate"
    region = "us-west-2"
  }
}

data "aws_caller_identity" "current_caller" {}

data "aws_region" "current_region" {
  current = true
}

resource "aws_api_gateway_rest_api" "line_film_bot_webhook" {
  name = "Line Film Bot Webhook"
}

resource "aws_api_gateway_method" "root_any_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  resource_id   = "${aws_api_gateway_rest_api.line_film_bot_webhook.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_lambda_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  resource_id             = "${aws_api_gateway_rest_api.line_film_bot_webhook.root_resource_id}"
  http_method             = "${aws_api_gateway_method.root_any_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current_region.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.bot_api.arn}/invocations"
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  parent_id   = "${aws_api_gateway_rest_api.line_film_bot_webhook.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  resource_id   = "${aws_api_gateway_resource.proxy_resource.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_lambda_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  resource_id             = "${aws_api_gateway_resource.proxy_resource.id}"
  http_method             = "${aws_api_gateway_method.proxy_any_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current_region.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.bot_api.arn}/invocations"
}

variable "deployment_package" {
  default = "lambda_function.zip"
}

variable "channel_secret" {}
variable "channel_access_token" {}

resource "aws_lambda_function" "bot_api" {
  filename         = "${var.deployment_package}"
  function_name    = "test"
  role             = "${data.terraform_remote_state.aws_iam_roles.lambda_basic_execution_role_arn}"
  handler          = "handler.lambda_handler"
  runtime          = "python3.6"
  timeout          = 30
  memory_size      = 512
  source_code_hash = "${base64sha256(file("${var.deployment_package}"))}"

  environment {
    variables = {
      CHANNEL_SECRET       = "${var.channel_secret}"
      CHANNEL_ACCESS_TOKEN = "${var.channel_access_token}"
    }
  }
}

resource "aws_lambda_permission" "allow_aws_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.bot_api.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:${aws_api_gateway_rest_api.line_film_bot_webhook.id}/*"
}

resource "aws_api_gateway_deployment" "dev_stage" {
  depends_on  = ["aws_api_gateway_integration.root_lambda_integration", "aws_api_gateway_integration.proxy_lambda_integration"]
  rest_api_id = "${aws_api_gateway_rest_api.line_film_bot_webhook.id}"
  stage_name  = "dev"

  # A workaround to update deployment stage. https://github.com/hashicorp/terraform/issues/6613#issuecomment-322264393
  stage_description = "${md5(file("main.tf"))}"
}

output "dev_invoke_url" {
  value = "${aws_api_gateway_deployment.dev_stage.invoke_url}"
}
