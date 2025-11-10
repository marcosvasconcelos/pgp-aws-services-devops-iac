resource "aws_codebuild_project" "pdftotxt" {
  name         = local.codebuild_projects.pdf_to_text
  description  = "Build project for PDF to Text Lambda function"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = local.lambda_functions.pdf_to_text
    }
  }

  source {
    type     = "CODEPIPELINE"
    buildspec = "pdftotxt-pgp-aws-services-lambda/buildspec.yml"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-pdftotxt-build" })
}

resource "aws_codebuild_project" "search_gateway" {
  name         = local.codebuild_projects.search_gateway
  description  = "Build project for Search Gateway Lambda function"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = local.lambda_functions.search_gateway
    }
  }

  source {
    type     = "CODEPIPELINE"
    buildspec = "search-gateway-aws-services-lambda/buildspec.yml"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-gateway-build" })
}

resource "aws_codebuild_project" "search_function" {
  name         = local.codebuild_projects.search_function
  description  = "Build project for Search Function Lambda"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = local.lambda_functions.search_function
    }
  }

  source {
    type     = "CODEPIPELINE"
    buildspec = "searchFunction-aws-services-lambda/buildspec.yml"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-function-build" })
}

resource "aws_codebuild_project" "upload_to_search" {
  name         = local.codebuild_projects.upload_to_search
  description  = "Build project for Upload to Search Lambda function"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = local.lambda_functions.upload_to_search
    }
  }

  source {
    type     = "CODEPIPELINE"
    buildspec = "upload-to-search-aws-services-lambda/buildspec.yml"
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-upload-to-search-build" })
}

resource "aws_lambda_function" "pdftotxt" {
  filename         = "${path.module}/lambda-placeholder.zip"
  function_name    = local.lambda_functions.pdf_to_text
  role             = aws_iam_role.lambda_pdftotxt_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  runtime          = "python3.9"
  timeout          = 300

  environment {
    variables = {
      DOCUMENTS_BUCKET = aws_s3_bucket.documents.bucket
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-pdftotxt-lambda" })

  lifecycle {
    ignore_changes = [filename, source_code_hash, last_modified]
  }
}

resource "aws_lambda_function" "search_gateway" {
  filename         = "${path.module}/lambda-placeholder.zip"
  function_name    = local.lambda_functions.search_gateway
  role             = aws_iam_role.lambda_search_gateway_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.main.endpoint
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-gateway-lambda" })

  lifecycle {
    ignore_changes = [filename, source_code_hash, last_modified]
  }
}

resource "aws_lambda_function" "search_function" {
  filename         = "${path.module}/lambda-placeholder.zip"
  function_name    = local.lambda_functions.search_function
  role             = aws_iam_role.lambda_search_function_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.main.endpoint
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-search-function-lambda" })

  lifecycle {
    ignore_changes = [filename, source_code_hash, last_modified]
  }
}

resource "aws_lambda_function" "upload_to_search" {
  filename         = "${path.module}/lambda-placeholder.zip"
  function_name    = local.lambda_functions.upload_to_search
  role             = aws_iam_role.lambda_upload_to_search_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256
  runtime          = "python3.9"
  timeout          = 300

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.main.endpoint
      DOCUMENTS_BUCKET    = aws_s3_bucket.documents.bucket
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-upload-to-search-lambda" })

  lifecycle {
    ignore_changes = [filename, source_code_hash, last_modified]
  }
}

data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda-placeholder.zip"

  source {
    content  = "def lambda_handler(event, context):\n    return {'statusCode': 200, 'body': 'Placeholder function'}"
    filename = "lambda_function.py"
  }
}
