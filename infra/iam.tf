data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid     = "TestAccess"
    actions = [
      "s3:*",
      "es:*"
    ]
    resources = [
      aws_s3_bucket.docstore.arn,
      "${aws_s3_bucket.docstore.arn}/*",
      aws_s3_bucket.intermediate.arn,
      "${aws_s3_bucket.intermediate.arn}/*",
      aws_opensearch_domain.dev.arn,
      "${aws_opensearch_domain.dev.arn}/*"
    ]
  }

  statement {
    sid       = "VpcNetworking"
    actions   = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "pgp-searchengine-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  description        = "Lambda exec role (broad test permissions)"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions_inline" {
  name   = "pgp-searchengine-lambda"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
