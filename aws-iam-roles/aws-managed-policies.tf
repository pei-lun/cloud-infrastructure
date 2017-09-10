# AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "aws_lambda_basic_execution_role" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}
